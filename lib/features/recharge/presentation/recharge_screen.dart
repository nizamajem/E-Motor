import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:flutter/foundation.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../components/app_motion.dart';
import '../../../components/app_feedback.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/network/api_config.dart';
import '../data/topup_service.dart';
import '../../profile/data/user_service.dart';
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final List<_RechargeOption> _options = const [
    _RechargeOption(amount: 10000, bonus: 1000),
    _RechargeOption(amount: 15000, bonus: 1500),
    _RechargeOption(amount: 20000, bonus: 2000),
    _RechargeOption(amount: 30000, bonus: 3000),
    _RechargeOption(amount: 50000, bonus: 5000),
    _RechargeOption(amount: 100000, bonus: 10000),
  ];

  int _selectedIndex = 0;
  bool _isSubmitting = false;
  final TopupService _topupService = TopupService();
  final UserService _userService = UserService();
  MidtransSDK? _midtrans;
  bool _midtransReady = false;

  @override
  void initState() {
    super.initState();
    _initMidtrans();
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _options[_selectedIndex];
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF111827),
                  ),
                  Expanded(
                    child: Text(
                      l10n.rechargeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    _PendingTopupCard(
                      onRetry: _retryPendingTopup,
                      onCancel: _clearPendingTopup,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.rechargePrompt,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9AA0AA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF2C7BFE),
                          width: 1.6,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatRupiah(selected.amount),
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 76,
                      ),
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = index == _selectedIndex;
                        return _RechargeOptionCard(
                          option: option,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedIndex = index),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleTopup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.continueLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTopup() async {
    if (_isSubmitting) return;
    final l10n = AppLocalizations.of(context);
    var walletId = SessionManager.instance.customerWalletId ?? '';
    if (walletId.isEmpty) {
      walletId = await _ensureWalletId();
      if (walletId.isEmpty) {
        _showMidtransNotReadyDialog(message: l10n.topupWalletMissing);
        return;
      }
    }
    final selected = _options[_selectedIndex];
    setState(() => _isSubmitting = true);
    try {
      await SessionManager.instance.clearPendingTopup();
      final res = await _topupService.createSnap(
        customerWalletId: walletId,
        amount: selected.amount,
        isSandbox: false,
      );
      if (!mounted) return;
      if (res == null || res.snapToken.isEmpty) {
        _showSnack(l10n.topupFailed);
        return;
      }
      if (!_midtransReady || _midtrans == null) {
        await _initMidtrans();
      }
      if (!_midtransReady || _midtrans == null) {
        _showMidtransNotReadyDialog();
        return;
      }
      await SessionManager.instance.savePendingTopup(
        snapToken: res.snapToken,
        orderId: res.orderId,
      );
      await _midtrans!.startPaymentUiFlow(token: res.snapToken);
      if (mounted) _showSnack(l10n.topupRedirected);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception:', '').trim();
        _showMidtransNotReadyDialog(
          message: msg.isEmpty ? l10n.topupFailed : msg,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    showInfoSnack(context, message);
  }

  Future<void> _showMidtransNotReadyDialog({String? message}) async {
    final l10n = AppLocalizations.of(context);
    return showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: const Color(0xFF111827),
                      splashRadius: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.paymentFailed,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? l10n.midtransNotReady,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B8190),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C7BFE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.ok,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _ensureWalletId() async {
    try {
      final userId = await SessionManager.instance.resolveUserId();
      if (userId.isEmpty) return '';
      final profile = await _userService.fetchUserById(userId);
      if (profile != null) {
        await SessionManager.instance.saveUserProfile(profile);
        if (mounted) setState(() {});
      }
    } catch (_) {}
    return SessionManager.instance.customerWalletId ?? '';
  }

  Future<void> _initMidtrans() async {
    final merchantUrl = _normalizeMerchantUrl(ApiConfig.midtransMerchantBaseUrl);
    if (ApiConfig.midtransClientKey.isEmpty || merchantUrl.isEmpty) {
      return;
    }
    try {
      if (kDebugMode) {
        debugPrint('midtrans init clientKeyLen=${ApiConfig.midtransClientKey.length}');
        debugPrint('midtrans merchantUrl=$merchantUrl');
      }
      final midtrans = await MidtransSDK.init(
        config: MidtransConfig(
          clientKey: ApiConfig.midtransClientKey,
          merchantBaseUrl: merchantUrl,
          enableLog: kDebugMode,
          colorTheme: ColorTheme(
            colorPrimary: const Color(0xFF2C7BFE),
            colorPrimaryDark: const Color(0xFF2C7BFE),
            colorSecondary: const Color(0xFF2C7BFE),
          ),
        ),
      );
      midtrans.setTransactionFinishedCallback(_handleMidtransResult);
      if (mounted) {
        setState(() {
          _midtrans = midtrans;
          _midtransReady = true;
        });
      } else {
        _midtrans = midtrans;
        _midtransReady = true;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _midtransReady = false);
      }
    }
  }

  String _normalizeMerchantUrl(String value) {
    var url = value.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    return url;
  }

  void _handleMidtransResult(TransactionResult result) {
    final status = result.status.toLowerCase();
    if (status == 'success' || status == 'settlement' || status == 'capture') {
      SessionManager.instance.clearPendingTopup();
      _refreshBalance();
      _showSnack(AppLocalizations.of(context).paymentSuccess);
      return;
    }
    if (status == 'pending') {
      _showSnack(AppLocalizations.of(context).paymentPendingBody);
      return;
    }
    _showSnack(AppLocalizations.of(context).paymentFailed);
  }

  Future<void> _refreshBalance() async {
    try {
      final userId = await SessionManager.instance.resolveUserId();
      if (userId.isEmpty) return;
      final profile = await _userService.fetchUserById(userId);
      if (profile != null) {
        await SessionManager.instance.saveUserProfile(profile);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _retryPendingTopup() async {
    final token = SessionManager.instance.pendingTopupSnapToken ?? '';
    if (token.isEmpty) return;
    if (!_midtransReady || _midtrans == null) {
      await _initMidtrans();
    }
    if (!_midtransReady || _midtrans == null) {
      _showMidtransNotReadyDialog();
      return;
    }
    await _midtrans!.startPaymentUiFlow(token: token);
  }

  Future<void> _clearPendingTopup() async {
    await SessionManager.instance.clearPendingTopup();
    if (mounted) setState(() {});
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final idx = digits.length - i;
      buffer.write(digits[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()},00';
  }
}

class _RechargeOption {
  const _RechargeOption({
    required this.amount,
    required this.bonus,
  });

  final int amount;
  final int bonus;
}

class _RechargeOptionCard extends StatelessWidget {
  const _RechargeOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _RechargeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected ? Colors.white : const Color(0xFFF4F6F9);
    final border =
        isSelected ? const Color(0xFF2C7BFE) : const Color(0xFFE6E9F2);
    final titleColor =
        isSelected ? const Color(0xFF2C7BFE) : const Color(0xFF9AA0AA);
    final bonusBg =
        isSelected ? const Color(0xFF0DA2E6) : const Color(0xFFE6EBF3);
    final bonusColor =
        isSelected ? Colors.white : const Color(0xFF9AA0AA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatRupiah(option.amount),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: bonusBg,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text(
              '${AppLocalizations.of(context).bonus} ${_formatRupiah(option.bonus)}',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: bonusColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final idx = digits.length - i;
      buffer.write(digits[i]);
      if (idx > 1 && idx % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()},00';
  }
}

class _PendingTopupCard extends StatelessWidget {
  const _PendingTopupCard({
    required this.onRetry,
    required this.onCancel,
  });

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final token = SessionManager.instance.pendingTopupSnapToken ?? '';
    if (token.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentPending,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.paymentPendingBody,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.pay,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
