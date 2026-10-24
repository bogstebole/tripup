// Demo content for the Lisbon trip. Shared by every story; the Flutter app has the same data in lib/data.dart.
import realMenu from '../../app/assets/data/brasserie-menu.json';
import type { InfoChip } from './components/InfoChips';

export const stickerUrl = (name: string) => `/assets/stickers/${name}.png`;
export const photoUrl = (name: string) => `/assets/photos/${name}.png`;
export const dishUrl = (name: string) => `/assets/photos/menu/${name}.jpg`;

/** The first price on a menu line, in euros ("1 scoop €3.40 · 2 scoops €5.10" counts as €3.40). */
export const eurosIn = (price: string) => {
  const m = /€\s?(\d+(?:[.,]\d+)?)/.exec(price);
  return m ? parseFloat(m[1].replace(',', '.')) : undefined;
};
export const euros = (v: number) => `€${v.toFixed(2)}`;

/** Today in the demo, as a day of the trip's month (May 2026). */
export const TODAY = 14;

/** Me, in the people list, in who picked what and in who owes whom. */
export const MY_ID = 'ari';

/**
 * `leaves` and `arrives` are when they set off for dinner and get there, in minutes after midnight on the trip's
 * today (the app simulates their walks on the demo clock; in the real app it's their shared locations).
 * `status` is what the app works out from that at the demo's start (Thu 15:56); see `statusOf` and `peopleAt`.
 * `joined` is the day they joined the trip, and `joinedMinute` when that day (minutes after midnight; 0 if left out):
 * costs from before it aren't theirs.
 */
export type Person = { id: string; name: string; sticker: string; status: string; going: boolean; joined: number; joinedMinute?: number; leaves: number; arrives: number };
type Walker = Omit<Person, 'status'>;
/** The group, on their way to dinner (17:00): Maya is there, Nic is on his way, Leo leaves at 16:16, and Ren (who
 *  joined today) and I leave at 16:30. */
const CREW: Walker[] = [
  { id: 'ari', name: 'You', sticker: 'person-04', going: true, joined: 12, leaves: 16 * 60 + 30, arrives: 16 * 60 + 52 },
  { id: 'maya', name: 'Maya', sticker: 'person-01', going: true, joined: 12, leaves: 15 * 60 + 28, arrives: 15 * 60 + 46 },
  { id: 'nic', name: 'Nic', sticker: 'person-05', going: true, joined: 12, leaves: 15 * 60 + 48, arrives: 16 * 60 + 4 },
  { id: 'leo', name: 'Leo', sticker: 'person-02', going: true, joined: 12, leaves: 16 * 60 + 16, arrives: 16 * 60 + 36 },
  { id: 'ren', name: 'Ren', sticker: 'person-03', going: true, joined: TODAY, joinedMinute: 14 * 60 + 10, leaves: 16 * 60 + 30, arrives: 16 * 60 + 48 },   // joined mid-trip, today at 2:10 PM
];

const minuteOf = (t: Date) => t.getHours() * 60 + t.getMinutes() + t.getSeconds() / 60;

/** Whether `p` has got to the Up next place (inside its geofence). */
export const isHere = (p: Walker, now: Date) => p.going && minuteOf(now) >= p.arrives;

/** "Already there", "On the way · 8 min", "Leaves in 20 min", or "Not going". */
export const statusOf = (p: Walker, now: Date) => {
  if (!p.going) return 'Not going';
  const m = minuteOf(now);
  if (m >= p.arrives) return 'Already there';
  if (m >= p.leaves) return `On the way · ${Math.ceil(p.arrives - m)} min`;
  return `Leaves in ${Math.ceil(p.leaves - m)} min`;
};

/** Everyone, with their status at `now`. */
export const peopleAt = (now: Date): Person[] => CREW.map(p => ({ ...p, status: statusOf(p, now) }));

/** The whole group as one little pile on the footer's money button (Figma "People", 38.6 × 38.2): content, placed by
 *  hand, back to front (top-left corner and height in px, tilt in degrees). */
export const CREW_PILE = {
  width: 38.58,
  height: 38.21,
  stickers: [
    { sticker: 'person-02', left: 1, top: 7, height: 24, tilt: 0 },
    { sticker: 'person-04', left: 0, top: 10, height: 24, tilt: 0 },
    { sticker: 'person-01', left: 9, top: 0, height: 24.59, tilt: 0 },
    { sticker: 'person-05', left: 10.24, top: 13.1, height: 24, tilt: -6.22 },
    { sticker: 'person-03', left: 17, top: 10, height: 24, tilt: 0 },
  ],
};

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

/** Everyone as they are at the demo's start: Maya there, Nic on his way, the rest still to leave. */
export const PEOPLE = peopleAt(TRIP_NOW);
export const personById = (id: string) => PEOPLE.find(p => p.id === id)!;
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

/** Dinner, the Up next plan: tonight, 5 PM (the slot the dinner poll decides). */
export const DINNER = new Date(2026, 4, 14, 17, 0);

export type PlaceDetail = { kind: 'address' | 'hours' | 'price' | 'booking' | 'order' | 'website' | 'phone'; text: string; status?: string; sub?: string };

