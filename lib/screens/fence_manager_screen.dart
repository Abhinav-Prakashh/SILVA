// lib/screens/fence_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class FenceManagerScreen extends StatefulWidget {
  const FenceManagerScreen({super.key});
  @override
  State<FenceManagerScreen> createState() => _FenceManagerScreenState();
}

class _FenceManagerScreenState extends State<FenceManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Fence Manager', style: GoogleFonts.playfairDisplay(
            fontSize: 22, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateFenceDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: Text('New Fence', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fenceColor, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            )),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.fenceColor,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.fenceColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
          tabs: const [Tab(text: 'All Fences'), Tab(text: '⚠️ Breaches')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // All fences
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.fencesStream(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return _emptyState('No fences created yet', Icons.fence_rounded);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FenceCard(doc: docs[i]),
              );
            },
          ),
          // Breaches only
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.fencesStream(),
            builder: (_, snap) {
              final all = snap.data?.docs ?? [];
              final breached = all.where((d) => (d.data() as Map)['isBreached'] == true).toList();
              if (breached.isEmpty) return _emptyState('No active breaches 🎉', Icons.check_circle_outline);
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: breached.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _FenceCard(doc: breached[i], highlightBreach: true),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 60, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text(msg, style: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 16)),
  ]));

  void _showCreateFenceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final animalCtrl = TextEditingController();
    final List<LatLng> points = [];
    bool isDrawing = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Create Fence Zone', style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Fence Name',
                    hintText: 'e.g. Kanha Tiger Zone')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: animalCtrl,
                decoration: const InputDecoration(
                    labelText: 'Animal IDs to monitor (comma separated)',
                    hintText: 'e.g. abc123, def456')),
            const SizedBox(height: 16),
            // Mini map to tap polygon points
            Container(
              height: 220,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fenceColor.withOpacity(0.4))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(22, 78), initialZoom: 3.5,
                    onTap: (_, latlng) {
                      if (isDrawing) {
                        setDialogState(() => points.add(latlng));
                      }
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.silva'),
                    if (points.isNotEmpty) PolylineLayer(polylines: [
                      Polyline(points: [...points, if (points.length > 1) points.first],
                          color: AppColors.fenceColor, strokeWidth: 2),
                    ]),
                    if (points.isNotEmpty) PolygonLayer(polygons: [
                      Polygon(points: points, color: AppColors.fenceColor.withOpacity(0.15),
                          borderColor: AppColors.fenceColor, borderStrokeWidth: 2),
                    ]),
                    MarkerLayer(markers: points.map((p) => Marker(
                      point: p, width: 16, height: 16,
                      child: Container(decoration: BoxDecoration(
                          color: AppColors.fenceColor, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2))),
                    )).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => setDialogState(() => isDrawing = !isDrawing),
                icon: Icon(isDrawing ? Icons.stop : Icons.edit_location_alt_rounded, size: 16),
                label: Text(isDrawing ? 'Stop Drawing' : 'Draw Fence',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.fenceColor,
                  side: const BorderSide(color: AppColors.fenceColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
              const SizedBox(width: 8),
              if (points.isNotEmpty)
                OutlinedButton(
                  onPressed: () => setDialogState(() => points.removeLast()),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Icon(Icons.undo, size: 16),
                ),
            ]),
            if (points.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text('${points.length} points drawn',
                      style: GoogleFonts.dmSans(color: AppColors.fenceColor, fontSize: 12,
                          fontWeight: FontWeight.w600))),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: points.length < 3 ? null : () async {
              final animalIds = animalCtrl.text.split(',')
                  .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              await FirebaseService.createFence({
                'name': nameCtrl.text.trim().isEmpty ? 'Unnamed Fence' : nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'polygon': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
                'assignedAnimals': animalIds,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Fence created!', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.fenceColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Create Fence', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      )),
    );
  }
}

class _FenceCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool highlightBreach;
  const _FenceCard({required this.doc, this.highlightBreach = false});

  @override
  Widget build(BuildContext context) {
    final d = doc.data() as Map<String, dynamic>;
    final isBreached = d['isBreached'] == true;
    final borderColor = isBreached ? AppColors.fenceBreach : AppColors.fenceColor;
    final pts = (d['polygon'] as List<dynamic>? ?? []).length;
    final animals = (d['assignedAnimals'] as List<dynamic>? ?? []).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(isBreached ? 0.5 : 0.2)),
        boxShadow: [BoxShadow(color: borderColor.withOpacity(0.06), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: borderColor.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: borderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.fence_rounded, color: borderColor, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['name'] ?? 'Unnamed Fence', style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              if (d['description'] != null && (d['description'] as String).isNotEmpty)
                Text(d['description'], style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (isBreached)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.fenceBreach,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('BREACHED', style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)))
            else
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.3))),
                  child: Text('ACTIVE', style: GoogleFonts.dmSans(
                      color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 10))),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats
          Row(children: [
            _Stat(icon: Icons.location_on, label: '$pts boundary points', color: AppColors.fenceColor),
            const SizedBox(width: 16),
            _Stat(icon: Icons.pets, label: '$animals animals monitored', color: AppColors.primary),
          ]),

          // Breach details
          if (isBreached) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fenceBreach.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fenceBreach.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_rounded, color: AppColors.fenceBreach, size: 16),
                  const SizedBox(width: 6),
                  Text('${d['breachedByAnimalName'] ?? 'Unknown'} has left the zone',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700,
                          fontSize: 13, color: AppColors.fenceBreach)),
                ]),
                const SizedBox(height: 8),
                if (d['breachLocationDescription'] != null)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(d['breachLocationDescription'],
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textPrimary, height: 1.4))),
                  ]),
                if (d['breachLat'] != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.my_location, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text('GPS: ${(d['breachLat'] as num).toStringAsFixed(5)}, '
                        '${(d['breachLng'] as num).toStringAsFixed(5)}',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textLight,
                            fontFamily: 'monospace')),
                  ]),
                ],
              ]),
            ),
          ],

          const SizedBox(height: 12),
          // Actions
          Row(children: [
            if (isBreached)
              Expanded(child: ElevatedButton.icon(
                onPressed: () => FirebaseService.updateFence(doc.id, {
                  'isBreached': false, 'breachedByAnimalId': null,
                  'breachedByAnimalName': null, 'breachLat': null, 'breachLng': null,
                }),
                icon: const Icon(Icons.check, size: 14),
                label: Text('Mark Safe', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              ))
            else
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: Text('Edit', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.fenceColor,
                    side: const BorderSide(color: AppColors.fenceColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, doc.id, d['name'] ?? 'this fence'),
              icon: const Icon(Icons.delete_outline, size: 14),
              label: Text('Delete', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
            ),
          ]),
        ])),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Delete Fence', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: Text('Are you sure you want to delete "$name"?',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { FirebaseService.deleteFence(id); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
