// lib/utils/mock_data.dart
import 'package:latlong2/latlong.dart';

class MockAnimal {
  final String id, name, species, scientificName;
  final double lat, lng, lastTemp;
  final int lastHR;
  final bool isDistress, isFavorite;
  final String? imageUrl, conservationStatus;
  final String fenceId; // which fence this animal belongs to

  const MockAnimal({
    required this.id, required this.name, required this.species,
    required this.scientificName, required this.lat, required this.lng,
    required this.lastTemp, required this.lastHR,
    this.isDistress = false, this.isFavorite = false,
    this.imageUrl, this.conservationStatus, this.fenceId = '',
  });
}

class MockFence {
  final String id, name, description;
  final List<LatLng> polygon;
  final bool isBreached;
  final String? breachedByAnimalId, breachedByAnimalName;
  final String? breachLocationDescription;
  final double? breachLat, breachLng;

  const MockFence({
    required this.id, required this.name, required this.description,
    required this.polygon, this.isBreached = false,
    this.breachedByAnimalId, this.breachedByAnimalName,
    this.breachLocationDescription, this.breachLat, this.breachLng,
  });
}

class MockAlert {
  final String id, animalName, type, severity, message, status;
  const MockAlert({required this.id, required this.animalName, required this.type,
      required this.severity, required this.message, required this.status});
}

class MockNews {
  final String id, title, summary, category;
  final String? imageUrl;
  const MockNews({required this.id, required this.title, required this.summary,
      required this.category, this.imageUrl});
}

class MockRescueCase {
  final String id, animalType, urgencyLevel, aiSummary, locationDescription, status;
  final int severityScore;
  final String? photoUrl, breed;
  const MockRescueCase({required this.id, required this.animalType,
      required this.urgencyLevel, required this.aiSummary,
      required this.locationDescription, required this.status,
      required this.severityScore, this.photoUrl, this.breed});
}

// ── FENCES ────────────────────────────────────────────────────────────────────

final mockFences = [
  MockFence(
    id: 'f1', name: 'Kanha Reserve Zone A',
    description: 'Primary tiger habitat — eastern sector',
    polygon: const [
      LatLng(22.35, 80.60), LatLng(22.35, 80.80),
      LatLng(22.20, 80.80), LatLng(22.20, 80.60),
    ],
    isBreached: false,
  ),
  MockFence(
    id: 'f2', name: 'Corbett Elephant Corridor',
    description: 'Protected elephant migration route',
    polygon: const [
      LatLng(29.60, 78.70), LatLng(29.60, 79.00),
      LatLng(29.35, 79.00), LatLng(29.35, 78.70),
    ],
    isBreached: true,
    breachedByAnimalId: '2',
    breachedByAnimalName: 'Bruno',
    breachLocationDescription: 'Near Highway NH-34, 2.3 km outside boundary — approaching farmland',
    breachLat: 29.28,
    breachLng: 79.08,
  ),
  MockFence(
    id: 'f3', name: 'Hemis Snow Leopard Zone',
    description: 'High altitude snow leopard territory',
    polygon: const [
      LatLng(34.10, 77.30), LatLng(34.10, 77.70),
      LatLng(33.85, 77.70), LatLng(33.85, 77.30),
    ],
    isBreached: false,
  ),
];

// ── ANIMALS ───────────────────────────────────────────────────────────────────

final mockAnimals = [
  const MockAnimal(
    id: '1', name: 'Amber', species: 'Bengal Tiger',
    scientificName: 'Panthera tigris tigris',
    lat: 22.28, lng: 80.72, lastTemp: 38.5, lastHR: 72,
    conservationStatus: 'Endangered', fenceId: 'f1',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Tiger_in_Ranthambhore.jpg/320px-Tiger_in_Ranthambhore.jpg',
  ),
  const MockAnimal(
    id: '2', name: 'Bruno', species: 'Indian Elephant',
    scientificName: 'Elephas maximus indicus',
    lat: 29.28, lng: 79.08, lastTemp: 36.2, lastHR: 40,
    isDistress: true, conservationStatus: 'Endangered', fenceId: 'f2',
  ),
  const MockAnimal(
    id: '3', name: 'Luna', species: 'Snow Leopard',
    scientificName: 'Panthera uncia',
    lat: 33.97, lng: 77.50, lastTemp: 37.8, lastHR: 60,
    isFavorite: true, conservationStatus: 'Vulnerable', fenceId: 'f3',
  ),
  const MockAnimal(
    id: '4', name: 'Rex', species: 'Red Fox',
    scientificName: 'Vulpes vulpes',
    lat: 28.6, lng: 77.2, lastTemp: 39.1, lastHR: 110,
    conservationStatus: 'Least Concern',
  ),
];

