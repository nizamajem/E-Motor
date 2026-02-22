import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shell/main_shell.dart';
import '../../../components/bottom_nav.dart';
import '../../rental/data/rental_service.dart';
import '../../rental/data/emotor_service.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/network/api_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../components/app_motion.dart';
import '../../../components/app_feedback.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final RentalService _rentalService = RentalService();
  final EmotorService _emotorService = EmotorService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const _BackgroundBlob(),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A2C7BFE),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/dashboard.png',
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.welcomeBack,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        // Intentionally hide EMOTOR_ID warning in UI.
                      ],
                    ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 18,
                          offset: Offset(0, 12),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE7EBF3)),
                    ),
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InputField(
                            label: l10n.username,
                            hint: l10n.usernameHint,
                            icon: Icons.person_rounded,
                            controller: _usernameController,
                            obscure: false,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 14),
                          _InputField(
                            label: l10n.password,
                            hint: l10n.passwordHint,
                            icon: Icons.lock_rounded,
                            obscure: _obscure,
                            controller: _passwordController,
                            onToggleObscure: () {
                              setState(() => _obscure = !_obscure);
                            },
                          ),
                          const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showContactAdminDialog(
                              context,
                              reason: _ContactReason.resetPassword,
                              username: _usernameController.text.trim(),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2C7BFE),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.forgotPassword,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C7BFE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              textStyle: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(l10n.signIn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          TextSpan(text: l10n.noAccount),
                          TextSpan(
                            text: l10n.contactAdmin,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C7BFE),
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showContactAdminDialog(
                                context,
                                reason: _ContactReason.newAccount,
                                username: _usernameController.text.trim(),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack(l10n.loginRequired);
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _rentalService.login(username: username, password: password);
      // Fetch e-motor bound to this user if not provided via dart-define.
      await _ensureEmotorId();
      final restored = await _rentalService.restoreActiveRental();
      debugPrint('login screen sessionEmotorId=${SessionManager.instance.emotorId}');
      if (!mounted) return;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        appRoute(
          MainShell(
            initialTab: BottomNavTab.dashboard,
            initialRental: restored,
          ),
        ),
      );
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ensureEmotorId({bool forceRefresh = false}) async {
    if (!forceRefresh && (SessionManager.instance.emotorId ?? '').isNotEmpty) {
      return;
    }
    if (!forceRefresh && ApiConfig.emotorId.isNotEmpty) {
      await SessionManager.instance.saveEmotorId(ApiConfig.emotorId);
      return;
    }
    if (forceRefresh) {
      await SessionManager.instance.saveEmotorId('');
      await SessionManager.instance.saveEmotorImei('');
    }
    final userId = SessionManager.instance.user?.userId;
    if (userId == null || userId.isEmpty) return;
    final emotor = await _emotorService.fetchAssignedToUser(userId);
    if (emotor != null) {
      await SessionManager.instance.saveEmotorId(emotor.id);
    } else {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context).emotorNotAssigned);
    }
  }

  void _showSnack(String message) {
    showErrorSnack(context, message);
  }

}

enum _ContactReason { resetPassword, newAccount }

Future<void> _showContactAdminDialog(
  BuildContext context, {
  required _ContactReason reason,
  String? username,
}) async {
  final l10n = AppLocalizations.of(context);
  const phoneNumber = '+62 821-4454-0304';
  const waNumber = '6282144540304';
  final cleanUsername = (username ?? '').trim();
  final usernameSuffix =
      cleanUsername.isNotEmpty ? ' ${l10n.username}: $cleanUsername.' : '';
  final message = reason == _ContactReason.resetPassword
      ? l10n.contactAdminResetMessage(usernameSuffix)
      : l10n.contactAdminNewMessage(usernameSuffix);
  final encodedMessage = Uri.encodeComponent(message);
  final url = Uri.parse('https://wa.me/$waNumber?text=$encodedMessage');
  await showAppDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                      l10n.contactAdminTitle,
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
                        onPressed: () => Navigator.of(dialogContext).pop(),
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
                l10n.contactAdminBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7B8190),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD6E4FF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded,
                        color: Color(0xFF25D366), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      phoneNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await launchUrl(url, mode: LaunchMode.externalApplication);
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
                    l10n.contactAdminButton,
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.controller,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5EAF2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  obscureText: obscure,
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
              if (onToggleObscure != null)
                IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: onToggleObscure,
                  splashRadius: 18,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackgroundBlob extends StatelessWidget {
  const _BackgroundBlob();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF4FF), Colors.white],
            stops: [0.0, 0.45],
          ),
        ),
      ),
    );
  }
}
