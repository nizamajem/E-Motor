import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../rental/data/rental_service.dart';
import '../../rental/data/emotor_service.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/network/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _isLoading = false;
  bool _isFlowLoading = false;
  final _usernameController = TextEditingController(text: 'demo');
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
    final emotorId = ApiConfig.emotorId;
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
                  _LanguagePill(),
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
                          'Welcome back!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue your ride with Gridwiz E-Motor.',
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
                            label: 'Username',
                            hint: 'Enter your username',
                            icon: Icons.person_rounded,
                            controller: _usernameController,
                            obscure: false,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 14),
                          _InputField(
                            label: 'Kata Sandi',
                            hint: 'Enter your password',
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
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2C7BFE),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
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
                            onPressed: (_isLoading || _isFlowLoading) ? null : _handleLogin,
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
                                : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_isLoading || _isFlowLoading)
                                ? null
                                : _handleRunFullFlow,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2C7BFE),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13, horizontal: 16),
                              side: const BorderSide(color: Color(0xFF2C7BFE)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: _isFlowLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation(Color(0xFF2C7BFE)),
                                    ),
                                  )
                                : const Text('Run Full Flow'),
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
                          const TextSpan(text: "Don't have account? "),
                          TextSpan(
                            text: 'Contact Admin',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C7BFE),
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack('Username dan password harus diisi');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await _rentalService.login(username: username, password: password);
      // Fetch e-motor bound to this user if not provided via dart-define.
      await _ensureEmotorId();
      debugPrint('login screen sessionEmotorId=${SessionManager.instance.emotorId}');
      if (!mounted) return;
      final startNow = await _confirmStartRental();
      RentalSession? rental;
      if (startNow == true) {
        try {
          rental = await _rentalService.startRental();
        } on ApiException catch (e) {
          // Jika start rental gagal, tetap izinkan masuk dashboard (login sudah sukses).
          final message = e.message.toLowerCase();
          if (e.statusCode == 404) {
            _showSnack('Start rental endpoint tidak ditemukan, membuka dashboard saja.');
          } else if (e.statusCode == 400 &&
              message.contains('bound') &&
              message.contains('user')) {
            await _ensureEmotorId(forceRefresh: true);
            try {
              rental = await _rentalService.startRental();
            } on ApiException {
              _showSnack('E-motor sudah terikat ke user lain. Membuka dashboard saja.');
            }
          } else {
            rethrow;
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(appRoute(DashboardScreen(initialRental: rental)));
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

  Future<void> _handleRunFullFlow() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showSnack('Username dan password harus diisi');
      return;
    }
    setState(() {
      _isFlowLoading = true;
    });
    try {
      await _rentalService.runFullFlow(
        username: username,
        password: password,
        stepDelay: const Duration(milliseconds: 800),
      );
      if (!mounted) return;
      _showSnack('Flow selesai.');
    } catch (e) {
      _showSnack('Flow gagal: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFlowLoading = false;
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
      _showSnack('Tidak menemukan e-motor yang terikat ke akun ini.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool?> _confirmStartRental() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mulai Rental?'),
          content: const Text('Login berhasil. Mulai rental sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mulai'),
            ),
          ],
        );
      },
    );
  }
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

class _LanguagePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language_rounded, size: 18, color: Color(0xFF2C7BFE)),
          const SizedBox(width: 8),
          Text(
            'English',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded,
              size: 20, color: Colors.grey.shade500),
        ],
      ),
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
