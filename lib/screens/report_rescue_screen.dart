// lib/screens/report_rescue_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';

class ReportRescueScreen extends StatefulWidget {
  const ReportRescueScreen({super.key});
  @override
  State<ReportRescueScreen> createState() => _ReportRescueScreenState();
}

class _ReportRescueScreenState extends State<ReportRescueScreen> {
  File? _imageFile;
  AnimalAssessment? _assessment;
  bool _isAnalyzing = false, _isSubmitting = false;
  String? _error;
  Position? _position;
  final _locationCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() { super.initState(); _getLocation(); }

  Future<void> _getLocation() async {
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;
    setState(() { _imageFile = File(picked.path); _assessment = null; _error = null; });
    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    setState(() { _isAnalyzing = true; _error = null; });
    try {
      final result = await GeminiService.analyzeAnimalPhoto(_imageFile!);
      setState(() => _assessment = result);
    } catch (e) {
      setState(() => _error = 'AI analysis failed. You can still submit the report.');
    } finally { setState(() => _isAnalyzing = false); }
  }

  Future<void> _submit() async {
    if (_imageFile == null || _assessment == null) return;
    setState(() { _isSubmitting = true; _error = null; });
    try {
      final user = FirebaseService.currentUser;
      final caseId = await FirebaseService.createRescueCase(
        imageFile: _imageFile!, assessment: _assessment!,
        location: {'latitude': _position?.latitude ?? 0, 'longitude': _position?.longitude ?? 0},
        locationDescription: _locationCtrl.text.trim().isEmpty
            ? '${_position?.latitude.toStringAsFixed(4) ?? 'Unknown'}, ${_position?.longitude.toStringAsFixed(4) ?? ''}'
            : _locationCtrl.text.trim(),
        reportedBy: user?.uid ?? 'anonymous',
        reporterName: user?.displayName ?? user?.email ?? 'Anonymous',
      );
      if (!mounted) return;
      _showSuccess(caseId);
    } catch (e) {
      setState(() => _error = 'Failed to submit: $e');
    } finally { setState(() => _isSubmitting = false); }
  }

  void _showSuccess(String caseId) => showDialog(context: context, barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 36)),
        const SizedBox(height: 16),
        Text('Report Submitted!', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Nearby zoologist experts have been notified. Case ID: $caseId',
            textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
      ]),
      actions: [SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Done')))],
    ));

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _assessment?.urgencyColor ?? AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Report Animal', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary)),
          onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SectionHeader(number: '1', title: 'Take or Upload Photo'),
          const SizedBox(height: 12),
          _imageFile == null ? _photoPrompt() : _photoPreview(),
          const SizedBox(height: 24),
          if (_imageFile != null) ...[
            _SectionHeader(number: '2', title: 'AI Assessment'),
            const SizedBox(height: 12),
            if (_isAnalyzing) _analyzingCard()
            else if (_assessment != null) _assessmentCard()
            else if (_error != null) _errorCard(),
            const SizedBox(height: 24),
          ],
          _SectionHeader(number: '3', title: 'Location'),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.textLight.withOpacity(0.2))),
            child: Column(children: [
              if (_position != null) ...[
                Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_on, color: AppColors.success, size: 18)),
                  const SizedBox(width: 10),
                  Text('GPS: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 12),
              ],
              TextField(controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Describe location (optional)',
                      hintText: 'e.g. Near Central Park, Gate 3',
                      prefixIcon: Icon(Icons.edit_location_outlined, color: AppColors.textLight)), maxLines: 2),
            ])),
          const SizedBox(height: 24),
          if (_error != null && !_isAnalyzing) Container(margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
          SizedBox(height: 54, child: ElevatedButton(
            onPressed: (_isSubmitting || _isAnalyzing || _imageFile == null || _assessment == null) ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: urgencyColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.send_rounded), const SizedBox(width: 8),
                    Text(_assessment?.urgencyLevel == 'Code Red' ? '🚨 Submit Code Red Alert' : 'Submit Rescue Report',
                        style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
          )),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _photoPrompt() => Row(children: [
    Expanded(child: GestureDetector(onTap: () => _pickImage(ImageSource.camera),
      child: Container(height: 130, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.camera_alt_rounded, size: 36, color: AppColors.primary),
          const SizedBox(height: 8),
          Text('Take Photo', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppColors.primary)),
        ])))),
    const SizedBox(width: 12),
    Expanded(child: GestureDetector(onTap: () => _pickImage(ImageSource.gallery),
      child: Container(height: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textLight.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.photo_library_rounded, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text('Upload Photo', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ])))),
  ]);

  Widget _photoPreview() => Stack(children: [
    ClipRRect(borderRadius: BorderRadius.circular(16),
        child: Image.file(_imageFile!, width: double.infinity, height: 220, fit: BoxFit.cover)),
    Positioned(top: 10, right: 10, child: GestureDetector(
        onTap: () => setState(() { _imageFile = null; _assessment = null; }),
        child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
            child: const Icon(Icons.close, color: Colors.white, size: 18)))),
  ]);

  Widget _analyzingCard() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
    child: Column(children: [
      CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3), const SizedBox(height: 16),
      Text('AI Analyzing Photo...', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text('Gemini Vision is identifying the animal and assessing injuries',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
    ]));

  Widget _errorCard() => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
    child: Row(children: [
      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
      const SizedBox(width: 10),
      Expanded(child: Text(_error ?? '', style: TextStyle(color: Colors.orange.shade800, fontSize: 13))),
      TextButton(onPressed: _analyzeImage, child: const Text('Retry')),
    ]));

  Widget _assessmentCard() {
    final a = _assessment!;
    final c = a.urgencyColor;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Assessment', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              Text('Powered by Gemini Vision', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
                child: Text(a.urgencyLevel, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
          ])),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.pets, size: 20, color: AppColors.primary), const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.animalType, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  if (a.breed != null) Text(a.breed!, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                ])),
              ]))),
            const SizedBox(width: 10),
            Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12), border: Border.all(color: c.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Severity', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${a.severityScore}', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: c)),
                  Text('/10', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textLight)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: a.severityScore / 10, backgroundColor: c.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(c), minHeight: 4, borderRadius: BorderRadius.circular(4)),
              ]))),
          ]),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary), const SizedBox(width: 8),
              Expanded(child: Text(a.aiSummary, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
            ])),
          if (a.injuries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Injuries', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: a.injuries.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.danger.withOpacity(0.2))),
              child: Text(item, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500)),
            )).toList()),
          ],
          if (a.requiresImmediateVet) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [
                Icon(Icons.local_hospital, color: Colors.red.shade600, size: 18), const SizedBox(width: 8),
                Text('Requires immediate veterinary attention',
                    style: GoogleFonts.dmSans(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
              ])),
          ],
        ])),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String number, title;
  const _SectionHeader({required this.number, required this.title});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 28, height: 28, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Center(child: Text(number, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)))),
    const SizedBox(width: 10),
    Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
  ]);
}