export const EVENT = {
  label: 'Up next',
  name: "La Brasserie de L'Entrecôte - Alvalade",
  rating: '4.2 (173)',
  cuisine: 'French',
  price: '€20–40',   // the range from the price detail below
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

export const TRIP = { title: 'Schmedeswurtherwesterdeich', city: 'Lisbon', dates: '12 May - 21 May' };

/** The trip's days (May 2026) for the day filter; today, in the demo, is the 14th. */
export const TRIP_DAYS = [12, 13, 14, 15, 16, 17, 18, 19, 20, 21].map(day => ({
  day,
  label: `${new Date(2026, 4, day).toLocaleDateString('en-GB', { weekday: 'short' })} ${day}`,
}));

/**
 * The Up next card's chips, by the app's rule (`UpNextMid`): how many are coming, or once anyone has arrived, every
 * arrived face and "here"; then the price range. The two share the width until four or more faces need the room,
 * then the price shrinks to its text.
 */
export const upNextChips = (here: string[]): InfoChip[] => [
  here.length ? { text: 'here', faces: here, grow: true } : { text: `${PEOPLE.filter(p => p.going).length} coming`, grow: true },
  { text: EVENT.price, grow: here.length < 4 },
];

/** How long a plan lasts after its start, for when it counts as over (the app's `planLasts`). */
export const PLAN_LASTS_MS = 3 * 3600000;

/** Dinner is on: its time has come (from a quarter of an hour before, for the three hours it lasts) and someone is
 *  there (inside the geofence). Nobody presses anything for it; it's where people are and the time. */
export const isActive = (now: Date) =>
  now.getTime() >= DINNER.getTime() - 15 * 60000 && now.getTime() < DINNER.getTime() + PLAN_LASTS_MS && CREW.some(p => isHere(p, now));

/** Moments of the brief's story (the app's Demo button): everyone's at the table, then the bill comes. */
export const EVERYONE_THERE = new Date(2026, 4, 14, 17, 0);
export const THE_BILL = new Date(2026, 4, 14, 19, 30);

/**
 * The Up next widget's content at `now`, by the app's rules: "Up next · 5 PM" and how soon, until the dinner is on;
 * then "Now", with a dot, and "You're here" once I'm inside its geofence (the mini says "Now"). `here` is everyone
 * else who has arrived (the app leaves me out: I know I'm there).
 */
export const upNextAt = (now: Date) => {
  const here = CREW.filter(p => p.id !== MY_ID && isHere(p, now)).map(p => p.sticker);
  const on = isActive(now);
  const me = CREW.find(p => p.id === MY_ID)!;
  return {
    label: on ? `Now · ${isHere(me, now) ? "You're here" : clockTime(DINNER)}` : `${EVENT.label} · ${clockTime(DINNER)}`,
    name: EVENT.name,
    rating: EVENT.rating,
    cuisine: EVENT.cuisine,
    eta: on ? 'Now' : timeUntil(DINNER, now),
    now: on,
    sticker: EVENT.sticker,
    fan: DISH_FAN,
    // Who's here (their faces, then "here") and the price range. The time sits by "Up next".
    chips: upNextChips(here),
    // On the mini pin, the same faces sit across its top-right corner
    here,
  };
};

/** The Up next widget's content at the demo's start, as on the Figma screens: Maya is already there. */
export const UP_NEXT = upNextAt(TRIP_NOW);

/** At dinner: everyone's there, me too, so the card says "Now · You're here". */
export const UP_NEXT_NOW = upNextAt(EVERYONE_THERE);

// ---------- The trip's days: where we've been and what's planned (the itinerary pop-up)

/** A day of the trip at a time of day. */
export const tripDate = (day: number, hour = 0, minute = 0) => new Date(2026, 4, day, hour, minute);

/** Planned, in order. The first one is Up next. `endHour` and `endMinute`: when it ends, if whoever planned it said
 *  (Plan something asks for a range). */
export type Plan = { id: string; name: string; sticker: string; day: number; hour: number; minute?: number; endHour?: number; endMinute?: number };
export const PLANS: Plan[] = [
  { id: 'brasserie', name: EVENT.name, sticker: EVENT.sticker, day: TODAY, hour: 17 },
  { id: 'croissants', name: 'Sam Croissants', sticker: 'nata', day: TODAY, hour: 18 },
  { id: 'tram', name: 'Tram 28 ride', sticker: 'tram', day: 15, hour: 10 },
  { id: 'sail', name: 'Sail on the Tagus', sticker: 'caravel', day: 16, hour: 18 },
  { id: 'fado', name: 'Fado at Tasca do Chico', sticker: 'guitar', day: 17, hour: 21 },
  { id: 'oceanario', name: 'Oceanário', sticker: 'festival-sardine', day: 18, hour: 11 },
  { id: 'tiles', name: 'Tile Museum', sticker: 'azulejo', day: 19, hour: 10 },
];
export const planStart = (p: Plan) => tripDate(p.day, p.hour, p.minute ?? 0);
/** When it ends, if it says. */
export const planEnd = (p: Plan) => (p.endHour === undefined ? undefined : tripDate(p.day, p.endHour, p.endMinute ?? 0));

/** Places already visited: stickers on the map, the trip's history (tilt in degrees). */
export type Visited = { name: string; sticker: string; tilt: number; day: number };
export const VISITED: Visited[] = [
  { name: 'Igreja de São João de Brito', sticker: 'azulejo', tilt: -5, day: 12 },
  { name: 'Jardim do Campo Grande', sticker: 'galo', tilt: 6, day: 12 },
  { name: 'Estádio José Alvalade', sticker: 'caravel', tilt: -4, day: 12 },
  { name: 'Teatro Maria Matos', sticker: 'guitar', tilt: -10, day: 12 },
  { name: 'Pastelaria Versailles', sticker: 'nata', tilt: -8, day: 13 },
  { name: 'Mercado de Arroios', sticker: 'sardine-tin', tilt: 4, day: 13 },
  { name: 'Torre de Belém', sticker: 'belem', tilt: -6, day: 13 },
  { name: 'Padrão dos Descobrimentos', sticker: 'padrao', tilt: 5, day: 13 },
];

// ---------- Money: what the trip has cost so far (the money pop-up)
// The flat, the tuk-tuk and the groceries, each split between the four who were here then. Ren joined today, so none
// of it is Ren's. Tonight's dinner isn't on it until its bill is scanned; until then it's an estimate from what
// everyone picked. The money comes in two modes: before the bill (PRE_DINNER) and with it in (BILL_IN).

/** `paidBy` and `split` are person ids: who paid, and who shares it (equally, unless `shares` says who had what). */
export type Expense = { title: string; amount: number; paidBy: string; split: string[]; day: number; shares?: Record<string, number> };
/** The ones from before tonight, newest first. */
export const EXPENSES: Expense[] = [
  { title: 'Groceries and drinks', amount: 46, paidBy: 'leo', split: ['ari', 'maya', 'nic', 'leo'], day: 13 },
  { title: 'Tuk-tuk tour', amount: 80, paidBy: 'nic', split: ['ari', 'maya', 'nic', 'leo'], day: 13 },
  { title: 'Airbnb, Alfama flat', amount: 600, paidBy: 'maya', split: ['ari', 'maya', 'nic', 'leo'], day: 12 },
];
export const shareOf = (e: Expense, id: string) => (e.shares ? e.shares[id] ?? 0 : e.split.includes(id) ? e.amount / e.split.length : 0);

/** One person paying another to settle up. */
export type Payment = { from: string; to: string; amount: number };

/** The money as it stands: every expense (newest first), what they come to, each balance, and the fewest payments. */
export type Money = {
  /** Tonight's bill, once it's in. */
  bill?: Bill;
  expenses: Expense[];
  spent: number;
  /** What `id` has paid, minus their share: above zero they get money back, below they owe. */
  balanceOf: (id: string) => number;
  /** The fewest payments that square everyone up. */
  settleUp: Payment[];
  /** How many payments it would take one expense at a time: everyone in a split pays whoever paid it. */
  paymentsOneByOne: number;
};

/** The money with tonight's dinner on it once its bill is in, or without it (the app's `tripExpenses` and the rest). */
export const moneyWith = (bill?: Bill): Money => {
  const expenses = [...(bill ? [billExpense(bill)] : []), ...EXPENSES];
  const balanceOf = (id: string) => expenses.reduce((sum, e) => sum + (e.paidBy === id ? e.amount : 0) - shareOf(e, id), 0);
  // The biggest debt pays the biggest credit, again and again. On a tie, the first one in the people list goes
  // first (as in the app).
  const owe = new Map(PEOPLE.filter(p => balanceOf(p.id) < -0.005).map(p => [p.id, -balanceOf(p.id)] as const));
  const get = new Map(PEOPLE.filter(p => balanceOf(p.id) > 0.005).map(p => [p.id, balanceOf(p.id)] as const));
  const biggest = (m: Map<string, number>) => [...m].reduce((a, b) => (a[1] >= b[1] ? a : b));
  const settleUp: Payment[] = [];
  while (owe.size && get.size) {
    const [d, dv] = biggest(owe), [c, cv] = biggest(get);
    const amount = Math.min(dv, cv);
    settleUp.push({ from: d, to: c, amount });
    if (dv - amount < 0.005) owe.delete(d); else owe.set(d, dv - amount);
    if (cv - amount < 0.005) get.delete(c); else get.set(c, cv - amount);
  }
  return {
    bill,
    expenses,
    spent: expenses.reduce((sum, e) => sum + e.amount, 0),
    balanceOf,
    settleUp,
    paymentsOneByOne: expenses.reduce((sum, e) => sum + e.split.filter(id => id !== e.paidBy && shareOf(e, id) > 0).length, 0),
  };
};

/** Whether `p` has been paid, in the payments made so far. */
export const isPaid = (p: Payment, made: Payment[]) => made.some(x => x.from === p.from && x.to === p.to);

/** What `id` still gets back (+) or owes (−), after the payments made so far. */
export const balanceLeft = (money: Money, made: Payment[], id: string) =>
  made.reduce((b, x) => b + (x.from === id ? x.amount : 0) - (x.to === id ? x.amount : 0), money.balanceOf(id));

/** Everyone has paid what the fewest payments asked of them. */
export const squaredUp = (money: Money, made: Payment[]) => money.settleUp.length > 0 && money.settleUp.every(p => isPaid(p, made));

/** "Leo paid Maya €185.92", "You paid Maya €11.82": the note everyone on the trip sees. */
export const payLine = (p: Payment) => `${p.from === MY_ID ? 'You' : personById(p.from).name} paid ${p.to === MY_ID ? 'you' : personById(p.to).name} ${euros(p.amount)}`;

type MenuItem = { name: string; price: string; pickedBy?: string[] };
const MENU_ITEMS = (realMenu as { sections: { items: MenuItem[] }[] }).sections.flatMap(s => s.items);

/** Tonight's dinner, roughly, from what everyone has picked on the restaurant's menu. */
export const DINNER_ESTIMATE = MENU_ITEMS.reduce((sum, d) => sum + (eurosIn(d.price) ?? 0) * (d.pickedBy?.length ?? 0), 0);

// ---------- Tonight: the dinner's bill, scanned, split by who had what

export const menuItemNamed = (name?: string) => (name ? MENU_ITEMS.find(i => i.name === name) : undefined);

/** Who picked `item` on the Menu: the others, then me. */
export const pickersOf = (item: MenuItem) => [...(item.pickedBy ?? []).filter(id => id !== MY_ID), ...(item.pickedBy?.includes(MY_ID) ? [MY_ID] : [])];

/** One line of a printed bill: how it reads on the paper, how many, at what price, and which menu item it is. */
export type BillLine = { printed: string; qty: number; unit: number; item?: string };
export const lineTotal = (l: BillLine) => l.qty * l.unit;

/** Tonight's bill at La Brasserie, line by line, at the menu's prices: what everyone picked, plus the couvert and
 *  the water, which nobody picked. 10 lines, €228.80. */
export const BRASSERIE_BILL: BillLine[] = [
  { printed: 'COUVERT INDIVIDUAL', qty: 5, unit: 2.8, item: 'Individual couvert' },
  { printed: 'ENTRECOTE SALADA', qty: 3, unit: 23.9, item: 'Sirloin entrecôte with lettuce and rocket salad' },
  { printed: 'ENTRECOTE SALMAO', qty: 1, unit: 29.8, item: 'Sirloin entrecôte with marinated salmon' },
  { printed: 'SEITAN SALADA', qty: 1, unit: 22, item: 'Seitan steak with lettuce and rocket salad' },
  { printed: 'BATATA FRITA', qty: 1, unit: 3.6, item: 'Fries' },
  { printed: 'FONDANT CHOCOLATE', qty: 1, unit: 6.5, item: 'Chocolate fondant with ice cream' },
  { printed: 'CREME BRULEE', qty: 2, unit: 6.4, item: 'Crème brûlée' },
  { printed: 'SOALHEIRO GRANIT', qty: 2, unit: 28.5, item: 'Soalheiro, Granit, Minho' },
  { printed: 'SUMOL', qty: 2, unit: 2.9, item: 'Sumol or Lipton Ice Tea' },
  { printed: 'AGUA LUSO 50CL', qty: 2, unit: 2.8, item: 'Luso water 50cl' },
];

/** Everyone who's coming, at the table. */
export const DINNER_TABLE = PEOPLE.filter(p => p.going).map(p => p.id);

/** Who had a line: whoever picked it on the Menu, split between them. A line nobody picked starts with everyone at
 *  the table; any line can be changed by hand. */
export const whoHad = (line: BillLine, table: string[]) => {
  const item = menuItemNamed(line.item);
  const picked = item ? pickersOf(item).filter(id => table.includes(id)) : [];
  return picked.length ? picked : table;
};

/** A scanned bill: its lines, who had each (by line), and who paid. */
export type Bill = { lines: BillLine[]; who: string[][]; paidBy: string };
export const billTotal = (b: Bill) => b.lines.reduce((sum, l) => sum + lineTotal(l), 0);

/** What each person had, to the cent. */
export const billShares = (b: Bill) => {
  const out: Record<string, number> = {};
  b.lines.forEach((l, i) => b.who[i].forEach(id => { out[id] = (out[id] ?? 0) + lineTotal(l) / b.who[i].length; }));
  return Object.fromEntries(Object.entries(out).map(([id, v]) => [id, Math.round(v * 100) / 100]));
};

/** The bill as an expense: split by who had what. */
export const billExpense = (b: Bill): Expense => {
  const shares = billShares(b);
  return { title: "Dinner, La Brasserie de L'Entrecôte", amount: billTotal(b), paidBy: b.paidBy, split: Object.keys(shares).filter(id => shares[id] > 0), day: TODAY, shares };
};

/** The bill as it comes off the scan, before anyone changes a line: paid by me. Shares: You €59.12, Maya €53.32,
 *  Nic €35.22, Leo €50.42, Ren €30.72. */
export const scannedBill = (): Bill => ({ lines: BRASSERIE_BILL, who: BRASSERIE_BILL.map(l => whoHad(l, DINNER_TABLE)), paidBy: MY_ID });
export const SCANNED_BILL = scannedBill();

/** Before the bill: €726.00, 3 expenses, 3 payments instead of 9. */
export const PRE_DINNER = moneyWith();
/** With the dinner in: €954.80, 4 expenses, 4 payments instead of 13, all to Maya. */
export const BILL_IN = moneyWith(SCANNED_BILL);
export const SPENT_SO_FAR = PRE_DINNER.spent;

// ---------- Ideas to add (the add pop-up)

/** A place the Add pop-up suggests, with the free slot it would go in. */
export type PlanIdea = { id: string; name: string; kind: string; sticker: string; day: number; hour: number };
export const PLAN_IDEAS: PlanIdea[] = [
  { id: 'timeout', name: 'Time Out Market', kind: 'Food hall', sticker: 'sardine-tin', day: 15, hour: 13 },
  { id: 'santini', name: 'Gelados Santini', kind: 'Ice cream', sticker: 'ice-cream', day: 16, hour: 15 },
  { id: 'lxfactory', name: 'LX Factory', kind: 'Shops and street art', sticker: 'azulejo', day: 20, hour: 11 },
];

/** A place Plan something can find: Lisbon's well-known spots, where they are, and a sticker for the map. */
export type PlaceSpot = { id: string; name: string; kind: string; area: string; at: LatLng; sticker: string };

/** Lower case, without accents ("Belém" → "belem"). */
const plain = (s: string) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');

/** Whether a search matches it: its name, what it is or where, ignoring case and accents. */
export const placeMatches = (s: PlaceSpot, query: string) => {
  const q = plain(query.trim());
  return !q || [s.name, s.kind, s.area].some(x => plain(x).includes(q));
};

export const LISBON_PLACES: PlaceSpot[] = [
  { id: 'timeout', name: 'Time Out Market', kind: 'Food hall', area: 'Cais do Sodré', at: [38.7069, -9.1459], sticker: 'sardine-tin' },
  { id: 'santini', name: 'Gelados Santini', kind: 'Ice cream', area: 'Chiado', at: [38.7108, -9.1418], sticker: 'ice-cream' },
  { id: 'lxfactory', name: 'LX Factory', kind: 'Shops and street art', area: 'Alcântara', at: [38.7034, -9.1786], sticker: 'azulejo' },
  { id: 'pasteis-belem', name: 'Pastéis de Belém', kind: 'Bakery', area: 'Belém', at: [38.6975, -9.2032], sticker: 'nata' },
  { id: 'jeronimos', name: 'Mosteiro dos Jerónimos', kind: 'Monastery', area: 'Belém', at: [38.6979, -9.2068], sticker: 'padrao' },
  { id: 'torre-belem', name: 'Torre de Belém', kind: 'Landmark', area: 'Belém', at: [38.6916, -9.216], sticker: 'belem' },
  { id: 'maat', name: 'MAAT', kind: 'Museum', area: 'Belém', at: [38.6957, -9.1946], sticker: 'caravel' },
  { id: 'castelo', name: 'Castelo de São Jorge', kind: 'Castle', area: 'Alfama', at: [38.7139, -9.1335], sticker: 'galo' },
  { id: 'santa-luzia', name: 'Miradouro de Santa Luzia', kind: 'Viewpoint', area: 'Alfama', at: [38.7118, -9.1302], sticker: 'azulejo' },
  { id: 'senhora-monte', name: 'Miradouro da Senhora do Monte', kind: 'Viewpoint', area: 'Graça', at: [38.7192, -9.1328], sticker: 'tram' },
  { id: 'feira-ladra', name: 'Feira da Ladra', kind: 'Flea market', area: 'São Vicente', at: [38.7158, -9.1268], sticker: 'galo' },
  { id: 'azulejo-museum', name: 'Museu Nacional do Azulejo', kind: 'Museum', area: 'Xabregas', at: [38.7247, -9.1137], sticker: 'azulejo' },
  { id: 'santa-justa', name: 'Elevador de Santa Justa', kind: 'Landmark', area: 'Baixa', at: [38.7121, -9.1394], sticker: 'tram' },
  { id: 'comercio', name: 'Praça do Comércio', kind: 'Square', area: 'Baixa', at: [38.7075, -9.1364], sticker: 'caravel' },
  { id: 'ginjinha', name: 'A Ginjinha', kind: 'Bar', area: 'Rossio', at: [38.7145, -9.1386], sticker: 'wings' },
  { id: 'manteigaria', name: 'Manteigaria', kind: 'Bakery', area: 'Chiado', at: [38.7106, -9.1437], sticker: 'nata' },
  { id: 'ramiro', name: 'Cervejaria Ramiro', kind: 'Seafood', area: 'Intendente', at: [38.7208, -9.1357], sticker: 'festival-sardine' },
  { id: 'tasca-chico', name: 'Tasca do Chico', kind: 'Fado', area: 'Bairro Alto', at: [38.7119, -9.1443], sticker: 'guitar' },
  { id: 'oceanario', name: 'Oceanário de Lisboa', kind: 'Aquarium', area: 'Parque das Nações', at: [38.7633, -9.0937], sticker: 'festival-sardine' },
  { id: 'gulbenkian', name: 'Museu Calouste Gulbenkian', kind: 'Museum', area: 'Avenidas Novas', at: [38.7372, -9.1545], sticker: 'padrao' },
];
export const placeById = (id: string) => LISBON_PLACES.find(s => s.id === id);

/** "12 min walk" from where I am, or for somewhere far (past 45 min), how far: "6.1 km away". */
export const walkLabel = (at: LatLng) => {
  const mins = walkMinutes(at);
  return mins <= 45 ? `${mins} min walk` : `${(metresBetween(ME_START, at) / 1000).toFixed(1)} km away`;
};

/** The trip's invite link: no account, they type a name and they're in. */
export const INVITE_LINK = 'tripup.app/j/lisbon-may';

// ---------- The dinner poll: where to eat tonight
// Maya asks at 2:30 PM; everyone votes from wherever they are. It closes at 3 PM, or as soon as everyone has voted,
// and the winner goes into tonight's 5 PM slot by itself (with Undo). Votes arrive on the demo clock, as they would
// from everyone's phones. All three are real places on Avenida da Igreja, with their public ratings and prices. The
// app keeps my vote and the Undo in its own state; here they're a `PollState` the story holds.

/** A point on the map: latitude, longitude. */
export type LatLng = readonly [lat: number, lng: number];

/** Where I start (the app's `me`). I leave for dinner at 4:30 PM, so during the poll I'm still here. */
export const ME_START: LatLng = [38.7478, -9.1475];

/** A walk: about 4.8 km/h, along streets about a third longer than a straight line (as in the app). */
const WALKING_METRES_PER_MINUTE = 80, STREET_DETOUR = 1.3;

/** Metres between two points, rounded to the metre: Vincenty on the WGS-84 ellipsoid, as the app's latlong2
 *  `Distance` does it. (Haversine comes out a metre long for Churrasqueira, enough to make its walk 18 min.) */
export const metresBetween = ([lat1, lng1]: LatLng, [lat2, lng2]: LatLng) => {
  const a = 6378137, b = 6356752.314245, f = 1 / 298.257223563;
  const rad = (d: number) => (d * Math.PI) / 180;
  const L = rad(lng2 - lng1);
  const u1 = Math.atan((1 - f) * Math.tan(rad(lat1))), u2 = Math.atan((1 - f) * Math.tan(rad(lat2)));
  const sinU1 = Math.sin(u1), cosU1 = Math.cos(u1), sinU2 = Math.sin(u2), cosU2 = Math.cos(u2);
  let lambda = L, lambdaP = 0, sinSigma = 0, cosSigma = 0, sigma = 0, cosSqAlpha = 0, cos2SigmaM = 0;
  for (let i = 0; i < 200; i++) {
    const sinLambda = Math.sin(lambda), cosLambda = Math.cos(lambda);
    sinSigma = Math.hypot(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
    if (sinSigma === 0) return 0;   // the same point
    cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
    sigma = Math.atan2(sinSigma, cosSigma);
    const sinAlpha = (cosU1 * cosU2 * sinLambda) / sinSigma;
    cosSqAlpha = 1 - sinAlpha * sinAlpha;
    cos2SigmaM = cosSqAlpha ? cosSigma - (2 * sinU1 * sinU2) / cosSqAlpha : 0;   // 0 along the equator
    const C = (f / 16) * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
    lambdaP = lambda;
    lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM ** 2)));
    if (Math.abs(lambda - lambdaP) <= 1e-12) break;
  }
  const uSq = (cosSqAlpha * (a * a - b * b)) / (b * b);
  const A = 1 + (uSq / 16384) * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
  const B = (uSq / 1024) * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
  const deltaSigma = B * sinSigma * (cos2SigmaM + (B / 4) * (cosSigma * (-1 + 2 * cos2SigmaM ** 2) - (B / 6) * cos2SigmaM * (-3 + 4 * sinSigma ** 2) * (-3 + 4 * cos2SigmaM ** 2)));
  return Math.round(b * A * (sigma - deltaSigma));
};

