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
 * `joined` is the day they joined the trip: costs from before it aren't theirs.
 */
export type Person = { id: string; name: string; sticker: string; status: string; going: boolean; joined: number; leaves: number; arrives: number };
type Walker = Omit<Person, 'status'>;
/** The group, on their way to dinner (17:00): Maya is there, Nic is on his way, Leo leaves at 16:16, and Ren (who
 *  joined today) and I leave at 16:30. */
const CREW: Walker[] = [
  { id: 'ari', name: 'You', sticker: 'person-04', going: true, joined: 12, leaves: 16 * 60 + 30, arrives: 16 * 60 + 52 },
  { id: 'maya', name: 'Maya', sticker: 'person-01', going: true, joined: 12, leaves: 15 * 60 + 28, arrives: 15 * 60 + 46 },
  { id: 'nic', name: 'Nic', sticker: 'person-05', going: true, joined: 12, leaves: 15 * 60 + 48, arrives: 16 * 60 + 4 },
  { id: 'leo', name: 'Leo', sticker: 'person-02', going: true, joined: 12, leaves: 16 * 60 + 16, arrives: 16 * 60 + 36 },
  { id: 'ren', name: 'Ren', sticker: 'person-03', going: true, joined: TODAY, leaves: 16 * 60 + 30, arrives: 16 * 60 + 48 },   // joined mid-trip, today
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

/** Dinner, the Up next plan. */
const DINNER = new Date(2026, 4, 14, 17, 0);

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

export const TRIP = { title: 'Schmedeswurtherwesterdeich', dates: '12 May - 21 May' };

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

/** Dinner is on: its time has come (from a quarter of an hour before, for the three hours it lasts) and someone is
 *  there (inside the geofence). Nobody presses anything for it; it's where people are and the time. */
export const isActive = (now: Date) =>
  now.getTime() >= DINNER.getTime() - 15 * 60000 && now.getTime() < DINNER.getTime() + 3 * 3600000 && CREW.some(p => isHere(p, now));

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

/** Planned, in order. The first one is Up next. */
export type Plan = { id: string; name: string; sticker: string; day: number; hour: number };
export const PLANS: Plan[] = [
  { id: 'brasserie', name: EVENT.name, sticker: EVENT.sticker, day: TODAY, hour: 17 },
  { id: 'croissants', name: 'Sam Croissants', sticker: 'nata', day: TODAY, hour: 18 },
  { id: 'tram', name: 'Tram 28 ride', sticker: 'tram', day: 15, hour: 10 },
  { id: 'sail', name: 'Sail on the Tagus', sticker: 'caravel', day: 16, hour: 18 },
  { id: 'fado', name: 'Fado at Tasca do Chico', sticker: 'guitar', day: 17, hour: 21 },
  { id: 'oceanario', name: 'Oceanário', sticker: 'festival-sardine', day: 18, hour: 11 },
  { id: 'tiles', name: 'Tile Museum', sticker: 'azulejo', day: 19, hour: 10 },
];
export const planStart = (p: Plan) => tripDate(p.day, p.hour);

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

/** The trip's invite link: no account, they type a name and they're in. */
export const INVITE_LINK = 'tripup.app/j/lisbon-may';
