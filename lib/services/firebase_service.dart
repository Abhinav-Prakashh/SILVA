// lib/services/firebase_service.dart
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:latlong2/latlong.dart';
import 'gemini_service.dart';

class FirebaseService {
  static final _db      = FirebaseFirestore.instance;
  static final _auth    = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  // ── AUTH ────────────────────────────────────────────────────────────────────

  static Future<UserCredential> loginWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> registerWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
    final result = await _auth.signInWithCredential(cred);
    await saveUserProfile(result.user!.uid, {
      'name': result.user!.displayName ?? '',
      'email': result.user!.email ?? '',
      'photoUrl': result.user!.photoURL,
      'role': 'volunteer',
    });
    return result;
  }

  static Future<UserCredential?> signInWithApple() async {
    final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
    final oauthCred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken, accessToken: apple.authorizationCode);
    final result = await _auth.signInWithCredential(oauthCred);
    await saveUserProfile(result.user!.uid, {
      'name': '${apple.givenName ?? ''} ${apple.familyName ?? ''}'.trim(),
      'email': apple.email ?? result.user!.email ?? '',
      'role': 'volunteer',
    });
    return result;
  }

  static Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── USER ────────────────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  static Future<DocumentSnapshot> getUserProfile(String uid) =>
      _db.collection('users').doc(uid).get();

  // ── ANIMALS ─────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> animalsStream() =>
      _db.collection('animals').where('isActive', isEqualTo: true).snapshots();

  static Stream<QuerySnapshot> distressAnimalsStream() =>
      _db.collection('animals').where('distressTriggered', isEqualTo: true).snapshots();

  static Future<void> updateAnimal(String id, Map<String, dynamic> data) =>
      _db.collection('animals').doc(id).update(data);

  static Future<void> toggleFavorite(String animalId, bool isFavorite) =>
      _db.collection('animals').doc(animalId).update({'isFavorite': isFavorite});

  static Future<void> resolveDistress(String animalId, String notes) =>
      _db.collection('animals').doc(animalId).update({
        'distressTriggered': false, 'distressResolved': true,
        'distressNotes': notes, 'distressResolvedAt': FieldValue.serverTimestamp(),
      });

  // ── FENCES ──────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> fencesStream() =>
      _db.collection('fences').snapshots();

  static Future<DocumentReference> createFence(Map<String, dynamic> data) =>
      _db.collection('fences').add({
        ...data,
        'isBreached': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateFence(String id, Map<String, dynamic> data) =>
      _db.collection('fences').doc(id).update(data);

  static Future<void> deleteFence(String id) =>
      _db.collection('fences').doc(id).delete();

  /// Called on every tracking ingest — checks if animal is outside its assigned fence.
  /// Uses ray-casting point-in-polygon algorithm.
  static Future<void> _checkFenceBreach(
      String animalId, String animalName, double lat, double lng) async {
    // Find fences assigned to this animal
    final fenceSnap = await _db.collection('fences')
        .where('assignedAnimals', arrayContains: animalId).get();

    for (final fenceDoc in fenceSnap.docs) {
      final fenceData = fenceDoc.data();
      final rawPoints = fenceData['polygon'] as List<dynamic>;
      final polygon = rawPoints.map((p) =>
          LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble())).toList();

      final inside = _pointInPolygon(lat, lng, polygon);

      if (!inside && fenceData['isBreached'] != true) {
        // Mark fence as breached
        await fenceDoc.reference.update({
          'isBreached': true,
          'breachedByAnimalId': animalId,
          'breachedByAnimalName': animalName,
          'breachLat': lat,
          'breachLng': lng,
          'breachLocationDescription':
              '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} — outside fence boundary',
          'breachTime': FieldValue.serverTimestamp(),
        });
        // Create alert
        await _db.collection('alerts').add({
          'animalId': animalId,
          'animalName': animalName,
          'type': 'fence_breach',
          'severity': 'critical',
          'message': '🚧 $animalName has breached the "${fenceData['name']}" fence! '
              'Currently at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}.',
          'fenceId': fenceDoc.id,
          'fenceName': fenceData['name'],
          'location': {'latitude': lat, 'longitude': lng},
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (inside && fenceData['isBreached'] == true &&
          fenceData['breachedByAnimalId'] == animalId) {
        // Animal returned inside — clear breach
        await fenceDoc.reference.update({
          'isBreached': false,
          'breachedByAnimalId': null,
          'breachedByAnimalName': null,
          'returnedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Ray-casting algorithm to determine if point is inside polygon
  static bool _pointInPolygon(double lat, double lng, List<LatLng> polygon) {
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final j = (i + 1) % polygon.length;
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        intersections++;
      }
    }
    return intersections % 2 == 1;
  }

  // ── TRACKING ────────────────────────────────────────────────────────────────

  static Future<void> ingestTracking(String animalId, Map<String, dynamic> data) async {
    final batch = _db.batch();
    final trackRef = _db.collection('animals').doc(animalId).collection('tracking').doc();
    batch.set(trackRef, {...data, 'timestamp': FieldValue.serverTimestamp()});
    final animalRef = _db.collection('animals').doc(animalId);
    final updateData = {
      'lastKnownLocation': data['location'],
      'lastBodyTemperature': data['bodyTemperature'],
      'lastHeartRate': data['heartRate'],
      'lastSignalTime': FieldValue.serverTimestamp(),
    };
    if (data['hasMovement'] == true) {
      updateData['lastMovementTime'] = FieldValue.serverTimestamp();
    }
    batch.update(animalRef, updateData);
    await batch.commit();
    await _checkDistress(animalId);
    // Check fence
    final loc = data['location'];
    if (loc != null) {
      final snap = await _db.collection('animals').doc(animalId).get();
      final name = (snap.data() as Map?)?['name'] ?? animalId;
      await _checkFenceBreach(animalId, name,
          (loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble());
    }
  }

  static Stream<QuerySnapshot> trackingHistoryStream(String animalId) =>
      _db.collection('animals').doc(animalId).collection('tracking')
          .orderBy('timestamp', descending: true).limit(50).snapshots();

  static Future<void> _checkDistress(String animalId) async {
    final doc = await _db.collection('animals').doc(animalId).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;
    final lastMovement = (data['lastMovementTime'] as Timestamp?)?.toDate();
    if (lastMovement == null || data['distressTriggered'] == true) return;
    final hoursSince = DateTime.now().difference(lastMovement).inHours;
    if (hoursSince >= 12) {
      await _db.collection('animals').doc(animalId).update({
        'distressTriggered': true,
        'distressTriggeredAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('alerts').add({
        'animalId': animalId, 'animalName': data['name'],
        'type': 'distress_no_movement', 'severity': 'critical',
        'message': '🚨 ${data['name']} has shown no movement for $hoursSince hours!',
        'status': 'active', 'location': data['lastKnownLocation'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── RESCUE CASES ────────────────────────────────────────────────────────────

  static Future<String> uploadRescuePhoto(File imageFile, String caseId) async {
    final ref = _storage.ref().child(
        'rescue_cases/$caseId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  static Future<String> createRescueCase({
    required File imageFile,
    required AnimalAssessment assessment,
    required Map<String, double> location,
    required String locationDescription,
    required String reportedBy,
    required String reporterName,
  }) async {
    final caseRef = _db.collection('rescue_cases').doc();
    final photoUrl = await uploadRescuePhoto(imageFile, caseRef.id);
    await caseRef.set({
      'photoUrl': photoUrl,
      'animalType': assessment.animalType,
      'breed': assessment.breed,
      'color': assessment.color,
      'overallCondition': assessment.overallCondition,
      'severityScore': assessment.severityScore,
      'urgencyLevel': assessment.urgencyLevel,
      'injuries': assessment.injuries,
      'visibleSymptoms': assessment.visibleSymptoms,
      'recommendedActions': assessment.recommendedActions,
      'aiSummary': assessment.aiSummary,
      'requiresImmediateVet': assessment.requiresImmediateVet,
      'aiAssessment': assessment.toJson(),
      'location': {'latitude': location['latitude'], 'longitude': location['longitude']},
      'locationDescription': locationDescription,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'status': 'pending',
      'assignedExpert': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (assessment.urgencyLevel == 'Code Red' || assessment.urgencyLevel == 'Emergency') {
      await _db.collection('alerts').add({
        'type': 'rescue_case', 'severity': 'critical',
        'animalName': '${assessment.animalType} (Rescue Case)',
        'message': '🚨 ${assessment.urgencyLevel}: ${assessment.animalType} needs help! ${assessment.aiSummary}',
        'caseId': caseRef.id, 'status': 'active', 'location': location,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return caseRef.id;
  }

  static Stream<QuerySnapshot> rescueCasesStream({String? status}) {
    Query query = _db.collection('rescue_cases').orderBy('createdAt', descending: true);
    if (status != null) query = query.where('status', isEqualTo: status);
    return query.snapshots();
  }

  static Future<void> assignExpert(String caseId, String expertId, String expertName) =>
      _db.collection('rescue_cases').doc(caseId).update({
        'assignedExpert': expertId, 'assignedExpertName': expertName,
        'status': 'assigned', 'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateCaseStatus(String caseId, String status, {String? notes}) =>
      _db.collection('rescue_cases').doc(caseId).update({
        'status': status,
        if (notes != null) 'resolutionNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ── ALERTS ──────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> alertsStream({String status = 'active'}) =>
      _db.collection('alerts').where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true).snapshots();

  static Future<void> acknowledgeAlert(String alertId) =>
      _db.collection('alerts').doc(alertId).update({
        'status': 'acknowledged', 'acknowledgedAt': FieldValue.serverTimestamp()});

  static Future<void> resolveAlert(String alertId, String notes) =>
      _db.collection('alerts').doc(alertId).update({
        'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp(),
        'resolutionNotes': notes});

  // ── NEWS ────────────────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> newsStream() =>
      _db.collection('news').where('isPublished', isEqualTo: true)
          .orderBy('publishedAt', descending: true).limit(20).snapshots();

  // ── SPECIES ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSpeciesList() async {
    final snap = await _db.collection('animals').get();
    final Map<String, Map<String, dynamic>> speciesMap = {};
    for (final doc in snap.docs) {
      final d = doc.data();
      final sp = d['species'] ?? 'Unknown';
      if (!speciesMap.containsKey(sp)) {
        speciesMap[sp] = {'name': sp, 'scientificName': d['scientificName'] ?? '',
            'imageUrl': d['imageUrl'], 'count': 0};
      }
      speciesMap[sp]!['count'] = (speciesMap[sp]!['count'] as int) + 1;
    }
    return speciesMap.values.toList()..sort((a, b) => a['name'].compareTo(b['name']));
  }
}