/** Walking minutes from where I am, the way the live statuses count them: 16, 17 and 17 to the poll's three. */
export const walkMinutes = (to: LatLng, from: LatLng = ME_START) => Math.ceil((metresBetween(from, to) * STREET_DETOUR) / WALKING_METRES_PER_MINUTE);

/** A place in the poll. `short` is what people call it, for notes ("La Brasserie"). */
export type PollOption = { id: string; name: string; short: string; sticker: string; rating: string; cuisine: string; price: string; at: LatLng };
export const POLL_OPTIONS: PollOption[] = [
  { id: 'brasserie', name: "La Brasserie de L'Entrecôte", short: 'La Brasserie', sticker: 'wings', rating: '4.2 (173)', cuisine: 'French', price: '€20–40', at: [38.754444, -9.140476] },
  { id: 'dote', name: 'Dote Alvalade', short: 'Dote', sticker: 'sardine-tin', rating: '3.9 (3,096)', cuisine: 'Portuguese', price: '€15–20', at: [38.7546, -9.13985] },   // Av. da Igreja 24
  { id: 'churrasqueira', name: 'Churrasqueira de Alvalade', short: 'Churrasqueira', sticker: 'galo', rating: '4.2 (156)', cuisine: 'Grill', price: '€5–10', at: [38.7547, -9.1393] },   // Av. da Igreja 23D
];
export const pollOptionById = (id: string) => POLL_OPTIONS.find(o => o.id === id)!;

