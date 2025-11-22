import 'package:latlong2/latlong.dart';
import '../models/spot_models.dart';

class UserProfile {
  final String id;
  final String name;
  final List<BeggarAttribute> myAttributes; 

  UserProfile({required this.id, required this.name, required this.myAttributes});
}

final currentUser = UserProfile(
  id: 'me_8492', 
  name: 'StreetSurvivor', 
  myAttributes: [BeggarAttribute.music, BeggarAttribute.dog] 
);

// --- DONNÉES DE SPOTS (Masivement augmentées) ---
final List<Spot> mockSpots = [
  // --- CENTRE VILLE ---
  Spot(id: '1', name: 'Grand-Place', description: 'Le cœur touristique.', position: const LatLng(50.8467, 4.3524), category: 'Tourisme', currentActiveUsers: 3, createdAt: DateTime.now(), createdBy: 'OldTimer', reviews: [
    Review(id: 'r1', authorName: 'MimeMarceau', ratingRevenue: 5.0, ratingSecurity: 2.0, ratingTraffic: 5.0, attribute: BeggarAttribute.circus, comment: 'Jackpot.', createdAt: DateTime.now()),
  ]),
  Spot(id: '1b', name: 'Manneken Pis', description: 'Foule compacte.', position: const LatLng(50.8450, 4.3500), category: 'Tourisme', currentActiveUsers: 5, createdAt: DateTime.now(), createdBy: 'TouristTrap', reviews: [
    Review(id: 'r1b', authorName: 'PickP', ratingRevenue: 4.0, ratingSecurity: 3.0, ratingTraffic: 5.0, attribute: BeggarAttribute.none, comment: 'Ça circule vite.', createdAt: DateTime.now()),
  ]),
  Spot(id: '1c', name: 'Mont des Arts', description: 'Belle vue, calme.', position: const LatLng(50.8441, 4.3560), category: 'Tourisme', currentActiveUsers: 1, createdAt: DateTime.now(), createdBy: 'SunsetLover', reviews: [
    Review(id: 'r1c', authorName: 'GuitarHero', ratingRevenue: 3.5, ratingSecurity: 4.0, ratingTraffic: 3.0, attribute: BeggarAttribute.music, comment: 'Bonne acoustique.', createdAt: DateTime.now()),
  ]),
  Spot(id: '1d', name: 'Galeries Royales', description: 'Luxe et touristes.', position: const LatLng(50.8475, 4.3540), category: 'Tourisme', currentActiveUsers: 0, createdAt: DateTime.now(), createdBy: 'ViolinPro', reviews: [
    Review(id: 'r1d', authorName: 'ViolinPro', ratingRevenue: 4.8, ratingSecurity: 1.0, ratingTraffic: 4.0, attribute: BeggarAttribute.music, comment: 'Sécurité privée très pénible.', createdAt: DateTime.now()),
  ]),
  Spot(id: '1e', name: 'Bourse', description: 'Zone piétonne large.', position: const LatLng(50.8485, 4.3495), category: 'Tourisme', currentActiveUsers: 2, createdAt: DateTime.now(), createdBy: 'SkaterBoy', reviews: [
    Review(id: 'r1e', authorName: 'Juggler', ratingRevenue: 3.0, ratingSecurity: 3.0, ratingTraffic: 5.0, attribute: BeggarAttribute.circus, comment: 'Beaucoup de place.', createdAt: DateTime.now()),
  ]),

  // --- BUSINESS ---
  Spot(id: '2', name: 'Sortie Métro Arts-Loi', description: 'Flux rapide matin.', position: const LatLng(50.8450, 4.3700), category: 'Business', currentActiveUsers: 0, createdAt: DateTime.now(), createdBy: 'ViolinMaster', reviews: [
    Review(id: 'r3', authorName: 'Maestro', ratingRevenue: 4.0, ratingSecurity: 4.0, ratingTraffic: 5.0, attribute: BeggarAttribute.music, comment: 'Efficace.', createdAt: DateTime.now()),
  ]),
  Spot(id: '2b', name: 'Schuman (UE)', description: 'Expats.', position: const LatLng(50.8425, 4.3830), category: 'Business', currentActiveUsers: 2, createdAt: DateTime.now(), createdBy: 'EuroBeg', reviews: [
    Review(id: 'r2b', authorName: 'NoLuck', ratingRevenue: 2.5, ratingSecurity: 5.0, ratingTraffic: 3.0, attribute: BeggarAttribute.none, comment: 'Pas de cash.', createdAt: DateTime.now()),
  ]),
  Spot(id: '2c', name: 'WTC Nord', description: 'Tours de bureaux.', position: const LatLng(50.8600, 4.3580), category: 'Business', currentActiveUsers: 6, createdAt: DateTime.now(), createdBy: 'NorthSide', reviews: [
    Review(id: 'r2c', authorName: 'FamilyMan', ratingRevenue: 3.0, ratingSecurity: 2.0, ratingTraffic: 4.0, attribute: BeggarAttribute.family, comment: 'Glauque mais ça donne.', createdAt: DateTime.now()),
  ]),
  Spot(id: '2d', name: 'Place du Luxembourg', description: 'Afterwork jeudi.', position: const LatLng(50.8390, 4.3730), category: 'Business', currentActiveUsers: 1, createdAt: DateTime.now(), createdBy: 'BeerHunter', reviews: [
    Review(id: 'r2d', authorName: 'Party', ratingRevenue: 4.5, ratingSecurity: 4.0, ratingTraffic: 4.0, attribute: BeggarAttribute.music, comment: 'Le jeudi soir c\'est top.', createdAt: DateTime.now()),
  ]),

  // --- SHOPPING ---
  Spot(id: '3', name: 'Rue Neuve', description: 'Foule compacte.', position: const LatLng(50.8520, 4.3560), category: 'Shopping', currentActiveUsers: 4, createdAt: DateTime.now(), createdBy: 'DogLover', reviews: [
    Review(id: 'r4', authorName: 'RexTeam', ratingRevenue: 4.5, ratingSecurity: 1.0, ratingTraffic: 5.0, attribute: BeggarAttribute.dog, comment: 'Le chien aide.', createdAt: DateTime.now()),
  ]),
  Spot(id: '3b', name: 'Avenue Louise', description: 'Luxe.', position: const LatLng(50.8350, 4.3600), category: 'Shopping', currentActiveUsers: 0, createdAt: DateTime.now(), createdBy: 'LuxuryHobo', reviews: [
    Review(id: 'r3b', authorName: 'Classy', ratingRevenue: 5.0, ratingSecurity: 2.0, ratingTraffic: 2.0, attribute: BeggarAttribute.music, comment: 'Gros billets.', createdAt: DateTime.now()),
  ]),
  Spot(id: '3c', name: 'Porte de Namur', description: 'Shopping & Ciné.', position: const LatLng(50.8380, 4.3620), category: 'Shopping', currentActiveUsers: 2, createdAt: DateTime.now(), createdBy: 'PopCorn', reviews: [
    Review(id: 'r3c', authorName: 'Juggler', ratingRevenue: 3.2, ratingSecurity: 3.0, ratingTraffic: 5.0, attribute: BeggarAttribute.circus, comment: 'Pas mal.', createdAt: DateTime.now()),
  ]),
  Spot(id: '3d', name: 'Toison d\'Or', description: 'Galerie chic.', position: const LatLng(50.8365, 4.3590), category: 'Shopping', currentActiveUsers: 1, createdAt: DateTime.now(), createdBy: 'GoldenBoy', reviews: [
    Review(id: 'r3d', authorName: 'Solo', ratingRevenue: 3.8, ratingSecurity: 1.0, ratingTraffic: 3.0, attribute: BeggarAttribute.none, comment: 'Vigiles agressifs.', createdAt: DateTime.now()),
  ]),

  // --- NIGHTLIFE ---
  Spot(id: '4', name: 'Place Saint-Géry', description: 'Bars et terrasses.', position: const LatLng(50.8480, 4.3480), category: 'Nightlife', currentActiveUsers: 1, createdAt: DateTime.now(), createdBy: 'NightOwl', reviews: [
    Review(id: 'r5', authorName: 'PartyBoy', ratingRevenue: 4.2, ratingSecurity: 4.0, ratingTraffic: 4.0, attribute: BeggarAttribute.none, comment: 'Gens bourrés généreux.', createdAt: DateTime.now()),
  ]),
  Spot(id: '4b', name: 'Cimetière d\'Ixelles', description: 'Étudiants.', position: const LatLng(50.8180, 4.3800), category: 'Nightlife', currentActiveUsers: 3, createdAt: DateTime.now(), createdBy: 'StudentDebt', reviews: [
    Review(id: 'r4b1', authorName: 'Doggo', ratingRevenue: 2.5, ratingSecurity: 5.0, ratingTraffic: 3.0, attribute: BeggarAttribute.dog, comment: 'Sympa mais fauchés.', createdAt: DateTime.now()),
  ]),
  Spot(id: '4c', name: 'Flagey', description: 'Bobo et hipster.', position: const LatLng(50.8280, 4.3720), category: 'Nightlife', currentActiveUsers: 1, createdAt: DateTime.now(), createdBy: 'HipHobo', reviews: [
    Review(id: 'r4c', authorName: 'FolkSinger', ratingRevenue: 3.8, ratingSecurity: 4.0, ratingTraffic: 3.0, attribute: BeggarAttribute.music, comment: 'Aiment la musique.', createdAt: DateTime.now()),
  ]),
  Spot(id: '4d', name: 'Parvis de Saint-Gilles', description: 'Marché et bars.', position: const LatLng(50.8300, 4.3450), category: 'Nightlife', currentActiveUsers: 2, createdAt: DateTime.now(), createdBy: 'Gilles', reviews: [
    Review(id: 'r4d', authorName: 'Acro', ratingRevenue: 3.0, ratingSecurity: 4.0, ratingTraffic: 4.0, attribute: BeggarAttribute.circus, comment: 'Bonne ambiance.', createdAt: DateTime.now()),
  ]),

  // --- TRANSPORT ---
  Spot(id: '5', name: 'Gare du Midi', description: 'Zone chaude.', position: const LatLng(50.8360, 4.3360), category: 'Transport', currentActiveUsers: 8, createdAt: DateTime.now(), createdBy: 'RiskTaker', reviews: [
    Review(id: 'r6', authorName: 'Scared', ratingRevenue: 3.0, ratingSecurity: 1.0, ratingTraffic: 5.0, attribute: BeggarAttribute.disability, comment: 'Dangereux.', createdAt: DateTime.now()),
  ]),
  Spot(id: '5b', name: 'Gare Centrale', description: 'Carrefour.', position: const LatLng(50.8455, 4.3570), category: 'Transport', currentActiveUsers: 3, createdAt: DateTime.now(), createdBy: 'CentralPark', reviews: [
    Review(id: 'r5b', authorName: 'Accordion', ratingRevenue: 3.5, ratingSecurity: 3.0, ratingTraffic: 5.0, attribute: BeggarAttribute.music, comment: 'Bon écho.', createdAt: DateTime.now()),
  ]),
  Spot(id: '5c', name: 'Méro De Brouckère', description: 'Sortie principale.', position: const LatLng(50.8500, 4.3530), category: 'Transport', currentActiveUsers: 4, createdAt: DateTime.now(), createdBy: 'Subway', reviews: [
    Review(id: 'r5c', authorName: 'Beggar', ratingRevenue: 2.8, ratingSecurity: 2.0, ratingTraffic: 5.0, attribute: BeggarAttribute.none, comment: 'Passage énorme.', createdAt: DateTime.now()),
  ]),
  Spot(id: '5d', name: 'Porte de Hal', description: 'Parc et métro.', position: const LatLng(50.8330, 4.3430), category: 'Transport', currentActiveUsers: 2, createdAt: DateTime.now(), createdBy: 'GateKeeper', reviews: [
    Review(id: 'r5d', authorName: 'DogLover', ratingRevenue: 2.0, ratingSecurity: 3.0, ratingTraffic: 3.0, attribute: BeggarAttribute.dog, comment: 'Calme.', createdAt: DateTime.now()),
  ]),
];