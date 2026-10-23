// Demo content for the Lisbon trip (same as storybook/src/data.ts). The restaurant's rating, place and menu are real
// (Google Maps and the restaurant's own English menu, in assets/data/brasserie-menu.json).
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'components/basics.dart';

class Person {
  const Person(this.id, this.name, this.sticker, {this.going = true, this.route = const [], this.leaves = 0, this.arrives = 0});
  final String id, name, sticker;
  final bool going;

  /// Their way to the Up next place, the last point being the place. Empty for me: I'm the blue dot, and my times
  /// come from how far I am (see [timesOf]).
  final List<LatLng> route;

  /// When they set off and when they get there, in minutes after midnight on the trip's today.
  final int leaves, arrives;
}

/// The group, on their way to dinner (17:00). In the real app this comes from their shared locations; here
/// they walk their routes on the demo clock: Maya is there, Nic is on his way, Leo leaves at 16:16.
const people = [
  Person('ari', 'You', 'person-04'),
  Person('maya', 'Maya', 'person-01', leaves: 15 * 60 + 28, arrives: 15 * 60 + 46, route: [
    LatLng(38.7480, -9.1330), LatLng(38.7500, -9.1360), LatLng(38.7530, -9.1385), LatLng(38.754444, -9.140476),
  ]),
  Person('nic', 'Nic', 'person-05', leaves: 15 * 60 + 48, arrives: 16 * 60 + 4, route: [
    LatLng(38.7395, -9.1430), LatLng(38.7440, -9.1440), LatLng(38.7490, -9.1425), LatLng(38.7525, -9.1412), LatLng(38.754444, -9.140476),
  ]),
  Person('leo', 'Leo', 'person-02', leaves: 16 * 60 + 16, arrives: 16 * 60 + 36, route: [
    LatLng(38.7570, -9.1590), LatLng(38.7560, -9.1520), LatLng(38.7552, -9.1460), LatLng(38.754444, -9.140476),
  ]),
  Person('ren', 'Ren', 'person-03', going: false),
];
String faceOf(String id) => people.firstWhere((p) => p.id == id).sticker;

/// Me, in the people list and in who picked what.
const myId = 'ari';

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

/// The first price on a menu line, in euros ("1 scoop €3.40 · 2 scoops €5.10" counts as €3.40).
double? eurosIn(String price) {
  final m = RegExp(r'€\s?(\d+(?:[.,]\d+)?)').firstMatch(price);
  return m == null ? null : double.parse(m.group(1)!.replaceAll(',', '.'));
}

String euros(double v) => '€${v.toStringAsFixed(2)}';

class MenuSection {
  const MenuSection(this.title, this.items, {this.note, this.course = ''});
  final String title;
  final String? note;

  /// "starters", "mains", "desserts" or "drinks", for the menu's filter.
  final String course;
  final List<MenuItem> items;
}

/// The menu once [brasserieMenu] has loaded, so a page can show it on its first frame instead of an empty one.
List<MenuSection>? loadedMenu;