/** The plan the poll decides: tonight's dinner, 5 PM. It isn't on the map or the itinerary until the poll has chosen. */
export const DINNER_SLOT_ID = 'brasserie';

export const POLL_OPENS = tripDate(TODAY, 14, 30), POLL_CLOSES = tripDate(TODAY, 15, 0);
export const POLL_ASKED_BY = 'maya';

/** The others' votes, as they come in. */
export type Vote = { who: string; option: string; at: Date };
export const POLL_VOTES: Vote[] = [
  { who: 'maya', option: 'brasserie', at: tripDate(TODAY, 14, 30) },
  { who: 'leo', option: 'churrasqueira', at: tripDate(TODAY, 14, 36) },
  { who: 'nic', option: 'brasserie', at: tripDate(TODAY, 14, 41) },
  { who: 'ren', option: 'brasserie', at: tripDate(TODAY, 14, 47) },
];

/** The poll as it stands on my phone: my vote and when I cast it (it can change until the poll closes), whether the
 *  winner going into tonight was undone, and then the place picked by hand. The app's `myVote`, `pollUndone` and
 *  `pickedDinner`. */
export type PollState = { mine?: { option: string; at: Date }; undone?: boolean; picked?: string };

/** Who has voted for `option` by `now`: the others in the order they voted, then me. */
export const votersOf = (option: string, now: Date, poll: PollState) => [
  ...POLL_VOTES.filter(v => v.option === option && v.at <= now).map(v => v.who),
  ...(poll.mine && poll.mine.option === option && poll.mine.at <= now ? [MY_ID] : []),
];

