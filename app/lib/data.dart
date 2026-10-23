// Demo content for the Lisbon trip (same as storybook/src/data.ts).
import 'package:latlong2/latlong.dart';

import 'components/basics.dart';

class Person {
  const Person(this.id, this.name, this.sticker, this.status, {this.going = true});
  final String id, name, sticker, status;
  final bool going;
}

const people = [
  Person('ari', 'You', 'person-04', 'On the way · 12 min'),
  Person('maya', 'Maya', 'person-01', 'Already there'),
  Person('nic', 'Nic', 'person-05', 'On the way · 8 min'),
  Person('leo', 'Leo', 'person-02', 'Leaves in 20 min'),
  Person('ren', 'Ren', 'person-03', 'Not going', going: false),
];
String faceOf(String id) => people.firstWhere((p) => p.id == id).sticker;

class Dish {
  const Dish(this.name, this.price, this.sticker, this.pickedBy);
  final String name, price, sticker;
  final List<String> pickedBy;
}

/// A sticker in the hand-placed fan on the Up next card (height in px, tilt in degrees).
class FanSticker {
  const FanSticker(this.sticker, this.height, this.tilt);
  final String sticker;
  final double height, tilt;
}

class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.eta,
    required this.sticker,
    required this.at,
    this.rating = '',
    this.cuisine = '',
    this.fan = const [],
    this.chips = const [],
    this.photos = const [],
    this.about = '',
    this.tips = const [],
    this.menu = const [],
  });
  final String id, name, eta, sticker, rating, cuisine, about;
  final LatLng at;
  final List<FanSticker> fan;
  final List<InfoChip> chips;
  final List<String> photos, tips;
  final List<Dish> menu;
}

/// Planned, in order. The first one is Up next; all of them show as pins so they stand apart from past places.
const plans = [
  Plan(
    id: 'brasserie',
    name: "La Brasserie de L'Entrecôte - Alvalade",
    eta: 'In 64 mins',
    sticker: 'wings',
    at: LatLng(38.7131, -9.1578),
    rating: '4.4 (1,431)',
    cuisine: 'French',
    fan: [FanSticker('pho', 44.79, 0), FanSticker('sushi', 78.53, -7.99), FanSticker('wings', 95, 0), FanSticker('ice-cream', 65.47, 8.59)],
    chips: [InfoChip('+3', sticker: 'person-05', tilt: -6.22), InfoChip('€€', grow: true), InfoChip('5 PM • Today')],
    photos: ['brasserie-1', 'brasserie-2', 'brasserie-3'],
    about:
        'La Brasserie de L’Entrecôte is a unique restaurant in many ways. For 30 years we have specialized in preparing a very special dish: the tender and sliced Entrecote, served with delicious and crispy French fries, complemented with delicious starters, countless deserts and an excellent wine list.',
    tips: [
      'Visitors highlight the exceptional secret sauce served over the tender entrecote',
      'Reviewers say the crisp fries are unlimited so you can ask for more refills',
      'Some say dining room can be quite noisy during busy hours',
    ],
    menu: [
      Dish('Spicy chicken wings', '€12', 'wings', ['ari', 'nic']),
      Dish('Sushi plate for two', '€24', 'sushi', ['maya', 'leo']),
      Dish('Beef pho', '€14', 'pho', ['leo']),
      Dish('Lime sorbet', '€6', 'ice-cream', ['ari', 'maya', 'nic']),
    ],
  ),
  Plan(id: 'croissants', name: 'Sam Croissants', eta: 'In 2 hrs', sticker: 'nata', at: LatLng(38.6975, -9.2032)),
  Plan(id: 'tram', name: 'Tram 28 ride', eta: 'Tomorrow', sticker: 'tram', at: LatLng(38.7114, -9.1296)),
];

/// Places already visited: stickers on the map, the trip's history.
class Visited {
  const Visited(this.sticker, this.at, this.tilt);
  final String sticker;
  final LatLng at;
  final double tilt;
}

const visited = [
  Visited('galo', LatLng(38.7196, -9.1712), 6),
  Visited('belem', LatLng(38.7262, -9.1478), -6),
  Visited('nata', LatLng(38.7142, -9.1745), -8),
  Visited('caravel', LatLng(38.7084, -9.1586), -4),
  Visited('azulejo', LatLng(38.7046, -9.1468), -5),
  Visited('guitar', LatLng(38.7102, -9.1262), -10),
  Visited('sardine-tin', LatLng(38.7098, -9.1386), 4),
  Visited('padrao', LatLng(38.6936, -9.2057), 5),
];

const me = LatLng(38.7108, -9.1668);

/// Where the map opens: Up next and me both in view.
const startCenter = LatLng(38.7160, -9.1590);
const startZoom = 14.1;
const meHeadingDegrees = -40.0;

const tripTitle = 'Schmedeswurtherwesterdeich';
const tripDates = '12 May - 21 May';
const topFaces = ['person-04', 'person-01'];
const moreFaces = 3;