// ── ALERTS ────────────────────────────────────────────────────────────────────

final mockAlerts = [
  const MockAlert(
    id: 'a1', animalName: 'Bruno', type: 'fence_breach',
    severity: 'critical',
    message: '🚧 Bruno has breached the Corbett Elephant Corridor fence! Currently near Highway NH-34, 2.3 km outside the boundary.',
    status: 'active',
  ),
  const MockAlert(
    id: 'a2', animalName: 'Bruno', type: 'distress_no_movement',
    severity: 'critical',
    message: '🚨 Bruno has shown no movement for 14 hours!',
    status: 'active',
  ),
  const MockAlert(
    id: 'a3', animalName: 'Amber', type: 'temperature_high',
    severity: 'high',
    message: '⚠️ Amber\'s body temperature is 42.3°C — above normal range.',
    status: 'active',
  ),
  const MockAlert(
    id: 'a4', animalName: 'Rex', type: 'low_battery',
    severity: 'medium',
    message: '🔋 Rex\'s collar battery is at 12%.',
    status: 'acknowledged',
  ),
  const MockAlert(
    id: 'a5', animalName: 'Luna', type: 'rescue_case',
    severity: 'high',
    message: '🩺 Rescue case reported near Sector 4 — Snow Leopard with leg injury.',
    status: 'resolved',
  ),
];

// ── NEWS ──────────────────────────────────────────────────────────────────────

final mockNews = [
  const MockNews(
    id: 'n1', title: 'Bengal Tiger Population Rises to 3,167',
    summary: 'India\'s latest tiger census shows a 6% increase in population, with Madhya Pradesh leading conservation efforts.',
    category: 'conservation',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/Tiger_in_Ranthambhore.jpg/320px-Tiger_in_Ranthambhore.jpg',
  ),
  const MockNews(
    id: 'n2', title: 'Elephant Rescue in Coimbatore Successful',
    summary: 'A young elephant calf was rescued from a drainage canal after 6 hours of effort by forest officials and volunteers.',
    category: 'rescue',
  ),
  const MockNews(
    id: 'n3', title: 'New GPS Collar Technology for Snow Leopards',
    summary: 'Researchers deploy next-gen solar-powered GPS collars to track snow leopard migration across the Himalayas.',
    category: 'research',
  ),
];

// ── RESCUE CASES ──────────────────────────────────────────────────────────────

final mockRescueCases = [
  const MockRescueCase(
    id: 'r1', animalType: 'Dog', breed: 'Labrador Mix',
    urgencyLevel: 'Emergency', severityScore: 8,
    aiSummary: 'Adult Labrador mix with severe leg injury and visible bleeding. Animal appears distressed and unable to walk.',
    locationDescription: 'Near Central Park Gate 3', status: 'pending',
  ),
  const MockRescueCase(
    id: 'r2', animalType: 'Cat', breed: 'Stray',
    urgencyLevel: 'Urgent', severityScore: 5,
    aiSummary: 'Stray cat with minor eye infection and malnutrition. Requires attention but not immediately life-threatening.',
    locationDescription: 'MG Road, beside bus stop', status: 'assigned',
  ),
  const MockRescueCase(
    id: 'r3', animalType: 'Bird', breed: 'Pigeon',
    urgencyLevel: 'Routine', severityScore: 2,
    aiSummary: 'Pigeon with a minor wing injury. Animal appears alert and responsive.',
    locationDescription: 'Sector 12 Park', status: 'resolved',
  ),
];
