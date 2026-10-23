// Demo content for the Lisbon trip. Shared by every story; the Flutter app has the same data in lib/data.dart.

export const stickerUrl = (name: string) => `/assets/stickers/${name}.png`;
export const photoUrl = (name: string) => `/assets/photos/${name}.png`;
export const dishUrl = (name: string) => `/assets/photos/menu/${name}.jpg`;

/** The first price on a menu line, in euros ("1 scoop €3.40 · 2 scoops €5.10" counts as €3.40). */
export const eurosIn = (price: string) => {
  const m = /€\s?(\d+(?:[.,]\d+)?)/.exec(price);
  return m ? parseFloat(m[1].replace(',', '.')) : undefined;
};
export const euros = (v: number) => `€${v.toFixed(2)}`;

export type Person = { id: string; name: string; sticker: string; status: string };
export const PEOPLE: Person[] = [
  { id: 'ari', name: 'You', sticker: 'person-04', status: 'On the way · 12 min' },
  { id: 'maya', name: 'Maya', sticker: 'person-01', status: 'Already there' },
  { id: 'nic', name: 'Nic', sticker: 'person-05', status: 'On the way · 8 min' },
  { id: 'leo', name: 'Leo', sticker: 'person-02', status: 'Leaves in 20 min' },
  { id: 'ren', name: 'Ren', sticker: 'person-03', status: 'Not going' },
];

/** Food stickers fanned out on the Up next card: content, placed by hand in Figma (height in px, tilt in degrees). */
export const DISH_FAN = [
  { sticker: 'pho', height: 44.79, tilt: 0 },
  { sticker: 'sushi', height: 78.53, tilt: -7.99 },
  { sticker: 'wings', height: 95, tilt: 0 },
  { sticker: 'ice-cream', height: 65.47, tilt: 8.59 },
];

export type Dish = { id: string; name: string; price: string; sticker: string; pickedBy: string[] };
export const MENU: Dish[] = [
  { id: 'wings', name: 'Spicy chicken wings', price: '€12', sticker: 'wings', pickedBy: ['ari', 'nic'] },
  { id: 'sushi', name: 'Sushi plate for two', price: '€24', sticker: 'sushi', pickedBy: ['maya', 'leo'] },
  { id: 'pho', name: 'Beef pho', price: '€14', sticker: 'pho', pickedBy: ['leo'] },
  { id: 'ice-cream', name: 'Lime sorbet', price: '€6', sticker: 'ice-cream', pickedBy: ['ari', 'maya', 'nic'] },
];

// ---------- Time: the demo's "now", the same as the app's

/** Where the demo starts: Thursday 14 May 2026, 15:56, an hour before dinner. */
export const TRIP_NOW = new Date(2026, 4, 14, 15, 56);
const daysBetween = (from: Date, to: Date) => Math.round((new Date(to.getFullYear(), to.getMonth(), to.getDate()).getTime() - new Date(from.getFullYear(), from.getMonth(), from.getDate()).getTime()) / 86400000);

/** How soon, the way a person would say it: minutes for the next hour and a half, then hours the same day, then "Tomorrow", then days. */
export const timeUntil = (start: Date, now = TRIP_NOW) => {
  const mins = Math.floor((start.getTime() - now.getTime()) / 60000);
  if (mins <= 0) return 'Now';
  const days = daysBetween(now, start);
  if (days === 0) {
    if (mins < 90) return `In ${mins} ${mins === 1 ? 'min' : 'mins'}`;
    const hrs = Math.round(mins / 60);
    return `In ${hrs} ${hrs === 1 ? 'hr' : 'hrs'}`;
  }
  return days === 1 ? 'Tomorrow' : `In ${days} days`;
};
/** "5 PM", "10:30 AM". */
export const clockTime = (t: Date) => `${t.getHours() % 12 || 12}${t.getMinutes() ? `:${String(t.getMinutes()).padStart(2, '0')}` : ''} ${t.getHours() < 12 ? 'AM' : 'PM'}`;
/** "Today", "Tomorrow", or "Sat 16". */
export const dayName = (t: Date, now = TRIP_NOW) => {
  const d = daysBetween(now, t);
  return d === 0 ? 'Today' : d === 1 ? 'Tomorrow' : `${t.toLocaleDateString('en-GB', { weekday: 'short' })} ${t.getDate()}`;
};

/** Dinner, the Up next plan. */
const DINNER = new Date(2026, 4, 14, 17, 0);

export type PlaceDetail = { kind: 'address' | 'hours' | 'price' | 'booking' | 'order' | 'website' | 'phone'; text: string; status?: string; sub?: string };

export const EVENT = {
  label: 'Up next',
  name: "La Brasserie de L'Entrecôte - Alvalade",
  rating: '4.2 (173)',
  cuisine: 'French',
  price: '€€',
  when: `${clockTime(DINNER)} • ${dayName(DINNER)}`,
  whenLong: `${dayName(DINNER)}, ${clockTime(DINNER)}`,
  eta: timeUntil(DINNER),
  sticker: 'wings',
  photos: ['brasserie-2', 'brasserie-3', 'brasserie-1', 'brasserie-4', 'brasserie-5'],   // 4 and 5 are from the restaurant's own menu
  // From the place's Google Maps card
  services: ['Dine-in', 'Takeaway', 'Delivery'],
  details: [
    { kind: 'address', text: 'Av. da Igreja 12B, 1700-238 Lisboa' },
    { kind: 'hours', text: 'Closes 11 PM', status: 'Open', sub: 'Opens 12 PM tomorrow' },
    { kind: 'price', text: '€20–40 per person', sub: 'Reported by 57 people' },
    { kind: 'booking', text: 'Find a table', sub: 'thefork.pt' },
    { kind: 'order', text: 'Place an order', sub: 'ubereats.com' },
    { kind: 'website', text: 'brasserieentrecote.pt' },
    { kind: 'phone', text: '+351 21 090 0179' },
  ] as PlaceDetail[],
  about:
    'La Brasserie de L’Entrecôte is a unique restaurant in many ways. For 30 years we have specialized in preparing a very special dish: the tender and sliced Entrecote, served with delicious and crispy French fries, complemented with delicious starters, countless deserts and an excellent wine list.',
  tips: [
    'Visitors highlight the exceptional secret sauce served over the tender entrecote',
    'Reviewers say the crisp fries are unlimited so you can ask for more refills',
    'Some say dining room can be quite noisy during busy hours',
  ],
};

export const TRIP = { title: 'Schmedeswurtherwesterdeich', dates: '12 May - 21 May' };

/** The trip's days (May 2026) for the day filter; today, in the demo, is the 14th. */
export const TRIP_DAYS = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21].map(day => ({
  day,
  label: `${new Date(2026, 4, day).toLocaleDateString('en-GB', { weekday: 'short' })} ${day}`,
}));

/** The Up next widget's content, as on the Figma screens. */
export const UP_NEXT = {
  label: EVENT.label,
  name: EVENT.name,
  rating: EVENT.rating,
  cuisine: EVENT.cuisine,
  eta: EVENT.eta,
  sticker: EVENT.sticker,
  fan: DISH_FAN,
  chips: [{ text: '+3', sticker: 'person-05', tilt: -6.22 }, { text: EVENT.price, grow: true }, { text: EVENT.when }],
};
