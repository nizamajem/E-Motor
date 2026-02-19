import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import '../../../components/loading_dialog.dart';
import '../../../components/app_motion.dart';
import '../../shell/main_shell.dart';
import '../../../components/bottom_nav.dart';
import '../data/payment_service.dart';

enum PaymentFlow { membership, ride }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.amount,
    required this.walletBalance,
    required this.flow,
    this.membershipId,
    this.rideId,
    this.snapToken,
    this.membershipHistoryId,
    this.lockMidtrans = false,
  });

  final int amount;
  final int walletBalance;
  final PaymentFlow flow;
  final String? membershipId;
  final String? rideId;
  final String? snapToken;
  final String? membershipHistoryId;
  final bool lockMidtrans;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedIndex = 0;
  bool _isProcessing = false;
  bool _cancelRequested = false;
  final PaymentService _paymentService = PaymentService();
  MidtransSDK? _midtrans;
  bool _midtransReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.snapToken != null && widget.snapToken!.isNotEmpty) {
      _selectedIndex = 1;
    }
    if (widget.lockMidtrans) {
      _selectedIndex = 1;
    }
    _initMidtrans();
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      l10n.paymentTitle,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.paymentAmountDue,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9AA0AA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(widget.amount),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C7BFE),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.paymentMethod,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!widget.lockMidtrans) ...[
                      _PaymentOptionCard(
                        title: l10n.balance,
                        subtitle: _formatRupiah(widget.walletBalance),
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                        leading: _WalletIcon(),
                      ),
                      const SizedBox(height: 12),
                      _PaymentOptionCard(
                        title: 'Midtrans',
                        subtitle: '',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                        leading: _MidtransIcon(),
                        trailing: _PaymentLogos(),
                      ),
                    ] else
                      _PaymentOptionCard(
                        title: 'Midtrans',
                        subtitle: '',
                        isSelected: true,
                        onTap: () {},
                        leading: _MidtransIcon(),
                        trailing: _PaymentLogos(),
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
                  onPressed:
                      _isProcessing ? null : () => _showPaymentConfirm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.pay,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
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

  void _showPaymentConfirm(BuildContext context) {
    showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return PaymentConfirmDialog(
          amount: widget.amount,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            _processPayment(context);
          },
        );
      },
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    if (_isProcessing) return;
    _cancelRequested = false;
    if (kDebugMode) {
      debugPrint('payment start flow=${widget.flow} method=${_selectedIndex == 0 ? 'WALLET' : 'MIDTRANS'}');
    }
    if (_selectedIndex == 0 && widget.walletBalance < widget.amount) {
      _showPaymentFailed(context);
      return;
    }
    setState(() => _isProcessing = true);
    showLoadingDialog(
      context,
      message: AppLocalizations.of(context).loadingProcessing,
      showClose: true,
      onCancel: () {
        _cancelRequested = true;
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      },
    );
    try {
      if (_cancelRequested) return;
      final method =
          _selectedIndex == 0 ? 'WALLET' : 'MIDTRANS';
      PaymentResult result;
      if (widget.flow == PaymentFlow.membership) {
        final membershipId = widget.membershipId ?? '';
        if (membershipId.isEmpty) {
          throw Exception('Membership ID tidak tersedia.');
        }
        final userId = await SessionManager.instance.resolveUserId();
        final customerId = _resolveCustomerId();
        if (kDebugMode) {
          debugPrint('membership pay userId=$userId customerId=$customerId membershipId=$membershipId');
        }
        if (userId.isEmpty) {
          throw Exception('User ID tidak tersedia.');
        }
        if (method == 'WALLET') {
          result = await _paymentService.buyMembershipWallet(
            userId: userId,
            membershipId: membershipId,
          );
          SessionManager.instance.setHasActivePackage(true);
        } else {
          if (widget.snapToken != null && widget.snapToken!.isNotEmpty) {
            result = PaymentResult(
              isSuccess: true,
              snapToken: widget.snapToken,
              membershipHistoryId: widget.membershipHistoryId,
            );
          } else {
            result = await _paymentService.buyMembershipMidtrans(
              userId: userId,
              membershipId: membershipId,
            );
            final historyId = result.membershipHistoryId ?? '';
            final snapToken = result.snapToken ?? '';
            final redirectUrl = result.redirectUrl ?? '';
            if (historyId.isNotEmpty && snapToken.isNotEmpty) {
              await SessionManager.instance.savePendingSnapToken(
                membershipHistoryId: historyId,
                snapToken: snapToken,
              );
            }
            if (historyId.isNotEmpty && redirectUrl.isNotEmpty) {
              await SessionManager.instance.savePendingRedirectUrl(
                membershipHistoryId: historyId,
                redirectUrl: redirectUrl,
              );
            }
          }
        }
      } else {
        final rideId = widget.rideId ?? '';
        if (rideId.isEmpty) {
          throw Exception('Ride ID tidak tersedia.');
        }
        if (method == 'WALLET') {
          result = await _paymentService.payRideWallet(rideId: rideId);
        } else {
          result = await _paymentService.payRideMidtrans(rideId: rideId);
        }
      }

      if (_cancelRequested) return;
      if (method == 'MIDTRANS') {
        final token = result.snapToken ?? '';
        if (kDebugMode) {
          debugPrint('midtrans snapToken length=${token.length}');
          debugPrint('midtrans redirectUrl=${result.redirectUrl}');
        }
        if (!_midtransReady || _midtrans == null) {
          await _initMidtrans();
        }
        if (!mounted) return;
        if (!_midtransReady || _midtrans == null) {
          _showMidtransNotReady(context);
          return;
        }
        if (token.isEmpty) {
          throw Exception('Snap token tidak tersedia.');
        }
        await _midtrans!.startPaymentUiFlow(token: token);
        return;
      }

      if (widget.flow == PaymentFlow.membership) {
        await _refreshMembershipStatus();
      }
      if (kDebugMode) {
        debugPrint('payment success flow=${widget.flow} method=$method');
      }
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      _navigateToDashboard(context);
    } catch (e) {
      if (!_cancelRequested) {
        if (kDebugMode) {
          debugPrint('payment error=$e');
          debugPrint('payment failed flow=${widget.flow} method=${_selectedIndex == 0 ? 'WALLET' : 'MIDTRANS'}');
        }
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        _showPaymentError(context, e.toString());
      }
    } finally {
      if (mounted) {
        // ignore: use_build_context_synchronously
        hideLoadingDialog(context);
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _refreshMembershipStatus() async {
    try {
      final active = await _paymentService.refreshMembershipStatus();
      SessionManager.instance.setHasActivePackage(active);
    } catch (_) {}
  }

  String _resolveCustomerId() {
    final profile = SessionManager.instance.userProfile;
    if (profile == null) return '';
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final direct = read(profile['customerId']) ??
        read(profile['customer_id']) ??
        read(profile['id_customer']) ??
        read(profile['customer']);
    if (direct != null) return direct;

    final customerMap = profile['Customer'] ?? profile['customer'];
    if (customerMap is Map<String, dynamic>) {
      final nested = read(customerMap['id']) ??
          read(customerMap['id_customer']) ??
          read(customerMap['customer_id']);
      if (nested != null) return nested;
    }
    return '';
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      appRoute(
        const MainShell(initialTab: BottomNavTab.dashboard),
        direction: AxisDirection.right,
      ),
      (route) => false,
    );
  }

  void _showPaymentFailed(BuildContext context) {
    showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return PaymentFailedDialog(
          onClose: () => Navigator.of(dialogContext).pop(),
          onOk: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  void _showPaymentError(BuildContext context, String message) {
    showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
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
                  message.replaceAll('Exception:', '').trim(),
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

  void _showMidtransNotReady(BuildContext context) {
    showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
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
                  l10n.midtransNotReady,
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

  Future<void> _initMidtrans() async {
    final merchantUrl =
        _normalizeMerchantUrl(ApiConfig.midtransMerchantBaseUrl);
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
    if (!mounted) return;
    final status = result.status.toLowerCase();
    final isSuccess =
        status == 'success' || status == 'settlement' || status == 'capture';
    final isPending = status == 'pending';
    if (isSuccess) {
      if (widget.flow == PaymentFlow.membership) {
        SessionManager.instance.setHasActivePackage(true);
        final historyId = widget.membershipHistoryId ?? '';
        if (historyId.isNotEmpty) {
          SessionManager.instance.clearPendingSnapToken(historyId);
          SessionManager.instance.clearPendingRedirectUrl(historyId);
        }
      }
      _navigateToDashboard(context);
      return;
    }
    if (isPending) {
      return;
    }
    _showPaymentFailed(context);
  }

}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF2C7BFE) : const Color(0xFFB8BDC7);
    final textColor =
        isSelected ? const Color(0xFF111827) : const Color(0xFF9AA0AA);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (subtitle.isNotEmpty && trailing == null)
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            if (trailing != null) trailing!,
            const SizedBox(width: 10),
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2C7BFE)
                      : const Color(0xFF9AA0AA),
                  width: 1.6,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFF2C7BFE)
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        size: 18,
        color: Color(0xFF2C7BFE),
      ),
    );
  }
}

