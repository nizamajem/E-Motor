import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../components/app_motion.dart';
import '../../../components/app_feedback.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/network/api_config.dart';
import '../../../core/navigation/app_route.dart';
import '../data/topup_service.dart';
import '../data/recharge_service.dart';
import '../../profile/data/user_service.dart';
import '../../payment/presentation/payment_webview_screen.dart';
class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final List<_RechargeOption> _options = [
    const _RechargeOption.custom(),
  ];

  int _selectedIndex = 0;
  bool _isSubmitting = false;
  bool _optionsLoading = true;
  int _customAmount = 0;
  final TopupService _topupService = TopupService();
  final RechargeService _rechargeService = RechargeService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadRechargeOptions();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _options[_selectedIndex];
    final displayAmount =
        selected.isCustom ? _customAmount : selected.amount;
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
                          _formatRupiah(displayAmount),
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_optionsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: CircularProgressIndicator(),
                      )
                    else
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
                            customAmount: _customAmount,
                            isSelected: isSelected,
                            onTap: () => _handleOptionTap(index, option),
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

  Future<void> _loadRechargeOptions() async {
    setState(() => _optionsLoading = true);
    try {
      String? tenantId;
      String? merchantId;
      for (var attempt = 0; attempt < 3; attempt++) {
        tenantId = _resolveTenantId();
        merchantId = _resolveMerchantId();
        if ((tenantId != null && tenantId.isNotEmpty) ||
            (merchantId != null && merchantId.isNotEmpty)) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      final items = await _rechargeService.fetchRechargeOptions(
        tenantId: tenantId,
        merchantId: merchantId,
      );
      final mapped = items
          .map(_mapRechargeToOption)
          .where((option) => option.amount > 0)
          .toList()
        ..sort((a, b) => a.amount.compareTo(b.amount));
      if (mapped.isNotEmpty && mounted) {
        setState(() {
          _options
            ..clear()
            ..addAll(mapped)
            ..add(const _RechargeOption.custom());
          if (_selectedIndex >= _options.length) {
            _selectedIndex = 0;
          }
        });
      }
    } catch (_) {
      // Keep default options on failure.
    } finally {
      if (mounted) {
        setState(() => _optionsLoading = false);
      }
    }
  }

  _RechargeOption _mapRechargeToOption(RechargeOptionDto dto) {
    final amount = _parseDecimalInt(dto.amount);
    final bonus = _parseDecimalInt(dto.giftNumber);
    return _RechargeOption(
      amount: amount,
      bonus: bonus,
      giftType: dto.giftType,
    );
  }

  int _parseDecimalInt(String value) {
    final cleaned = value.replaceAll(',', '.');
    final parsed = double.tryParse(cleaned);
    if (parsed != null) return parsed.round();
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  String? _resolveTenantId() {
    final profile = SessionManager.instance.userProfile;
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    String? readFromMap(Map<String, dynamic>? map, List<String> keys) {
      if (map == null) return null;
      for (final key in keys) {
        final value = read(map[key]);
        if (value != null) return value;
      }
      return null;
    }

    final direct = readFromMap(profile, ['tenantId', 'tenant_id', 'id_tenant']);
    if (direct != null) return direct;

    final tenantAdmin = profile?['tenantAdmin'] ??
        profile?['tenant_admin'] ??
        profile?['TenantAdmin'] ??
        profile?['tenantAdminProfile'] ??
        profile?['tenant_admin_profile'];
    if (tenantAdmin is Map<String, dynamic>) {
      final fromAdmin = readFromMap(
        tenantAdmin,
        ['tenantId', 'tenant_id', 'id_tenant', 'id'],
      );
      if (fromAdmin != null) return fromAdmin;
      final nestedTenant = tenantAdmin['tenant'] ?? tenantAdmin['Tenant'];
      if (nestedTenant is Map<String, dynamic>) {
        final fromTenant = readFromMap(
          nestedTenant,
          ['id', 'tenantId', 'tenant_id', 'id_tenant'],
        );
        if (fromTenant != null) return fromTenant;
      }
    }

    final tenant = profile?['tenant'] ?? profile?['Tenant'];
    if (tenant is Map<String, dynamic>) {
      final fromTenant = readFromMap(
        tenant,
        ['id', 'tenantId', 'tenant_id', 'id_tenant'],
      );
      if (fromTenant != null) return fromTenant;
    }

    return null;
  }

  String? _resolveMerchantId() {
    final profile = SessionManager.instance.userProfile;
    final merchant = profile?['merchantId']?.toString().trim() ??
        profile?['merchant_id']?.toString().trim() ??
        profile?['id_merchant']?.toString().trim();
    return (merchant == null || merchant.isEmpty) ? null : merchant;
  }

  Future<void> _handleOptionTap(int index, _RechargeOption option) async {
    if (!option.isCustom) {
      setState(() => _selectedIndex = index);
      return;
    }
    final amount = await _promptCustomAmount();
    if (!mounted) return;
    if (amount == null || amount <= 0) {
      _showSnack(AppLocalizations.of(context).rechargePrompt);
      return;
    }
    setState(() {
      _customAmount = amount;
      _selectedIndex = index;
    });
  }

  Future<int?> _promptCustomAmount() async {
    final controller = TextEditingController(
      text: _customAmount > 0 ? _customAmount.toString() : '',
    );
    return showAppDialog<int>(
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
                Text(
                  l10n.rechargeCustom,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: l10n.rechargeCustomHint,
                    filled: true,
                    fillColor: const Color(0xFFF4F6F9),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      final value = int.tryParse(text) ?? 0;
                      Navigator.of(dialogContext).pop(value > 0 ? value : null);
                    },
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

  Future<void> _handleTopup() async {
    if (_isSubmitting) return;
    var customerId = SessionManager.instance.customerId ?? '';
    var walletId = SessionManager.instance.customerWalletId ?? '';
    if (customerId.isEmpty || walletId.isEmpty) {
      final resolved = await _ensureCustomerData();
      customerId = resolved.$1;
      walletId = resolved.$2;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (customerId.isEmpty && walletId.isEmpty) {
        _showMidtransNotReadyDialog(message: l10n.topupWalletMissing);
        return;
      }
    }
    final selected = _options[_selectedIndex];
    final amount = selected.isCustom ? _customAmount : selected.amount;
    if (amount <= 0) {
      _showSnack(AppLocalizations.of(context).rechargePrompt);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await SessionManager.instance.clearPendingTopup();
      final res = await _topupService.createSnap(
        customerId: customerId,
        customerWalletId: walletId,
        amount: amount,
        isSandbox: false,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (res == null || res.snapToken.isEmpty) {
        _showSnack(l10n.topupFailed);
        return;
      }
      await SessionManager.instance.savePendingTopup(
        snapToken: res.snapToken,
        orderId: res.orderId,
      );
      if (!mounted) return;
      final webUrl = _resolveMidtransUrl(res.redirectUrl, res.snapToken);
      if (webUrl.isEmpty) {
        _showMidtransNotReadyDialog(message: l10n.snapTokenMissing);
        return;
      }
      final resultStatus = await Navigator.of(context).push(
        appRoute(
          PaymentWebViewScreen(
            url: webUrl,
            paymentId: res.orderId,
            statusMode: PaymentStatusMode.topup,
          ),
          direction: AxisDirection.left,
        ),
      );
      if (!mounted) return;
      await _handleTopupResult(resultStatus);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
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

  Future<(String, String)> _ensureCustomerData() async {
    try {
      final userId = await SessionManager.instance.resolveUserId();
      if (userId.isEmpty) {
        return (
          SessionManager.instance.customerId ?? '',
          SessionManager.instance.customerWalletId ?? '',
        );
      }
      final profile = await _userService.fetchUserById(userId);
      if (profile != null) {
        await SessionManager.instance.saveUserProfile(profile);
        if (mounted) setState(() {});
      }
    } catch (_) {}
    return (
      SessionManager.instance.customerId ?? '',
      SessionManager.instance.customerWalletId ?? '',
    );
  }

  String _resolveMidtransUrl(String redirectUrl, String token) {
    final cleaned = redirectUrl.trim();
    if (cleaned.isNotEmpty) return cleaned;
    if (token.isEmpty) return '';
    final base = ApiConfig.midtransMerchantBaseUrl.toLowerCase();
    final apiBase = ApiConfig.baseUrl.toLowerCase();
    final isSandbox =
        base.contains('sandbox') ||
        base.contains('staging') ||
        base.contains('dev') ||
        apiBase.contains('sandbox') ||
        apiBase.contains('staging') ||
        apiBase.contains('dev');
    final host =
        isSandbox ? 'https://app.sandbox.midtrans.com' : 'https://app.midtrans.com';
    return '$host/snap/v2/vtweb/$token';
  }

  Future<void> _handleTopupResult(dynamic resultStatus) async {
    final l10n = AppLocalizations.of(context);
    if (resultStatus == PaymentWebViewResult.success) {
      await SessionManager.instance.clearPendingTopup();
      await _refreshBalance();
      if (!mounted) return;
      await _showTopupSuccessDialog();
      return;
    }
    if (resultStatus == PaymentWebViewResult.failed) {
      _showSnack(l10n.paymentFailed);
      return;
    }
    _showSnack(l10n.paymentPendingBody);
  }

  Future<void> _refreshBalance() async {
    try {
      final userId = await SessionManager.instance.resolveUserId();
      if (userId.isEmpty) return;
      final profile = await _userService.fetchUserById(userId);
      if (profile != null) {
        await SessionManager.instance.saveUserProfile(profile);
        final customer = profile['Customer'] ?? profile['customer'];
        if (customer is Map<String, dynamic>) {
          final wallet =
              customer['CustomerWallet'] ??
              customer['customerWallet'] ??
              customer['customer_wallet'];
          if (wallet is Map<String, dynamic>) {
            await SessionManager.instance.saveWalletProfile(wallet);
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _showTopupSuccessDialog() async {
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
                const SizedBox(height: 8),
                Text(
                  l10n.topupRedirected,
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
      },
    );
  }

  Future<void> _retryPendingTopup() async {
    final token = SessionManager.instance.pendingTopupSnapToken ?? '';
    if (token.isEmpty) return;
    final orderId = SessionManager.instance.pendingTopupOrderId ?? '';
    final webUrl = _resolveMidtransUrl('', token);
    if (webUrl.isEmpty) {
      _showMidtransNotReadyDialog();
      return;
    }
    final resultStatus = await Navigator.of(context).push(
      appRoute(
        PaymentWebViewScreen(
          url: webUrl,
          paymentId: orderId,
          statusMode: PaymentStatusMode.topup,
        ),
        direction: AxisDirection.left,
      ),
    );
    if (!mounted) return;
    await _handleTopupResult(resultStatus);
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
    this.giftType = '',
    this.isCustom = false,
  });

  const _RechargeOption.custom()
      : amount = 0,
        bonus = 0,
        giftType = '',
        isCustom = true;

  final int amount;
  final int bonus;
  final String giftType;
  final bool isCustom;
}

class _RechargeOptionCard extends StatelessWidget {
  const _RechargeOptionCard({
    required this.option,
    required this.customAmount,
    required this.isSelected,
    required this.onTap,
  });

  final _RechargeOption option;
  final int customAmount;
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
    final l10n = AppLocalizations.of(context);
    final isCustom = option.isCustom;
    final isPoints = option.giftType.toLowerCase() == 'points';
    final title = isCustom ? l10n.rechargeCustom : _formatRupiah(option.amount);
    final bonusText = isCustom
        ? (customAmount > 0
            ? _formatRupiah(customAmount)
            : l10n.rechargeCustomHint)
        : isPoints
            ? '${option.bonus} ${l10n.points}'
            : '${l10n.bonus} ${_formatRupiah(option.bonus)}';
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
              title,
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
                  bonusText,
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