export const votesIn = (now: Date, poll: PollState) => POLL_OPTIONS.reduce((n, o) => n + votersOf(o.id, now, poll).length, 0);

/** Every vote cast by `now`, with when: the others', then mine. */
const votesBy = (now: Date, poll: PollState): Vote[] => [
  ...POLL_VOTES.filter(v => v.at <= now),
  ...(poll.mine && poll.mine.at <= now ? [{ who: MY_ID, option: poll.mine.option, at: poll.mine.at }] : []),
];

/** When the poll closes, as known at `now`: the moment the last person voted, if everyone at the table has by then;
 *  otherwise its deadline. It can't count votes that haven't come in yet. */
export const pollClosedAt = (now: Date, poll: PollState) => {
  const cast = votesBy(now, poll).map(v => v.at).sort((x, y) => x.getTime() - y.getTime());
  const last = cast[cast.length - 1];
  return cast.length >= DINNER_TABLE.length && last < POLL_CLOSES ? last : POLL_CLOSES;
};

export const pollOpen = (now: Date, poll: PollState) => now >= POLL_OPENS && now < pollClosedAt(now, poll);
export const pollClosed = (now: Date, poll: PollState) => now >= pollClosedAt(now, poll);

/** The option with the most votes. A tie goes to whichever reached that many first (the time of its latest vote). */
export const pollLeader = (now: Date, poll: PollState) => {
  const votes = votesBy(now, poll);
  let best: string | undefined, most = 0, reached = Infinity;
  for (const o of POLL_OPTIONS) {
    const times = votes.filter(v => v.option === o.id).map(v => v.at.getTime()).sort((x, y) => x - y);
    if (!times.length) continue;
    const at = times[times.length - 1];   // when it got to its count
    if (times.length > most || (times.length === most && at < reached)) [best, most, reached] = [o.id, times.length, at];
  }
  return best;
};

