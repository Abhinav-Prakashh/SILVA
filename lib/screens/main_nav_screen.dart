// lib/screens/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'species_screen.dart';
import 'report_rescue_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});
  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MapScreen(),
    SizedBox(), // placeholder for center camera button
    AlertsScreen(),
    SpeciesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: [
          const DashboardScreen(),
          const MapScreen(),
          const AlertsScreen(),
          const SpeciesScreen(),
        ],
      ),
      bottomNavigationBar: _SilvaNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportRescueScreen()));
          } else {
            setState(() => _currentIndex = i);
          }
        },
      ),
    );
  }
}

class _SilvaNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _SilvaNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              // Dashboard
              _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard', isActive: currentIndex == 0, onTap: () => onTap(0)),
              // Map
              _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map_rounded,
                  label: 'Map', isActive: currentIndex == 1, onTap: () => onTap(1)),

              // Centre camera button — pops up
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: SizedBox(
                    height: 66,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -22,
                          child: Container(
                            width: 58, height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withOpacity(0.45),
                                    blurRadius: 18, offset: const Offset(0, 6)),
                                BoxShadow(color: Colors.white, blurRadius: 0,
                                    spreadRadius: 3, offset: Offset.zero),
                              ],
                            ),
                            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          child: Text('Report', style: GoogleFonts.dmSans(
                              fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Alerts
              _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded,
                  label: 'Alerts', isActive: currentIndex == 3, onTap: () => onTap(3)),
              // Species
              _NavItem(icon: Icons.pets_outlined, activeIcon: Icons.pets_rounded,
                  label: 'Species', isActive: currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label,
      required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isActive ? activeIcon : icon, size: 22,
                color: isActive ? AppColors.primary : AppColors.textLight),
          ),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.dmSans(
              fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textLight)),
        ]),
      ),
    );
  }
}
