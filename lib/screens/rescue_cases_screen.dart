// lib/screens/rescue_cases_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class RescueCasesScreen extends StatefulWidget {
  const RescueCasesScreen({super.key});
  @override
  State<RescueCasesScreen> createState() => _RescueCasesScreenState();
}

class _RescueCasesScreenState extends State<RescueCasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Rescue Cases', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary)),
          onPressed: () => Navigator.pop(context)),
        bottom: TabBar(controller: _tabs, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary, indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Pending'), Tab(text: 'Assigned'), Tab(text: 'Resolved')]),
      ),
      body: TabBarView(
        controller: _tabs,
        children: ['pending', 'assigned', 'resolved'].map((status) =>
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.rescueCasesStream(status: status),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No $status cases', style: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 16)),
              ]));
              return ListView.separated(
                padding: const EdgeInsets.all(16), itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CaseCard(doc: docs[i]),
              );
            },
          ),
        ).toList(),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _CaseCard({required this.doc});

  Color _urgencyColor(String? level) {
    switch (level) {
      case 'Code Red': return AppColors.danger;
      case 'Emergency': return const Color(0xFFFF5722);
      case 'Urgent': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final urgency = d['urgencyLevel'] ?? 'Routine';
    final c = _urgencyColor(urgency);
    final ts = (d['createdAt'] as Timestamp?)?.toDate();
    final timeStr = ts != null ? DateFormat('dd MMM, HH:mm').format(ts) : '';
    final status = d['status'] ?? 'pending';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          d['photoUrl'] != null
              ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(d['photoUrl'], height: 160, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 80, color: AppColors.surface)))
              : Container(height: 80, decoration: BoxDecoration(color: c.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                  child: Center(child: Icon(Icons.pets, size: 40, color: c.withOpacity(0.3)))),
          Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
              child: Text(urgency, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)))),
          Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Text('Sev: ${d['severityScore']}/10', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12)))),
        ]),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(d['animalType'] ?? 'Unknown', style: GoogleFonts.playfairDisplay(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
            Text(timeStr, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textLight)),
          ]),
          if (d['breed'] != null) Text(d['breed'], style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          if (d['aiSummary'] != null) Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary), const SizedBox(width: 6),
              Expanded(child: Text(d['aiSummary'], style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textPrimary, height: 1.4))),
            ])),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight), const SizedBox(width: 4),
            Expanded(child: Text(d['locationDescription'] ?? 'Location not specified',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary))),
          ]),
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () {
                  final user = FirebaseService.currentUser;
                  if (user == null) return;
                  FirebaseService.assignExpert(doc.id, user.uid, user.displayName ?? user.email ?? 'Expert');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Case accepted!', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                    backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: c,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text('Accept Case', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              )),
            ]),
          ],
          if (status == 'assigned') ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => FirebaseService.updateCaseStatus(doc.id, 'resolved'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text('Mark Resolved', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            )),
          ],
        ])),
      ]),
    );
  }
}