class _MidtransIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          height: 16,
          width: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF2C7BFE),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _PaymentLogos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/payment/qris.png',
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Image.asset(
          'assets/images/payment/gopay.png',
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Image.asset(
          'assets/images/payment/dana.png',
          height: 14,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Image.asset(
          'assets/images/payment/shopepay.png',
          height: 14,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class PaymentConfirmDialog extends StatelessWidget {
  const PaymentConfirmDialog({
    super.key,
    required this.amount,
    required this.onCancel,
    required this.onConfirm,
  });

  final int amount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    l10n.confirmPayTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onCancel,
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: const Color(0xFF111827),
                      splashRadius: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _withAmount(l10n.confirmPayBody, _formatRupiah(amount)),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B8190),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3F6),
                        foregroundColor: const Color(0xFF111827),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C7BFE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.pay,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

  String _withAmount(String template, String amount) {
    return template.replaceAll('{amount}', amount);
  }
}

class PaymentSuccessDialog extends StatelessWidget {
  const PaymentSuccessDialog({
    super.key,
    required this.onClose,
    required this.onContinue,
  });

  final VoidCallback onClose;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  color: const Color(0xFF111827),
                  splashRadius: 18,
                ),
              ),
            ),
            Image.asset(
              'assets/images/icon-park-solid_success.png',
              height: 64,
              width: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.paymentSuccess,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C7BFE),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.continueLabel,
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
  }
}

class PaymentFailedDialog extends StatelessWidget {
  const PaymentFailedDialog({
    super.key,
    required this.onClose,
    required this.onOk,
  });

  final VoidCallback onClose;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  color: const Color(0xFF111827),
                  splashRadius: 18,
                ),
              ),
            ),
            Image.asset(
              'assets/images/failed.png',
              height: 64,
              width: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
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
              l10n.insufficientBalance,
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
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
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
  }
}
