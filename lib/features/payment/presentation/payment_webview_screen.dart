import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../data/payment_service.dart';

enum PaymentWebViewResult { success, failed, pending, cancelled }

class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    required this.url,
    required this.paymentId,
  });

  final String url;
  final String paymentId;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final PaymentService _paymentService = PaymentService();
  late final WebViewController _controller;
  Timer? _pollTimer;
  bool _finished = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _loadError = error.description;
            });
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            final lower = url.toLowerCase();
            if (lower.startsWith('http://') || lower.startsWith('https://')) {
              return NavigationDecision.navigate;
            }
            // Handle intent/deeplink (e.g. gopay, dana, shopeepay)
            final uri = Uri.tryParse(url);
            if (uri != null) {
              final can = await canLaunchUrl(uri);
              if (can) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (widget.paymentId.isEmpty) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_finished) return;
      try {
        final status = await _paymentService.checkPaymentStatus(
          paymentId: widget.paymentId,
        );
        if (status.isEmpty) return;
        if (status == 'success' ||
            status == 'settlement' ||
            status == 'capture') {
          _finish(PaymentWebViewResult.success);
          return;
        }
        if (status == 'failed' ||
            status == 'failure' ||
            status == 'deny' ||
            status == 'cancel' ||
            status == 'expire') {
          _finish(PaymentWebViewResult.failed);
        }
      } catch (_) {
        // ignore polling errors
      }
    });
  }

  void _finish(PaymentWebViewResult result) {
    if (!mounted || _finished) return;
    _finished = true;
    _pollTimer?.cancel();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.midtransTitle,
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          onPressed: () => _finish(PaymentWebViewResult.cancelled),
          icon: const Icon(Icons.close),
          color: const Color(0xFF111827),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE53935),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
