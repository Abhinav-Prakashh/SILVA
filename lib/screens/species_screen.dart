// lib/screens/species_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';

class SpeciesScreen extends StatefulWidget {
  const SpeciesScreen({super.key});
  @override
  State<SpeciesScreen> createState() => _SpeciesScreenState();
}

class _SpeciesScreenState extends State<SpeciesScreen> {
  List<Map<String, dynamic>> _all = [], _filtered = [];
  bool _loading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() => _filtered = _all.where((s) =>
          s['name'].toLowerCase().contains(q) ||
          (s['scientificName'] ?? '').toLowerCase().contains(q)).toList());
    });
  }

  Future<void> _load() async {
    final s = await FirebaseService.getSpeciesList();
    setState(() { _all = s; _filtered = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Species', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(controller: _ctrl,
            decoration: InputDecoration(hintText: 'Search species...',
              hintStyle: GoogleFonts.dmSans(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
        ),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.textLight.withOpacity(0.15), height: 1, indent: 70),
            itemBuilder: (_, i) {
              final s = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: CircleAvatar(radius: 24,
                  backgroundImage: s['imageUrl'] != null ? NetworkImage(s['imageUrl']) : null,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: s['imageUrl'] == null ? Icon(Icons.pets, color: AppColors.primary, size: 22) : null),
                title: Text(s['name'], style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                subtitle: Text(s['scientificName'] ?? '', style: GoogleFonts.dmSans(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.textSecondary)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${s['count']}', style: GoogleFonts.dmSans(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
              );
            },
          )),
      ]),
    );
  }
}