/** What tonight's dinner is, once decided: the poll's winner, unless that was undone and another picked by hand. */
export const dinnerChoice = (now: Date, poll: PollState) => (!pollClosed(now, poll) ? undefined : poll.undone ? poll.picked : pollLeader(now, poll));

/** "3 votes to 1", for the result. */
export const pollScore = (now: Date, poll: PollState) => {
  const counts = POLL_OPTIONS.map(o => votersOf(o.id, now, poll).length).sort((x, y) => y - x);
  return counts.length > 1 ? `${counts[0]} votes to ${counts[1]}` : `${counts[0]} votes`;
};

/** "closes in 19 mins": the whole minutes left, plus one (as the app counts it). */
export const pollCountdown = (now: Date, poll: PollState) => {
  const mins = Math.floor((pollClosedAt(now, poll).getTime() - now.getTime()) / 60000) + 1;
  return `closes in ${mins} ${mins === 1 ? 'min' : 'mins'}`;
};

/** The notes everyone on the trip gets: when the poll opens, and when it closes (with Undo). */
export const pollStartedLine = () => `${personById(POLL_ASKED_BY).name} started a poll: where for dinner tonight?`;
export const pollWonLine = (o: PollOption) => `${o.short} won · added to tonight`;

/** A place as tonight's plan: La Brasserie's own plan, a plain one for the others. */
export const pollOptionPlan = (o: PollOption): Plan => PLANS.find(p => p.id === o.id) ?? { id: o.id, name: o.name, sticker: o.sticker, day: TODAY, hour: DINNER.getHours() };

