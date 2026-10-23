// Demo content for the Lisbon trip (same as storybook/src/data.ts). The restaurant's rating, place and menu are real
// (Google Maps and the restaurant's own English menu, in assets/data/brasserie-menu.json).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class Person {
  const Person(this.id, this.name, this.sticker, {this.going = true, this.route = const [], this.leaves = 0, this.arrives = 0, this.joined = 12});
  final String id, name, sticker;
  final bool going;

  /// The day they joined the trip. Costs from before it aren't theirs.
  final int joined;

  /// Their way to the Up next place, the last point being the place. Empty for me: I'm the blue dot, and my times
  /// come from how far I am (see [timesOf]).
  final List<LatLng> route;

  /// When they set off and when they get there, in minutes after midnight on the trip's today.
  final int leaves, arrives;
}

/// The group, on their way to dinner (17:00). In the real app this comes from their shared locations; here
/// they walk their routes on the demo clock: Maya is there, Nic is on his way, Leo leaves at 16:16, and Ren (who
/// joined today) and I leave at 16:30.
const people = [
  Person('ari', 'You', 'person-04', leaves: 16 * 60 + 30, arrives: 16 * 60 + 52, route: [
    me, LatLng(38.7500, -9.1462), LatLng(38.7528, -9.1430), LatLng(38.754444, -9.140476),
  ]),
  Person('maya', 'Maya', 'person-01', leaves: 15 * 60 + 28, arrives: 15 * 60 + 46, route: [
    LatLng(38.7480, -9.1330), LatLng(38.7500, -9.1360), LatLng(38.7530, -9.1385), LatLng(38.754444, -9.140476),
  ]),
  Person('nic', 'Nic', 'person-05', leaves: 15 * 60 + 48, arrives: 16 * 60 + 4, route: [
    LatLng(38.7395, -9.1430), LatLng(38.7440, -9.1440), LatLng(38.7490, -9.1425), LatLng(38.7525, -9.1412), LatLng(38.754444, -9.140476),
  ]),
  Person('leo', 'Leo', 'person-02', leaves: 16 * 60 + 16, arrives: 16 * 60 + 36, route: [
    LatLng(38.7570, -9.1590), LatLng(38.7560, -9.1520), LatLng(38.7552, -9.1460), LatLng(38.754444, -9.140476),
  ]),
  Person('ren', 'Ren', 'person-03', joined: today, leaves: 16 * 60 + 30, arrives: 16 * 60 + 48, route: [   // joined mid-trip, today
    LatLng(38.7590, -9.1330), LatLng(38.7570, -9.1370), LatLng(38.7555, -9.1395), LatLng(38.754444, -9.140476),
  ]),
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

/// A sticker placed by hand in a small composition: its top-left corner, height and tilt (degrees), as in Figma.
class PlacedSticker {
  const PlacedSticker(this.sticker, this.left, this.top, this.height, {this.tilt = 0});
  final String sticker;
  final double left, top, height, tilt;
}

/// The whole group as one little pile, on the footer's money button (Figma "People", 38.6 × 38.2), back to front.
const crewPile = (
  width: 38.58,
  height: 38.21,
  stickers: [
    PlacedSticker('person-02', 1, 7, 24),
    PlacedSticker('person-04', 0, 10, 24),
    PlacedSticker('person-01', 9, 0, 24.59),
    PlacedSticker('person-05', 10.24, 13.1, 24, tilt: -6.22),
    PlacedSticker('person-03', 17, 10, 24),
  ],
);

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
  final menu = loadedMenu = [
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
  myPicks.value ??= {for (final s in menu) for (final i in s.items) if (i.pickedBy.contains(myId)) i.name};
  return menu;
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
    this.priceRange,
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

  /// What it costs a person, as the place's details put it ("€20–40"), for the card.
  final String? priceRange;
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
    priceRange: '€20–40',   // from the price detail below
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
  const Visited(this.name, this.sticker, this.at, this.tilt, this.day);
  final String name, sticker;
  final LatLng at;
  final double tilt;
  final int day;
}

const visited = [
  Visited('Igreja de São João de Brito', 'azulejo', LatLng(38.7560, -9.1462), -5, 12),
  Visited('Jardim do Campo Grande', 'galo', LatLng(38.7600, -9.1500), 6, 12),
  Visited('Estádio José Alvalade', 'caravel', LatLng(38.7612, -9.1608), -4, 12),
  Visited('Teatro Maria Matos', 'guitar', LatLng(38.7465, -9.1390), -10, 12),
  Visited('Pastelaria Versailles', 'nata', LatLng(38.7395, -9.1458), -8, 13),
  Visited('Mercado de Arroios', 'sardine-tin', LatLng(38.7340, -9.1350), 4, 13),
  Visited('Torre de Belém', 'belem', LatLng(38.6916, -9.2160), -6, 13),
  Visited('Padrão dos Descobrimentos', 'padrao', LatLng(38.6936, -9.2057), 5, 13),
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
var _launch = DateTime.now();

/// Now, in the trip: the demo's start plus however long the app has been open (or since the last [jumpTo]).
DateTime tripNow() => (demoMoment.value?.at ?? tripNowAtLaunch).add(DateTime.now().difference(_launch));

// ---------- Demo: moments of the brief's story to jump between (Demo button, top right)

/// A moment in the brief's scenario: when it happens, which steps it shows (see USER-STORIES.md), and whether the
/// app has it yet. [opens] names a pop-up to open there ('money').
class StoryMoment {
  const StoryMoment(this.title, this.steps, {this.at, this.opens, this.built = true, this.bill = false, this.paid = false});
  final String title, steps;
  final DateTime? at;
  final String? opens;
  final bool built;

  /// Whether the dinner's bill is in by then (as scanned, paid by me), and whether everyone has paid.
  final bool bill, paid;
}

final storyMoments = [
  StoryMoment('Your trips', '01', built: false),
  StoryMoment('Ren joins', '03', at: DateTime(tripYear, tripMonth, today, 14, 10), built: false),
  StoryMoment('Dinner poll', '04–06', at: DateTime(tripYear, tripMonth, today, 14, 30), built: false),
  StoryMoment('The poll closes', '07', at: DateTime(tripYear, tripMonth, today, 15, 0), built: false),
  StoryMoment('On the way', '02', at: DateTime(tripYear, tripMonth, today, 15, 30)),
  StoryMoment('Before dinner', '02, 07', at: tripNowAtLaunch),
  StoryMoment("Everyone's there", '02', at: DateTime(tripYear, tripMonth, today, 17, 0)),
  StoryMoment('The bill', '08', at: DateTime(tripYear, tripMonth, today, 19, 30)),
  StoryMoment('Settle up', '09–10', at: DateTime(tripYear, tripMonth, today, 19, 40), opens: 'money', bill: true),
  StoryMoment('Squared up', '11', at: DateTime(tripYear, tripMonth, today, 19, 50), opens: 'money', bill: true, paid: true),
];

/// The moment the demo last jumped to (null: it runs on from the start).
final demoMoment = ValueNotifier<StoryMoment?>(null);

/// Jumps the demo's clock to [m] and runs on from there, with the money as it stands then: no bill before it's
/// scanned; at Settle up the bill is in and the others start paying; at Squared up everyone has paid.
void jumpTo(StoryMoment m) {
  _launch = DateTime.now();
  demoMoment.value = m;
  if (!m.bill) {
    dinnerBill.value = null;
    madePayments.value = const [];
    duePayments.clear();
    return;
  }
  addBill(scannedBill(tripNow()));
  if (m.paid) {
    settleUp.forEach(recordPayment);
    duePayments.clear();
  }
}

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

// ── Money ────────────────────────────────────────────────────────────────────────────────────────────────────────────
// What the trip has cost so far, from the earlier prototypes (prototype/versions/v11-midfi-receipt.html): the flat, the
// tuk-tuk and the groceries, each split between the four who were here then. Ren joined today, so none of it is Ren's.
// Tonight's dinner isn't on the bill yet; until it is, it's an estimate from what everyone picked.

class Expense {
  const Expense(this.title, this.amount, this.paidBy, this.split, this.day, {this.shares});
  final String title;
  final double amount;

  /// Person ids: who paid, and who shares it (equally, unless [shares] says who had what).
  final String paidBy;
  final List<String> split;
  final int day;
  final Map<String, double>? shares;

  double shareOf(String id) => shares?[id] ?? (split.contains(id) && shares == null ? amount / split.length : 0);
}

const expenses = [
  Expense('Groceries and drinks', 46, 'leo', ['ari', 'maya', 'nic', 'leo'], 13),
  Expense('Tuk-tuk tour', 80, 'nic', ['ari', 'maya', 'nic', 'leo'], 13),
  Expense('Airbnb, Alfama flat', 600, 'maya', ['ari', 'maya', 'nic', 'leo'], 12),
];

/// Every expense so far, newest first: tonight's dinner once its bill is in, then the earlier ones.
List<Expense> get tripExpenses => [if (dinnerBill.value case final b?) b.expense, ...expenses];

double get spentSoFar => tripExpenses.fold(0.0, (sum, e) => sum + e.amount);

/// What [id] has paid, minus their share: above zero they get money back, below they owe.
double balanceOf(String id) => tripExpenses.fold(0.0, (sum, e) => sum + (e.paidBy == id ? e.amount : 0) - e.shareOf(id));

/// One person paying another to settle up.
typedef Payment = ({String from, String to, double amount});

/// The fewest payments that square everyone up: the biggest debt pays the biggest credit, again and again.
List<Payment> get settleUp {
  final owe = {for (final p in people) if (balanceOf(p.id) < -0.005) p.id: -balanceOf(p.id)};
  final get = {for (final p in people) if (balanceOf(p.id) > 0.005) p.id: balanceOf(p.id)};
  final out = <Payment>[];
  while (owe.isNotEmpty && get.isNotEmpty) {
    final d = owe.entries.reduce((a, b) => a.value >= b.value ? a : b), c = get.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final amount = d.value < c.value ? d.value : c.value;
    out.add((from: d.key, to: c.key, amount: amount));
    if ((owe[d.key] = d.value - amount) < 0.005) owe.remove(d.key);
    if ((get[c.key] = c.value - amount) < 0.005) get.remove(c.key);
  }
  return out;
}

/// How many payments it would take one expense at a time: everyone in a split pays whoever paid it.
int get paymentsOneByOne => tripExpenses.fold(0, (sum, e) => sum + e.split.where((id) => id != e.paidBy && e.shareOf(id) > 0).length);

/// Tonight's dinner, roughly, from what everyone has picked on the menu (null until the menu has loaded).
double? get dinnerEstimate => loadedMenu == null
    ? null
    : [for (final s in loadedMenu!) ...s.items].fold<double>(0, (sum, d) => sum + (eurosIn(d.price) ?? 0) * d.pickedBy.length);

Person personById(String id) => people.firstWhere((p) => p.id == id);

// ── Ideas to add ─────────────────────────────────────────────────────────────────────────────────────────────────────

/// A place the Add pop-up suggests, with the free slot it would go in.
class PlanIdea {
  const PlanIdea(this.id, this.name, this.kind, this.sticker, this.at, this.day, this.hour);
  final String id, name, kind, sticker;
  final LatLng at;
  final int day, hour;

  Plan get plan => Plan(id: id, name: name, sticker: sticker, at: at, day: day, hour: hour);
}

const planIdeas = [
  PlanIdea('timeout', 'Time Out Market', 'Food hall', 'sardine-tin', LatLng(38.7069, -9.1459), 15, 13),
  PlanIdea('santini', 'Gelados Santini', 'Ice cream', 'ice-cream', LatLng(38.7108, -9.1418), 16, 15),
  PlanIdea('lxfactory', 'LX Factory', 'Shops and street art', 'azulejo', LatLng(38.7034, -9.1786), 20, 11),
];

/// Plans the group adds during the trip, on top of [plans].
final addedPlans = ValueNotifier<List<Plan>>(const []);

/// Every plan, in the order they happen.
List<Plan> get tripPlans => [...plans, ...addedPlans.value]..sort((a, b) => a.start.compareTo(b.start));

// ── Tonight: the dinner turning active, its bill, and settling up ────────────────────────────────────────────────────

/// Where I am now: walking my route on the demo clock, or where I started before I share it.
LatLng myPosition(DateTime now) => whereIs(personById(myId), now) ?? me;

/// How long a plan lasts after its start, for when it counts as over.
const planLasts = Duration(hours: 3);

/// The dinner is on: its time has come (from a quarter of an hour before) and someone is there (inside the
/// geofence). Nobody presses anything for it; it's where people are and the time.
bool isActive(Plan p, DateTime now) =>
    p == plans.first && !now.isBefore(p.start.subtract(const Duration(minutes: 15))) && now.isBefore(p.start.add(planLasts)) && people.any((x) => isHere(x, now));

/// The dishes I'll have, from the Menu: my picks from before, then whatever I add or remove there (null until the
/// menu has loaded).
final myPicks = ValueNotifier<Set<String>?>(null);

/// Who picked [item] on the Menu, me included as I am now.
List<String> pickersOf(MenuItem item) => [
      for (final id in item.pickedBy) if (id != myId) id,
      if (myPicks.value?.contains(item.name) ?? item.pickedBy.contains(myId)) myId,
    ];

/// One line of a printed bill: how it reads on the paper, how many, at what price, and which menu item it is.
class BillLine {
  const BillLine(this.printed, this.qty, this.unit, {this.item});
  final String printed;
  final int qty;
  final double unit;
  final String? item;

  double get total => qty * unit;
}

/// Tonight's bill at La Brasserie, line by line, at the menu's prices: what everyone picked, plus the couvert and
/// the water, which nobody picked.
const brasserieBill = [
  BillLine('COUVERT INDIVIDUAL', 5, 2.80, item: 'Individual couvert'),
  BillLine('ENTRECOTE SALADA', 3, 23.90, item: 'Sirloin entrecôte with lettuce and rocket salad'),
  BillLine('ENTRECOTE SALMAO', 1, 29.80, item: 'Sirloin entrecôte with marinated salmon'),
  BillLine('SEITAN SALADA', 1, 22.00, item: 'Seitan steak with lettuce and rocket salad'),
  BillLine('BATATA FRITA', 1, 3.60, item: 'Fries'),
  BillLine('FONDANT CHOCOLATE', 1, 6.50, item: 'Chocolate fondant with ice cream'),
  BillLine('CREME BRULEE', 2, 6.40, item: 'Crème brûlée'),
  BillLine('SOALHEIRO GRANIT', 2, 28.50, item: 'Soalheiro, Granit, Minho'),
  BillLine('SUMOL', 2, 2.90, item: 'Sumol or Lipton Ice Tea'),
  BillLine('AGUA LUSO 50CL', 2, 2.80, item: 'Luso water 50cl'),
];

MenuItem? menuItemNamed(String? name) => name == null ? null : [for (final s in loadedMenu ?? const <MenuSection>[]) ...s.items].where((i) => i.name == name).firstOrNull;

/// Who had a line: whoever picked it on the Menu, split between them. A line nobody picked starts with everyone at
/// the table; any line can be changed by hand. Wine nobody else picked stays with the ones who did, so two people
/// skipping it needs nothing special.
List<String> whoHad(BillLine line, List<String> table) {
  final item = menuItemNamed(line.item);
  final picked = item == null ? const <String>[] : [for (final id in pickersOf(item)) if (table.contains(id)) id];
  return picked.isEmpty ? table : picked;
}

/// A scanned bill: its lines, who had each, and who paid.
class Bill {
  const Bill(this.lines, this.who, this.paidBy, this.at);
  final List<BillLine> lines;
  final List<List<String>> who;
  final String paidBy;
  final DateTime at;

  double get total => lines.fold(0.0, (sum, l) => sum + l.total);

  /// What each person had, to the cent.
  Map<String, double> get shares {
    final out = <String, double>{};
    for (final (i, l) in lines.indexed) {
      for (final id in who[i]) {
        out[id] = (out[id] ?? 0) + l.total / who[i].length;
      }
    }
    return {for (final e in out.entries) e.key: (e.value * 100).round() / 100};
  }

  Expense get expense => Expense("Dinner, La Brasserie de L'Entrecôte", total, paidBy, [for (final e in shares.entries) if (e.value > 0) e.key], today, shares: shares);
}

/// Everyone who's coming, at the table.
List<String> get dinnerTable => [for (final p in people) if (p.going) p.id];

/// The bill as it comes off the scan, before anyone changes a line.
Bill scannedBill(DateTime at) => Bill(brasserieBill, [for (final l in brasserieBill) whoHad(l, dinnerTable)], myId, at);

/// Tonight's bill, once someone has scanned it and added it to the trip's money.
final dinnerBill = ValueNotifier<Bill?>(null);

/// A payment someone has made, and when.
typedef MadePayment = ({String from, String to, double amount, DateTime at});
final madePayments = ValueNotifier<List<MadePayment>>(const []);

bool isPaid(Payment p) => madePayments.value.any((m) => m.from == p.from && m.to == p.to);

/// What [id] still gets back (+) or owes (−), after the payments made so far.
double balanceLeft(String id) => madePayments.value.fold(balanceOf(id), (b, m) => b + (m.from == id ? m.amount : 0) - (m.to == id ? m.amount : 0));

/// Everyone has paid what the fewest payments asked of them.
bool get squaredUp => settleUp.isNotEmpty && settleUp.every(isPaid);

/// The others' payments, as they'd come in from their own phones: each a little after the last (demo clock).
final duePayments = <({Payment pay, DateTime at})>[];
const paymentGap = Duration(seconds: 30);

/// Adds the bill to the trip's money. The others start paying what they owe on their own.
void addBill(Bill b) {
  dinnerBill.value = b;
  madePayments.value = const [];
  duePayments
    ..clear()
    ..addAll([for (final (i, p) in settleUp.where((p) => p.from != myId).indexed) (pay: p, at: tripNow().add(paymentGap * (i + 1)))]);
}

/// Records a payment (mine from Pay, or one of the others' coming in).
void recordPayment(Payment p) {
  if (isPaid(p)) return;
  madePayments.value = [...madePayments.value, (from: p.from, to: p.to, amount: p.amount, at: tripNow())];
}

/// The others' payments that are due by now, in order; each one is recorded as it's returned.
List<Payment> takeDuePayments(DateTime now) {
  final due = [for (final d in duePayments) if (!d.at.isAfter(now)) d.pay];
  duePayments.removeWhere((d) => !d.at.isAfter(now));
  due.forEach(recordPayment);
  return due;
}

/// A short note for everyone on the trip, shown at the top of the map ("Leo paid Maya €185.92").
final tripNotice = ValueNotifier<String?>(null);

String payLine(Payment p) => '${p.from == myId ? 'You' : personById(p.from).name} paid ${p.to == myId ? 'you' : personById(p.to).name} ${euros(p.amount)}';
