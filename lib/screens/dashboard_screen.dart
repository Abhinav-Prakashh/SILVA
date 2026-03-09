// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import 'animal_detail_screen.dart';
import 'map_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(children: [
                    Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 22)),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SILVA', style: GoogleFonts.playfairDisplay(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 3)),
                      Text('Wildlife Monitoring', style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
                    ]),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withOpacity(0.3))),
                      child: Row(children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text('Live', style: GoogleFonts.dmSans(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── STAT CARDS ─────────────────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.animalsStream(),
                  builder: (_, animalSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService.alertsStream(status: 'active'),
                      builder: (_, alertSnap) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseService.fencesStream(),
                          builder: (_, fenceSnap) {
                            final totalAnimals = animalSnap.data?.docs.length ?? 0;
                            final distressCount = animalSnap.data?.docs
                                .where((d) => (d.data() as Map)['distressTriggered'] == true).length ?? 0;
                            final alertCount = alertSnap.data?.docs.length ?? 0;
                            final fences = fenceSnap.data?.docs ?? [];
                            final breachedFences = fences.where((d) => (d.data() as Map)['isBreached'] == true).length;

                            return Column(children: [
                              Row(children: [
                                Expanded(child: _StatCard(label: 'Animals', value: '$totalAnimals',
                                    icon: Icons.pets, color: AppColors.primary)),
                                const SizedBox(width: 10),
                                Expanded(child: _StatCard(label: 'Distress', value: '$distressCount',
                                    icon: Icons.warning_rounded, color: AppColors.danger)),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(child: _StatCard(label: 'Active Alerts', value: '$alertCount',
                                    icon: Icons.notifications_active, color: AppColors.warning)),
                                const SizedBox(width: 10),
                                Expanded(child: _StatCard(label: 'Fence Breaches', value: '$breachedFences',
                                    icon: Icons.fence_rounded, color: AppColors.fenceColor)),
                              ]),
                            ]);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── FENCE BREACH ALERTS ────────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.fencesStream(),
                  builder: (_, snap) {
                    final breached = snap.data?.docs
                        .where((d) => (d.data() as Map)['isBreached'] == true).toList() ?? [];
                    if (breached.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _SectionTitle(title: '🚧 Fence Breaches', actionLabel: 'View Map', onAction: () {
                        // Switch to map tab
                      }),
                      ...breached.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _FenceBreachCard(data: d);
                      }),
                      const SizedBox(height: 24),
                    ]);
                  },
                ),

                // ── ANIMALS IN DISTRESS ────────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.distressAnimalsStream(),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _SectionTitle(title: '🚨 Animals in Distress'),
                      SizedBox(height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            return _DistressChip(name: d['name'] ?? '', species: d['species'] ?? '',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => AnimalDetailScreen(animalId: docs[i].id))));
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]);
                  },
                ),

                // ── ALL ANIMALS ────────────────────────────────────────────────
                const _SectionTitle(title: 'All Animals'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.animalsStream(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator()));
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('No animals tracked yet',
                          style: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 15))),
                    );
                    return ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        return _AnimalRow(data: d, animalId: docs[i].id);
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),
                // ── RECENT ALERTS ──────────────────────────────────────────────
                const _SectionTitle(title: 'Recent Alerts'),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.alertsStream(status: 'active'),
                  builder: (_, snap) {
                    final docs = snap.data?.docs.take(3).toList() ?? [];
                    if (docs.isEmpty) return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.success.withOpacity(0.2))),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 10),
                        Text('All clear — no active alerts', style: GoogleFonts.dmSans(
                            color: AppColors.success, fontWeight: FontWeight.w600)),
                      ]),
                    );
                    return Column(children: docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return _AlertRow(data: d);
                    }).toList());
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── WIDGETS ────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: GoogleFonts.playfairDisplay(
              fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(title, style: GoogleFonts.playfairDisplay(
            fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!,
              style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}

class _FenceBreachCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FenceBreachCard({required this.data});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fenceBreach.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.fenceBreach.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.fenceBreach.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fence_rounded, color: AppColors.fenceBreach, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name'] ?? 'Fence', style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            Text('Breached by ${data['breachedByAnimalName'] ?? 'Unknown'}',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.fenceBreach, fontWeight: FontWeight.w600)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.fenceBreach, borderRadius: BorderRadius.circular(20)),
              child: Text('BREACH', style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10))),
        ]),
        if (data['breachLocationDescription'] != null) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.fenceBreach.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.fenceBreach),
                const SizedBox(width: 6),
                Expanded(child: Text(data['breachLocationDescription'],
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textPrimary, height: 1.4))),
              ])),
        ],
        if (data['breachLat'] != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.my_location, size: 12, color: AppColors.textLight),
            const SizedBox(width: 4),
            Text('GPS: ${(data['breachLat'] as num).toStringAsFixed(4)}, ${(data['breachLng'] as num).toStringAsFixed(4)}',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textLight)),
          ]),
        ],
      ]),
    );
  }
}

class _DistressChip extends StatelessWidget {
  final String name, species;
  final VoidCallback onTap;
  const _DistressChip({required this.name, required this.species, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: AppColors.danger.withOpacity(0.06), blurRadius: 12)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: AppColors.danger, size: 18)),
          const SizedBox(height: 8),
          Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          Text(species, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _AnimalRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String animalId;
  const _AnimalRow({required this.data, required this.animalId});
  @override
  Widget build(BuildContext context) {
    final isDistress = data['distressTriggered'] == true;
    final temp = (data['lastBodyTemperature'] as num?)?.toDouble();
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AnimalDetailScreen(animalId: animalId))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDistress ? AppColors.danger.withOpacity(0.3) : AppColors.textLight.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: isDistress ? AppColors.danger.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                image: data['imageUrl'] != null ? DecorationImage(
                    image: NetworkImage(data['imageUrl']), fit: BoxFit.cover) : null,
              ),
              child: data['imageUrl'] == null
                  ? Icon(Icons.pets, color: isDistress ? AppColors.danger : AppColors.primary, size: 22) : null),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(data['name'] ?? '', style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              if (isDistress) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                    child: Text('DISTRESS', style: GoogleFonts.dmSans(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
              ],
            ]),
            Text(data['species'] ?? '', style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (temp != null)
              Text('${temp.toStringAsFixed(1)}°C', style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: temp > 40 ? AppColors.danger : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Container(width: 8, height: 8, decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle)),
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
        ]),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AlertRow({required this.data});
  Color get _color {
    switch (data['severity']) {
      case 'critical': return AppColors.danger;
      case 'high':     return AppColors.warning;
      default:         return AppColors.info;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_alertIcon(data['type'] ?? ''), color: _color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(data['message'] ?? '', style: GoogleFonts.dmSans(
            fontSize: 12, color: AppColors.textPrimary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text((data['severity'] ?? '').toUpperCase(),
                style: GoogleFonts.dmSans(color: _color, fontWeight: FontWeight.w700, fontSize: 9))),
      ]),
    );
  }
  IconData _alertIcon(String t) {
    switch (t) {
      case 'fence_breach':          return Icons.fence_rounded;
      case 'distress_no_movement':  return Icons.warning_rounded;
      case 'temperature_high':      return Icons.thermostat;
      case 'low_battery':           return Icons.battery_alert;
      case 'rescue_case':           return Icons.medical_services_rounded;
      default:                      return Icons.notifications_rounded;
    }
  }
}
