// Demo content for the Lisbon trip (same as storybook/src/data.ts). The restaurant's rating, place and menu are real
// (Google Maps and the restaurant's own English menu, in assets/data/brasserie-menu.json).
import 'dart:convert';

import 'package:flutter/services.dart';
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

class MenuItem {
  const MenuItem(this.name, this.price, {this.note, this.photo, this.pickedBy = const []});
  final String name, price;
  final String? note;

  /// File name in assets/photos/menu, without .jpg. Dishes only; drinks have none.
  final String? photo;
  final List<String> pickedBy;
}

class MenuSection {
  const MenuSection(this.title, this.items, {this.note});
  final String title;
  final String? note;
  final List<MenuItem> items;
}

/// The restaurant's whole menu (real, from its English menu). Loaded once.
final Future<List<MenuSection>> brasserieMenu = rootBundle.loadString('assets/data/brasserie-menu.json').then((raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final s in json['sections'] as List)
      MenuSection(
        s['title'] as String,
        note: s['note'] as String?,
        [
          for (final i in s['items'] as List)
            MenuItem(i['name'] as String, i['price'] as String, note: i['note'] as String?, photo: i['photo'] as String?, pickedBy: [for (final id in (i['pickedBy'] as List? ?? const [])) id as String]),
        ],
      ),
  ];
});

class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.eta,
    required this.sticker,
    required this.at,
    required this.day,
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

  /// Day of the month it happens on (see [tripDays]).
  final int day;
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
    at: LatLng(38.754444, -9.140476),   // Av. da Igreja 12B, Alvalade
    day: today,
    rating: '4.2 (173)',
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
  Plan(id: 'croissants', name: 'Sam Croissants', eta: 'In 2 hrs', sticker: 'nata', at: LatLng(38.6975, -9.2032), day: today),
  Plan(id: 'tram', name: 'Tram 28 ride', eta: 'Tomorrow', sticker: 'tram', at: LatLng(38.7114, -9.1296), day: 15),
  Plan(id: 'sail', name: 'Sail on the Tagus', eta: 'Sat · 6 PM', sticker: 'caravel', at: LatLng(38.7700, -9.0935), day: 16),   // Doca dos Olivais
  Plan(id: 'fado', name: 'Fado at Tasca do Chico', eta: 'Sun · 9 PM', sticker: 'guitar', at: LatLng(38.7123, -9.1450), day: 17),
  Plan(id: 'oceanario', name: 'Oceanário', eta: 'Mon · 11 AM', sticker: 'festival-sardine', at: LatLng(38.7635, -9.0937), day: 18),
  Plan(id: 'tiles', name: 'Tile Museum', eta: 'Tue · 10 AM', sticker: 'azulejo', at: LatLng(38.7247, -9.1136), day: 19),
];

/// Places already visited: stickers on the map, the trip's history.
class Visited {
  const Visited(this.sticker, this.at, this.tilt, this.day);
  final String sticker;
  final LatLng at;
  final double tilt;
  final int day;
}

const visited = [
  Visited('azulejo', LatLng(38.7560, -9.1462), -5, 12),      // Igreja de São João de Brito
  Visited('galo', LatLng(38.7600, -9.1500), 6, 12),          // Jardim do Campo Grande
  Visited('caravel', LatLng(38.7612, -9.1608), -4, 12),      // Estádio José Alvalade
  Visited('guitar', LatLng(38.7465, -9.1390), -10, 12),      // Teatro Maria Matos
  Visited('nata', LatLng(38.7395, -9.1458), -8, 13),         // Pastelaria Versailles
  Visited('sardine-tin', LatLng(38.7340, -9.1350), 4, 13),   // Mercado de Arroios
  Visited('belem', LatLng(38.6916, -9.2160), -6, 13),
  Visited('padrao', LatLng(38.6936, -9.2057), 5, 13),
];

const me = LatLng(38.7478, -9.1475);

/// Where the map opens: Up next and me both in view.
const startCenter = LatLng(38.7591, -9.1405);
const startZoom = 14.1;
const meHeadingDegrees = -40.0;

const tripTitle = 'Schmedeswurtherwesterdeich';
const tripDates = '12 May - 21 May';

/// The trip's days, as days of the month (May 2026), and today in the demo.
const tripYear = 2026, tripMonth = 5;
const tripDays = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21];
const today = 14;
const topFaces = ['person-04', 'person-01'];
const moreFaces = 3;
