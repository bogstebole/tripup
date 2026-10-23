// Demo content for the Lisbon trip. Shared by every story; the Flutter app has the same data in lib/data.dart.

export const stickerUrl = (name: string) => `/assets/stickers/${name}.png`;
export const photoUrl = (name: string) => `/assets/photos/${name}.png`;
export const dishUrl = (name: string) => `/assets/photos/menu/${name}.jpg`;

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

export type PlaceDetail = { kind: 'address' | 'hours' | 'price' | 'booking' | 'order' | 'website' | 'phone'; text: string; status?: string; sub?: string };

export const EVENT = {
  label: 'Up next',
  name: "La Brasserie de L'Entrecôte - Alvalade",
  rating: '4.2 (173)',
  cuisine: 'French',
  price: '€€',
  when: '5 PM • Today',
  eta: 'In 64 mins',
  sticker: 'wings',
  photos: ['brasserie-1', 'brasserie-2', 'brasserie-3'],
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