/** Every plan, in order, with tonight's dinner as decided: `undefined` leaves the plans as they stand at the demo's
 *  start (La Brasserie, as the poll chose); `null` takes tonight's slot out while it's undecided; an id puts that place
 *  in it (the app's `tripPlans`). */
export const plansWith = (dinner?: string | null) =>
  dinner === undefined
    ? PLANS
    : [...PLANS.filter(p => p.id !== DINNER_SLOT_ID || p.id === dinner), ...(dinner && dinner !== DINNER_SLOT_ID ? [pollOptionPlan(pollOptionById(dinner))] : [])]
        .sort((x, y) => planStart(x).getTime() - planStart(y).getTime());

// ---------- Your trips, and joining one
// The app opens on your trips; the one you're on goes into its map. Ren joins from the invite link with only a name,
// and sees the trip so far. The app's Demo moments "Your trips" (01) and "Ren joins" (03).

/** The Demo's moments: your trips at 2 PM, and Ren joining at 2:10 PM (before the poll opens). */
export const YOUR_TRIPS = tripDate(TODAY, 14, 0), REN_JOINS = tripDate(TODAY, 14, 10);

/** My own name, for what others see (in the app I'm "You"). */
export const MY_NAME = 'Ari';

/** Whether `p` is on the trip by `now` (Ren joins today at 2:10 PM). */
export const onTrip = (p: Pick<Person, 'joined' | 'joinedMinute'>, now: Date) =>
  p.joined < TODAY || (p.joined === TODAY && minuteOf(now) >= (p.joinedMinute ?? 0));

