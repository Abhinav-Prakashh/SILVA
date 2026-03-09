// lib/screens/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Alerts', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Acknowledged'), Tab(text: 'Resolved')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: ['active', 'acknowledged', 'resolved'].map((status) =>
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.alertsStream(status: status),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No $status alerts', style: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 16)),
              ]));
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final severity = d['severity'] ?? 'medium';
                  final type = d['type'] ?? '';
                  final ts = (d['createdAt'] as Timestamp?)?.toDate();
                  final timeStr = ts != null ? DateFormat('dd MMM, HH:mm').format(ts) : '';
                  final sColor = _sColor(severity);
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sColor.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 42, height: 42,
                            decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_aIcon(type), color: sColor, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['animalName'] ?? 'Unknown', style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                          Text(timeStr, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textLight)),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: sColor, borderRadius: BorderRadius.circular(20)),
                            child: Text(severity.toUpperCase(),
                                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
                      ]),
                      const SizedBox(height: 12),
                      Text(d['message'] ?? '', style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                      // Show GPS for fence breaches
                      if (type == 'fence_breach' && d['location'] != null) ...[
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.fenceColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.fenceColor.withOpacity(0.2))),
                          child: Row(children: [
                            const Icon(Icons.my_location, size: 14, color: AppColors.fenceColor),
                            const SizedBox(width: 6),
                            Text('${(d['location']['latitude'] as num).toStringAsFixed(5)}, '
                                '${(d['location']['longitude'] as num).toStringAsFixed(5)}',
                                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fenceColor,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                      if (status == 'active') ...[
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () => FirebaseService.acknowledgeAlert(docs[i].id),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary,
                                side: BorderSide(color: AppColors.textLight.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: Text('Acknowledge', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton(
                            onPressed: () => FirebaseService.resolveAlert(docs[i].id, 'Resolved'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: Text('Resolve', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
                          )),
                        ]),
                      ],
                    ]),
                  );
                },
              );
            },
          ),
        ).toList(),
      ),
    );
  }
  Color _sColor(String s) {
    switch (s) { case 'critical': return AppColors.danger; case 'high': return AppColors.warning;
      default: return AppColors.info; }
  }
  IconData _aIcon(String t) {
    switch (t) { case 'fence_breach': return Icons.fence_rounded;
      case 'distress_no_movement': return Icons.warning_rounded;
      case 'temperature_high': return Icons.thermostat; case 'low_battery': return Icons.battery_alert;
      case 'rescue_case': return Icons.medical_services_rounded;
      default: return Icons.notifications_rounded; }
  }
}