/// The restaurant's whole menu (real, from its English menu). Loaded once.
final Future<List<MenuSection>> brasserieMenu = rootBundle.loadString('assets/data/brasserie-menu.json').then((raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return loadedMenu = [
    for (final s in json['sections'] as List)
      MenuSection(
        s['title'] as String,
        note: s['note'] as String?,
        course: s['course'] as String? ?? '',
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
    required this.sticker,
    required this.at,
    required this.day,
    required this.hour,
    this.minute = 0,
    this.rating = '',
    this.cuisine = '',
    this.fan = const [],
    this.chips = const [],
    this.photos = const [],
    this.about = '',
    this.tips = const [],
    this.menu = const [],
    this.services = const [],
    this.details = const [],
  });
  final String id, name, sticker, rating, cuisine, about;
  final LatLng at;

  /// Day of the month it happens on (see [tripDays]), and the time it starts.
  final int day, hour, minute;

  DateTime get start => DateTime(tripYear, tripMonth, day, hour, minute);

  /// How soon, from now: "In 64 mins", "In 2 hrs", "Tomorrow", "In 3 days".
  String get eta => timeUntil(start, tripNow());

  /// "5 PM • Today", for the card's chips.
  String get whenShort => '${clockTime(start)} • ${dayName(start, tripNow())}';

  /// "Today, 5 PM", for running text.
  String get whenLong => '${dayName(start, tripNow())}, ${clockTime(start)}';

  /// "5 PM" if it's today, else "Tomorrow, 10 AM": next to "Up next".
  String get startsAt => dayName(start, tripNow()) == 'Today' ? clockTime(start) : whenLong;
  final List<FanSticker> fan;
  final List<InfoChip> chips;
  final List<String> photos, tips;
  final List<Dish> menu;

  /// Service options, as on the place's Google Maps card ("Dine-in", "Takeaway", …).
  final List<String> services;

  /// The rest of that card: address, hours, price, where to book or order, website, phone.
  final List<PlaceDetail> details;
}

enum PlaceDetailKind { address, hours, price, booking, order, website, phone }

/// One line of a place's facts. [status] leads the line in colour ("Open"); [sub] is the smaller line under it.
class PlaceDetail {
  const PlaceDetail(this.kind, this.text, {this.status, this.sub});
  final PlaceDetailKind kind;
  final String text;
  final String? status, sub;
}

/// Planned, in order. The first one is Up next; all of them show as pins so they stand apart from past places.
const plans = [
  Plan(
    id: 'brasserie',
    name: "La Brasserie de L'Entrecôte - Alvalade",
    sticker: 'wings',
    at: LatLng(38.754444, -9.140476),   // Av. da Igreja 12B, Alvalade
    day: today,
    hour: 17,
    rating: '4.2 (173)',
    cuisine: 'French',
    fan: [FanSticker('pho', 44.79, 0), FanSticker('sushi', 78.53, -7.99), FanSticker('wings', 95, 0), FanSticker('ice-cream', 65.47, 8.59)],
    // Equal widths; the first one turns into who's already there once people arrive. The time sits by "Up next".
    chips: [InfoChip('+3', sticker: 'person-05', tilt: -6.22, grow: true), InfoChip('€€', grow: true)],
    photos: ['brasserie-2', 'brasserie-3', 'brasserie-1', 'brasserie-4', 'brasserie-5'],   // 4 and 5 are from the restaurant's own menu
    // From the place's Google Maps card
    services: ['Dine-in', 'Takeaway', 'Delivery'],
    details: [
      PlaceDetail(PlaceDetailKind.address, 'Av. da Igreja 12B, 1700-238 Lisboa'),
      PlaceDetail(PlaceDetailKind.hours, 'Closes 11 PM', status: 'Open', sub: 'Opens 12 PM tomorrow'),
      PlaceDetail(PlaceDetailKind.price, '€20–40 per person', sub: 'Reported by 57 people'),
      PlaceDetail(PlaceDetailKind.booking, 'Find a table', sub: 'thefork.pt'),
      PlaceDetail(PlaceDetailKind.order, 'Place an order', sub: 'ubereats.com'),
      PlaceDetail(PlaceDetailKind.website, 'brasserieentrecote.pt'),
      PlaceDetail(PlaceDetailKind.phone, '+351 21 090 0179'),
    ],
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
  Plan(id: 'croissants', name: 'Sam Croissants', sticker: 'nata', at: LatLng(38.6975, -9.2032), day: today, hour: 18),
  Plan(id: 'tram', name: 'Tram 28 ride', sticker: 'tram', at: LatLng(38.7114, -9.1296), day: 15, hour: 10),
  Plan(id: 'sail', name: 'Sail on the Tagus', sticker: 'caravel', at: LatLng(38.7700, -9.0935), day: 16, hour: 18),   // Doca dos Olivais
  Plan(id: 'fado', name: 'Fado at Tasca do Chico', sticker: 'guitar', at: LatLng(38.7123, -9.1450), day: 17, hour: 21),
  Plan(id: 'oceanario', name: 'Oceanário', sticker: 'festival-sardine', at: LatLng(38.7635, -9.0937), day: 18, hour: 11),
  Plan(id: 'tiles', name: 'Tile Museum', sticker: 'azulejo', at: LatLng(38.7247, -9.1136), day: 19, hour: 10),
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

// ---------- Time: the demo's "now", running on from when the app opened

/// Where the demo starts: Thursday 14 May, 15:56, an hour before dinner.
final tripNowAtLaunch = DateTime(tripYear, tripMonth, today, 15, 56);
final _launch = DateTime.now();

/// Now, in the trip: the demo's start plus however long the app has been open.
DateTime tripNow() => tripNowAtLaunch.add(DateTime.now().difference(_launch));

// ---------- Live: where everyone is (simulated on the demo clock; in the real app, their shared locations)

/// A walk: about 4.8 km/h, along streets about a third longer than a straight line; people aim to be 5 min early.
const walkingMetresPerMinute = 80.0, streetDetour = 1.3, arriveEarlyMinutes = 5;

/// Locations are shared only from this long before the event.
const shareBefore = Duration(minutes: 90);

double _minuteOf(DateTime t) => t.hour * 60 + t.minute + t.second / 60;

/// When [p] sets off and arrives. Mine come from how far I am from the place: start, minus being early, minus the walk.
(double leaves, double arrives) timesOf(Person p) {
  if (p.route.isNotEmpty || p.id != myId) return (p.leaves.toDouble(), p.arrives.toDouble());
  final upNext = plans.first;
  final walk = const Distance().as(LengthUnit.Meter, me, upNext.at) * streetDetour / walkingMetresPerMinute;
  final arrives = _minuteOf(upNext.start) - arriveEarlyMinutes;
  return (arrives - walk, arrives);
}

/// Whether [p] has got to the Up next place.
bool isHere(Person p, DateTime now) => p.going && _minuteOf(now) >= timesOf(p).$2;

/// "Already there", "On the way · 8 min", "Leaves in 20 min", or "Not going".
String statusOf(Person p, DateTime now) {
  if (!p.going) return 'Not going';
  final (leaves, arrives) = timesOf(p);
  final m = _minuteOf(now);
  if (m >= arrives) return 'Already there';
  if (m >= leaves) return 'On the way · ${(arrives - m).ceil()} min';
  return 'Leaves in ${(leaves - m).ceil()} min';
}

/// Where [p] is now along their route, at an even pace between leaving and arriving. Null for me and for anyone
/// not coming or not sharing yet.
LatLng? whereIs(Person p, DateTime now) {
  if (!p.going || p.route.isEmpty || now.isBefore(plans.first.start.subtract(shareBefore))) return null;
  final f = ((_minuteOf(now) - p.leaves) / (p.arrives - p.leaves)).clamp(0.0, 1.0);
  const d = Distance();
  final legs = [for (var i = 1; i < p.route.length; i++) d.as(LengthUnit.Meter, p.route[i - 1], p.route[i])];
  var left = f * legs.fold(0.0, (a, b) => a + b);
  for (var i = 0; i < legs.length; i++) {
    if (left <= legs[i]) {
      final t = legs[i] == 0 ? 0.0 : left / legs[i], a = p.route[i], b = p.route[i + 1];
      return LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);
    }
    left -= legs[i];
  }
  return p.route.last;
}

int _daysBetween(DateTime from, DateTime to) => DateTime(to.year, to.month, to.day).difference(DateTime(from.year, from.month, from.day)).inDays;

/// How soon, the way a person would say it: minutes for the next hour and a half, then hours the same day,
/// then "Tomorrow", then days.
String timeUntil(DateTime start, DateTime now) {
  final mins = start.difference(now).inMinutes;
  if (mins <= 0) return 'Now';
  final days = _daysBetween(now, start);
  if (days == 0) {
    if (mins < 90) return 'In $mins ${mins == 1 ? 'min' : 'mins'}';
    final hrs = (mins / 60).round();
    return 'In $hrs ${hrs == 1 ? 'hr' : 'hrs'}';
  }
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}

/// "5 PM", "10:30 AM".
String clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h${t.minute == 0 ? '' : ':${t.minute.toString().padLeft(2, '0')}'} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Mon", "Tue", …
String weekdayShort(DateTime t) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][t.weekday - 1];

/// "Today", "Tomorrow", or "Sat 16".
String dayName(DateTime t, DateTime now) => switch (_daysBetween(now, t)) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => '${weekdayShort(t)} ${t.day}',
    };
const topFaces = ['person-04', 'person-01'];
const moreFaces = 3;
