// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  bool _isLoading = false, _isSocialLoading = false, _obscure = true, _isRegister = false;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _goHome() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavScreen()));

  Future<void> _emailSubmit() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isRegister) {
        final cred = await FirebaseService.registerWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
        await FirebaseService.saveUserProfile(cred.user!.uid, {
          'name': _nameCtrl.text.trim(), 'email': _emailCtrl.text.trim(), 'role': 'volunteer',
        });
      } else {
        await FirebaseService.loginWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      setState(() { _error = switch (e.code) {
        'user-not-found'      => 'No account found with this email',
        'wrong-password'      => 'Incorrect password',
        'email-already-in-use'=> 'Email already registered',
        'weak-password'       => 'Password must be at least 6 characters',
        _                     => e.message ?? 'Authentication failed',
      }; });
    } finally { setState(() => _isLoading = false); }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isSocialLoading = true; _error = null; });
    try {
      final r = await FirebaseService.signInWithGoogle();
      if (r == null) return;
      if (!mounted) return;
      _goHome();
    } catch (e) { setState(() => _error = 'Google sign-in failed.'); }
    finally { setState(() => _isSocialLoading = false); }
  }

  Future<void> _appleSignIn() async {
    setState(() { _isSocialLoading = true; _error = null; });
    try {
      final r = await FirebaseService.signInWithApple();
      if (r == null) return;
      if (!mounted) return;
      _goHome();
    } catch (e) { setState(() => _error = 'Apple sign-in failed.'); }
    finally { setState(() => _isSocialLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8EE), Color(0xFFFDF0D5)]),
        ),
        child: SafeArea(child: FadeTransition(opacity: _fade, child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 20),
            Center(child: Column(children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
                child: const Icon(Icons.track_changes_rounded, size: 44, color: Colors.white)),
              const SizedBox(height: 16),
              Text('SILVA', style: GoogleFonts.playfairDisplay(
                  fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text(_isRegister ? 'Create your account' : 'Welcome back',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
            ])),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_error != null)
                  Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                    ])),
                if (_isRegister) ...[
                  TextField(controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.textLight))),
                  const SizedBox(height: 14),
                ],
                TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.textLight))),
                const SizedBox(height: 14),
                TextField(controller: _passwordCtrl, obscureText: _obscure,
                    decoration: InputDecoration(labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textLight),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textLight),
                          onPressed: () => setState(() => _obscure = !_obscure)))),
                const SizedBox(height: 20),
                SizedBox(height: 52, child: ElevatedButton(
                  onPressed: _isLoading ? null : _emailSubmit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isRegister ? 'Create Account' : 'Sign In',
                          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                )),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with', style: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 12))),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ]),
                const SizedBox(height: 16),
                _SocialBtn(onTap: _isSocialLoading ? null : _googleSignIn, isLoading: _isSocialLoading,
                    iconWidget: Container(width: 22, height: 22,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
                        child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)))),
                    label: 'Continue with Google', bgColor: Colors.white, borderColor: Colors.grey.shade200),
                const SizedBox(height: 10),
                _SocialBtn(onTap: _isSocialLoading ? null : _appleSignIn, isLoading: false,
                    iconWidget: const Icon(Icons.apple, size: 22, color: Colors.white),
                    label: 'Continue with Apple', bgColor: Colors.black, textColor: Colors.white, borderColor: Colors.black),
              ]),
            ),
            const SizedBox(height: 20),
            Center(child: TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
              child: RichText(text: TextSpan(
                style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
                children: [
                  TextSpan(text: _isRegister ? 'Already have an account? ' : "Don't have an account? "),
                  TextSpan(text: _isRegister ? 'Sign In' : 'Register',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              )),
            )),
          ]),
        ))),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget iconWidget;
  final String label;
  final Color bgColor, borderColor;
  final Color? textColor;
  const _SocialBtn({required this.onTap, required this.isLoading, required this.iconWidget,
      required this.label, required this.bgColor, required this.borderColor, this.textColor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(height: 50,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor)),
        child: isLoading
            ? Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(textColor ?? AppColors.textPrimary))))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                iconWidget, const SizedBox(width: 10),
                Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.textPrimary)),
              ]),
      ),
    );
  }
}
