import 'package:latlong2/latlong.dart';
import '../models/spot_models.dart';

final List<Spot> mockSpots = [
  Spot(
    id: '1',
    name: 'Parvis Notre-Dame',
    description: 'Zone touristique haute densité. Les jongleurs cartonnent ici.',
    position: const LatLng(50.8400, 4.3550),
    category: 'Tourisme',
    currentActiveUsers: 2, // Déjà 2 personnes sur place
    createdAt: DateTime.now(),
    createdBy: 'Admin',
    reviews: [
      Review(
        id: 'r1', authorName: 'JongleMan', 
        hourlyRate: 35.50, // Gros score
        attribute: BeggarAttribute.circus, // Grâce au cirque
        comment: 'Les touristes adorent le spectacle. 35€ en une heure facile.',
        createdAt: DateTime.now(),
      ),
      Review(
        id: 'r2', authorName: 'SadGuy', 
        hourlyRate: 5.0, 
        attribute: BeggarAttribute.none, // Sans attribut, ça paie pas
        comment: 'Sans spectacle, personne ne donne.',
        createdAt: DateTime.now(),
      ),
    ],
  ),
  Spot(
    id: '2',
    name: 'Sortie Métro Arts-Loi',
    description: 'Flux de costards pressés. Le violon marche fort.',
    position: const LatLng(50.8450, 4.3700),
    category: 'Business',
    currentActiveUsers: 0, // Libre !
    createdAt: DateTime.now(),
    createdBy: 'ViolinMaster',
    reviews: [
      Review(
        id: 'r3', authorName: 'Maestro', 
        hourlyRate: 22.0, 
        attribute: BeggarAttribute.music,
        comment: 'Acoustique parfaite dans le couloir.',
        createdAt: DateTime.now(),
      ),
    ],
  ),
  Spot(
    id: '3',
    name: 'Rue Neuve (Shopping)',
    description: 'Foule compacte. Le chien est indispensable pour arrêter les gens.',
    position: const LatLng(50.8520, 4.3560),
    category: 'Shopping',
    currentActiveUsers: 4, // Saturé
    createdAt: DateTime.now(),
    createdBy: 'DogLover',
    reviews: [
      Review(
        id: 'r4', authorName: 'RexTeam', 
        hourlyRate: 18.50, 
        attribute: BeggarAttribute.dog,
        comment: 'La sécurité est chiante mais les gens craquent pour le chien.',
        createdAt: DateTime.now(),
      ),
    ],
  ),
];