/** "5 PM" if it's today, else "Tomorrow, 10 AM" (the app's `Plan.startsAt`). */
export const startsAt = (t: Date, now = TRIP_NOW) => (dayName(t, now) === 'Today' ? clockTime(t) : `${dayName(t, now)}, ${clockTime(t)}`);

/** The plans not over yet at `now`, in order, with tonight's dinner as the poll stands (out while it's undecided). */
export const plansAhead = (now: Date, poll: PollState) =>
  plansWith(dinnerChoice(now, poll) ?? null).filter(p => planStart(p).getTime() + PLAN_LASTS_MS > now.getTime());

/** Another trip on the home list: where, when, a sticker, who (their stickers), and a line about it. `faceTilts`: how
 *  much each face leans, in degrees, by its place in `faces` (as they're placed in the design). */
export type TripSummary = { title: string; dates: string; sticker: string; faces: string[]; note: string; faceTilts?: number[] };

export const UPCOMING_TRIPS: TripSummary[] = [
  { title: 'Berlin', dates: '23 June - 23 July', sticker: 'brandenburg', faces: ['person-03', 'person-05'], note: 'In 6 weeks · 3 going', faceTilts: [0, -6.22] },
];

/** Done and settled. */
export const PAST_TRIPS: TripSummary[] = [
  { title: 'Mallorca', dates: 'Jan 24 - Feb 12', sticker: 'windmill', faces: ['person-02', 'person-03', 'person-04'], note: '€960 · squared up' },
  { title: 'Tokyo', dates: 'Oct 3 - Oct 14', sticker: 'sushi', faces: ['person-04', 'person-05', 'person-02'], note: '€1,840 · squared up' },
  { title: 'Hanoi', dates: 'Mar 8 - Mar 15', sticker: 'pho', faces: ['person-04', 'person-01'], note: '€610 · squared up' },
];

/** The current trip's card on Your trips (Figma 75:5927): a still of Lisbon, far bigger than the card and placed so the
 *  neighbourhoods we've been in show, with a few of the places on it as stickers. In the design's units (px): the card
 *  covers a HOME_MAP_FRAME box (scaled to fill the real card); the image's rect and each sticker's centre, height and
 *  tilt (degrees) are placed in it. */
export const HOME_MAP_FRAME = { width: 361, height: 438 };
export const HOME_MAP_IMAGE = '/assets/map/home-lisbon.png';
/** Only the part of the still the card shows (and 2 px around it), as in the app: the design placed the whole
 *  3584 × 2048 still at (-634, -343, 1792 × 1024) (original: Assets/map/home-lisbon-full.png). */
export const HOME_MAP_IMAGE_RECT = { left: -2, top: -2, width: 365, height: 442 };
export const HOME_MAP_STICKERS = [
  { sticker: 'belem', x: 324.5, y: 29, height: 38, tilt: 0 },
  { sticker: 'galo', x: 236.26, y: 65.85, height: 26.25, tilt: 11.86 },
  { sticker: 'azulejo', x: 330, y: 90, height: 16, tilt: 0 },
  { sticker: 'caravel', x: 228.07, y: 129.65, height: 23.55, tilt: 0 },
];
