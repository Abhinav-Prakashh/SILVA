// lib/screens/animal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../widgets/vital_card.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;
  const AnimalDetailScreen({super.key, required this.animalId});
  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('animals').doc(widget.animalId).snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: Text('Not found')));
        final isDistress = data['distressTriggered'] == true;
        final lastTemp = (data['lastBodyTemperature'] as num?)?.toDouble();
        final lastHR = data['lastHeartRate'] as int?;
        final lastSignal = (data['lastSignalTime'] as Timestamp?)?.toDate();
        final lastMove = (data['lastMovementTime'] as Timestamp?)?.toDate();
        final hoursSinceMove = lastMove != null ? DateTime.now().difference(lastMove).inHours : null;
        final aiSummary = data['aiSummary'] as String?;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 220, pinned: true, backgroundColor: AppColors.background,
                leading: Padding(padding: const EdgeInsets.all(8), child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary)))),
                actions: [Padding(padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => FirebaseService.toggleFavorite(widget.animalId, !(data['isFavorite'] ?? false)),
                      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                          child: Icon(data['isFavorite'] == true ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: data['isFavorite'] == true ? AppColors.primary : AppColors.textLight))))],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    data['imageUrl'] != null
                        ? Image.network(data['imageUrl'], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.surface))
                        : Container(decoration: BoxDecoration(gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.6), AppColors.primaryLight],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)),
                            child: const Icon(Icons.pets, size: 80, color: Colors.white30)),
                    Container(decoration: BoxDecoration(gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)]))),
                    if (isDistress) Container(color: Colors.red.withOpacity(0.2),
                        child: const Center(child: Icon(Icons.warning_rounded, color: Colors.white, size: 60))),
                    Positioned(bottom: 16, left: 16, right: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['name'] ?? '', style: GoogleFonts.playfairDisplay(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                      Text(data['scientificName'] ?? data['species'] ?? '', style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
                    ])),
                  ]),
                ),
              ),
            ],
            body: Column(children: [
              if (isDistress) Container(color: AppColors.danger,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.warning_rounded, color: Colors.white, size: 18), const SizedBox(width: 8),
                  Expanded(child: Text('🚨 No movement for ${hoursSinceMove ?? '12+'}h — DISTRESS',
                      style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  TextButton(onPressed: () => _resolveDialog(context), style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('RESOLVE')),
                ])),
              Container(color: Colors.white, child: TabBar(controller: _tabController,
                labelColor: AppColors.primary, unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primary, indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                tabs: const [Tab(text: 'Overview'), Tab(text: 'Temperature'), Tab(text: 'History')])),
              Expanded(child: TabBarView(controller: _tabController, children: [
                SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
                  if (aiSummary != null && aiSummary.isNotEmpty) ...[
                    Container(padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(gradient: LinearGradient(
                          colors: [AppColors.primary.withOpacity(0.08), AppColors.primaryLight.withOpacity(0.1)]),
                          borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16), const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AI Summary', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.primary)),
                          const SizedBox(height: 3),
                          Text(aiSummary, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
                        ])),
                      ])),
                  ],
                  Row(children: [
                    Expanded(child: VitalCard(title: 'Body Temp',
                        value: lastTemp != null ? '${lastTemp.toStringAsFixed(1)}°C' : '--',
                        icon: Icons.thermostat, color: lastTemp != null && lastTemp > 40 ? AppColors.danger : AppColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: VitalCard(title: 'Heart Rate', value: lastHR != null ? '$lastHR bpm' : '--',
                        icon: Icons.favorite_rounded, color: AppColors.danger)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: VitalCard(title: 'Last Signal',
                        value: lastSignal != null ? DateFormat('HH:mm').format(lastSignal) : '--',
                        icon: Icons.signal_cellular_alt, color: AppColors.success)),
                    const SizedBox(width: 12),
                    Expanded(child: VitalCard(title: 'Last Move',
                        value: hoursSinceMove != null ? '${hoursSinceMove}h ago' : '--',
                        icon: Icons.directions_walk,
                        color: (hoursSinceMove ?? 0) >= 12 ? AppColors.danger : AppColors.info)),
                  ]),
                  const SizedBox(height: 16),
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Animal Info', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
                      const Divider(height: 20),
                      ...[['Tag ID', data['tagId'] ?? 'N/A'], ['Species', data['species'] ?? 'N/A'],
                          ['Gender', data['gender'] ?? 'Unknown'], ['Age', data['ageYears'] != null ? '${data['ageYears']} years' : 'Unknown'],
                          ['Weight', data['weightKg'] != null ? '${data['weightKg']} kg' : 'Unknown'],
                          ['Conservation', data['conservationStatus'] ?? 'Unknown']].map((r) =>
                        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
                          SizedBox(width: 100, child: Text(r[0], style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary))),
                          Expanded(child: Text(r[1], style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        ]))),
                    ]),
                  ),
                ])),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.trackingHistoryStream(widget.animalId),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    final spots = docs.reversed.where((d) => (d.data() as Map)['bodyTemperature'] != null)
                        .take(20).toList().asMap().entries.map((e) {
                      final temp = ((e.value.data() as Map)['bodyTemperature'] as num).toDouble();
                      return FlSpot(e.key.toDouble(), temp);
                    }).toList();
                    if (spots.isEmpty) return Center(child: Text('No data yet', style: GoogleFonts.dmSans(color: AppColors.textLight)));
                    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Body Temperature', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Last ${spots.length} readings', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 20),
                      Expanded(child: LineChart(LineChartData(
                        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: AppColors.primary, barWidth: 2.5,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)))],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}°',
                                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textLight))))),
                        gridData: FlGridData(getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textLight.withOpacity(0.15))),
                        borderData: FlBorderData(show: false),
                      ))),
                    ]));
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.trackingHistoryStream(widget.animalId),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return Center(child: Text('No history yet', style: GoogleFonts.dmSans(color: AppColors.textLight)));
                    return ListView.separated(
                      padding: const EdgeInsets.all(12), itemCount: docs.length,
                      separatorBuilder: (_, __) => Divider(color: AppColors.textLight.withOpacity(0.15), height: 1),
                      itemBuilder: (_, i) {
                        final d = docs[i].data() as Map<String, dynamic>;
                        final ts = (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                        final loc = d['location'] as Map?;
                        return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Container(width: 38, height: 38,
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                              child: Icon(d['hasMovement'] == true ? Icons.directions_walk : Icons.bedtime_rounded,
                                  size: 18, color: AppColors.primary)),
                          title: Text(DateFormat('dd MMM HH:mm').format(ts),
                              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(loc != null
                              ? '${(loc['latitude'] as num).toStringAsFixed(3)}, ${(loc['longitude'] as num).toStringAsFixed(3)}'
                                '${d['bodyTemperature'] != null ? '  •  ${d['bodyTemperature']}°C' : ''}'
                              : 'No location', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)));
                      },
                    );
                  },
                ),
              ])),
            ]),
          ),
        );
      },
    );
  }

  void _resolveDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Resolve Distress', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Resolution notes'), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { FirebaseService.resolveDistress(widget.animalId, ctrl.text); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Resolve'),
        ),
      ],
    ));
  }
}
