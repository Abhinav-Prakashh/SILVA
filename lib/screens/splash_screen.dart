// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1, curve: Curves.easeOut)));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => user != null ? const MainNavScreen() : const LoginScreen()));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8EE), Color(0xFFFDF0D5), Color(0xFFFFE0A0)]),
        ),
        child: Stack(children: [
          Positioned(top: 60, right: 30, child: Icon(Icons.pets, size: 80, color: AppColors.primary.withOpacity(0.08))),
          Positioned(bottom: 120, left: 20, child: Icon(Icons.pets, size: 60, color: AppColors.primary.withOpacity(0.06))),
          Positioned(top: 200, left: 50, child: Icon(Icons.pets, size: 40, color: AppColors.primary.withOpacity(0.05))),
          Center(
            child: AnimatedBuilder(animation: _ctrl, builder: (_, __) => FadeTransition(
              opacity: _fade,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(scale: _scale, child: Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 12))]),
                  child: const Icon(Icons.track_changes_rounded, size: 60, color: Colors.white),
                )),
                const SizedBox(height: 28),
                SlideTransition(position: _slide, child: Column(children: [
                  Text('SILVA', style: GoogleFonts.playfairDisplay(
                      fontSize: 52, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 6)),
                  const SizedBox(height: 8),
                  Text('Track • Rescue • Protect', style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textSecondary, letterSpacing: 3, fontWeight: FontWeight.w500)),
                ])),
                const SizedBox(height: 60),
                SizedBox(width: 32, height: 32,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary), strokeWidth: 2.5)),
              ]),
            )),
          ),
        ]),
      ),
    );
  }
}
