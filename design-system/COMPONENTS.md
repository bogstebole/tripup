# TripUp components

Generated from design-system/components.json by design-system/build-components-doc.mjs. Don't edit by hand.

Every component the Figma screens are built from: 93 entries on the page Components (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=143-83), one section each.
The Flutter app (app/lib) is the source of truth; each component is drawn 1:1 from its widget.

## How to read it

- Name: the component's name in Figma, also the name of its section and its docs card.
- Figma: node id, component key, and the property API exactly as Figma has it (`Name=value|value` for variants; text, boolean and instance swap properties in brackets).
- Props: how the Figma properties map to the code's parameters (`Kind → kind`).
- Code: the widget and its file. Swift for the Live Activity and the notification.
- Tokens: every colour, size and space is a variable made from design-system/tokens.json; in Figma its code syntax is the CSS variable (`var(--c-button-soft-bg)`), the same token as TokColors and TokDim in Dart. The tokens each component uses are listed in its Figma description.
- Screens are instances of these components: change the component, never a copy on a screen.

## Index

- Buttons: Button, Text button, Add button
- System: Status bar, Home indicator
- Your trips: Trip card, Trip still / Lisbon, Happening now, Trip row, Avatar button, Splash mark
- Map: Top bar, Toggle chip, Demo button, Action bar, Crew button, Plan pin, Up next card, Mini pin, Pin tail, Edge pin, Edge arrow, Info chip, Rating line, Face pile, Me marker
- Scenes: Scene / Trip map · 2:10 PM, Scene / Trip map · 2:30 PM, Scene / Trip map · 3:00 PM, Scene / Trip map · 3:56 PM, Scene / Trip map · plan sent, Scene / Trip map · 5 PM, Map / Lisbon today, Map / Lisbon · Gulbenkian
- Full view: Sheet header, Segmented tabs, Segment, Page title, Photo carousel, Know tip, Fact row, Menu row, Dish sticker, Person row, More picks, Hairline
- Pop-ups: Pop-up header, Sheet footer, Sheet section, Sheet row, Icon row, Day heading, Tag, Segmented tabs / wide, Owe pill, Payment row, Why, Money footer, Add choice, Search field, Place map, Time row, Link pill, Text field, Phone pill, Toast, Pay amount, Pay line, Bank logo
- Poll: Poll card, Poll place, Vote bar, Live dot
- Bill: Scan frame, Receipt, Bill line, Share, Payer
- Paying: Face ID, Bank approval
- Live Activity: Live Activity, Activity place, Activity mark, Activity bar, Island / compact, Island / expanded, Notification, Notification actions, App icon, Wallpaper
- Assets: Icon set, Sticker library, Photo set

## Buttons

The raised bodies people tap. Soft for most actions, primary (brand blue) for the one main action on a screen.

### Button

Round icon button: every icon-only action in TripUp (back, close, add, the arrow into a trip).

- Use: When the icon alone says the action. Kind=primary only for the one main action on a screen. States: Kind=soft|primary × Size=sm|md|lg, all six. Pressed has no look of its own: the whole button scales to 0.97 (press-scale) while held.
- Avoid: Actions that need words: use Text button.
- Props: Kind → kind (GlassKind.soft | primary) · Size → size (TuButtonSize sm 40 | md 44 | lg 56) · Icon → icon (a TuIcons entry). Code also takes label (read by screen readers) and onTap.
- Code: TuButton · app/lib/components/glass.dart
- Storybook: Components/Button
- Figma: node 93:1579 · key 78bc87d2d8d1fb1582876f9415e423fae99a33c4 · properties: Icon (instance swap), Kind=soft|primary, Size=sm|md|lg (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=143-159)

### Text button

Pill button with a label and an optional icon before it, for actions an icon can't say: Pay, Copy link, Send to the group.

- Use: Set the instance's width to Fill for the main action at the bottom of a page (wide: true in code). States: Kind=soft|primary × Size=sm|md|lg, with or without the icon, hugging its label or set to Fill. Pressed has no look of its own: the whole button scales to 0.97 (press-scale) while held.
- Avoid: Icon-only actions: use Button.
- Props: Label → label · Show icon + Icon → icon (null hides it) · Kind → kind (code default is primary) · Size → size · Fill width → wide: true.
- Code: TuTextButton · app/lib/components/glass.dart
- Storybook: Components/Button
- Figma: node 93:1610 · key baee38d2dad6bb8d4eb75a25df008660e12b692a · properties: Label (text), Show icon (boolean), Icon (instance swap), Kind=soft|primary, Size=sm|md|lg (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=143-235)

### Add button

Small round toggle on a menu row: a plus in soft glass, a check in primary glass once the dish is added. One tap toggles it.

- Use: Only on Menu row. The 32 circle sits in a 44 touch target.
- Props: Added=no|yes → added. Code also takes itemName (for the screen reader: Add … to your picks) and onTap.
- Code: AddButton · app/lib/components/glass.dart
- Figma: node 106:1952 · key 36d410b468906d2908bdfa241d3a3efeff779f4e · properties: Added=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=143-273)

## System

iOS's own parts of the screen, drawn so the frames read as a real iPhone. Not built by the app.

### Status bar

iOS status bar: 9:41, signal, wifi, battery. At the top of every screen frame.

- Props: Content=dark (over light screens) | light (over the blue or dark screens).
- Code: System UI (iOS), not in the app's code.
- Figma: node 95:1484 · key fd4a731db1402778955765fe659ffdedcdfd5d48 · properties: Content=dark|light (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-698)

### Home indicator

iOS home indicator at the bottom of every screen frame.

- Props: Content=dark | light, like Status bar.
- Code: System UI (iOS), not in the app's code.
- Figma: node 95:1489 · key 714a1d5ca6a930263e8ac016ec2da3229e38f761 · properties: Content=dark|light (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-750)

## Your trips

The home screen: every trip, the one that's on as a big card.

### Trip card

The trip you're on, the big card on Your trips: the city still with stickers, Happening now, the trip's name, city and dates, who's on it, and the arrow in. Tapping anywhere opens the trip.

- Props: Title → the trip's name (one line, ends in …) · City and dates.
- Code: _CurrentTrip, TripCardFace · app/lib/components/home.dart
- Storybook: Screens/Trip
- Figma: node 96:1448 · key bd6b333bd054d2c658156caceeb5531b312e341c · properties: Title (text), City and dates (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-803)

### Trip still / Lisbon

The picture on the Trip card: the city's still with its landmark stickers. The app scales it to cover the card, top centre.

- Code: TripCardStill · app/lib/components/home.dart
- Figma: node 95:1497 · key 09b47a422138fecdc2d86a62f94c521a5dfee1c1 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-824)

### Happening now

Small glass pill with a green dot: the trip is on right now. Sits on the Trip card.

- Code: _HappeningNow · app/lib/components/home.dart
- Figma: node 95:1494 · key 42e811b963eb7ecf259068ba19014ed7656edfde (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-836)

### Trip row

Another trip on Your trips (coming up or past): its sticker, name, dates, and who went as faces on the row's edge.

- Props: Title · Dates · Place (the trip's sticker) · Third face (shows a third face).
- Code: _TripRow · app/lib/components/home.dart
- Figma: node 96:1475 · key b515fd0221741494cabaee43bc009cbfec1a7359 · properties: Title (text), Dates (text), Place (instance swap), Third face (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-891)

### Avatar button

Me: my sticker in a soft glass circle, top right of Your trips.

- Props: Sticker → my face.
- Code: TripsHome · app/lib/components/home.dart
- Figma: node 95:1492 · key 58299270ce357d26ef6de654cc201ffd2cdf9630 · properties: Sticker (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-910)

### Splash mark

The splash's mark on a cold start: my dot (the app icon's motif, four times the map's, with its ring) and TripUp in the display face, centred on Your trips' blue.

- Use: Step=dot while the dot pops in (TripUp is there but not yet showing, so the dot sits where it ends up); Step=word once TripUp has come in; in the app the dot's blue then breathes like my location on the map. Small stickers pop up at random spots all over the screen and pop away again (Sticker instances, splash/sticker high); then the dot and TripUp slide out to the left (splash/slide) as Your trips slides in from the right.
- Props: Step=dot|word.
- Code: Splash · app/lib/components/splash.dart
- Figma: node 159:6442 · key c96ff46358b0776facdb6a3728f2adb0faf06b7a · properties: Step=dot|word (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=159-6443)

## Map

Everything on and over the trip map.

### Top bar

The trip's header over the map: back, the trip's name and dates, Demo, then the day chips. The map fades out under it.

- Props: Title → title · Dates → dates. The day chips are Toggle chip instances.
- Code: TopBar · app/lib/components/bars.dart
- Figma: node 98:1555 · key 319136ee9dc1bf6cc159625e562741220123ea5f · properties: Title (text), Dates (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1168)

### Toggle chip

One toggle in a row of toggles (the trip's days on the map, the menu's courses): flat when off, primary glass when on.

- Use: In a row: All first, then one per option. Options combine; with none picked, All is on. The row scrolls sideways.
- Props: Label → label · On=no|yes → on.
- Code: ToggleChips, ToggleChip · app/lib/components/toggle_chips.dart
- Figma: node 98:1549 · key f78dc71271cc597ff51595d653e84d3340db5b90 · properties: Label (text), On=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1205)

### Demo button

Demo only, not part of the product: the demo's clock. Tapping it lists the story's moments to jump between.

- Props: Label → time (Demo · 3:56 PM).
- Code: DemoButton · app/lib/components/bars.dart
- Figma: node 98:1550 · key 62b2d6f8a0852069a950a79945ab90cbd9d56d04 · properties: Label (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1226)

### Action bar

The trip's three actions at the bottom of the map: Itinerary, Money (the group as a pile) and Add (the one primary). A white fade lifts them off the map.

- Code: ActionBar · app/lib/components/bars.dart
- Figma: node 98:1599 · key eb6cf44602c37fb148c60645ddc42cecb7e2884e (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1346)

### Crew button

The Money button: the whole group piled up on a soft glass circle. Opens Money. Built like Bogdan's buttons: the glass body sits behind the faces, which may spill over its edge.

- Code: _CrewButton · app/lib/components/bars.dart
- Figma: node 98:1592 · key 3fc35b7d3135177491ea3ab726b6fa5934b55943 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1361)

### Plan pin

A plan pinned to its place: the Up next card (mid) or the Mini pin, over the Pin tail. The bottom of the dash is the map point. In the app it is one surface that morphs between mid, mini and edge with springs.

- Props: Size=mid|mini.
- Code: PlanPin · app/lib/components/plan_pin.dart
- Storybook: Widget/Up next
- Figma: node 100:1702 · key f6f84386ed0f21d601117b3f78ead70656444d31 · properties: Size=mid|mini (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1594)

### Up next card

The next plan on the map: when, the place's name and rating, its fan of dishes, who's coming (or who's here) and the price, and the arrow into the full view.

- Props: When · Name · Now (the dinner is on: Now · You're here).
- Code: UpNextMid · app/lib/components/plan_pin.dart
- Storybook: Widget/Up next
- Figma: node 100:1611 · key bf11369004d2deedb9d2621676a91a83c59d471f · properties: When (text), Name (text), Now (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1615)

### Mini pin

A plan's small pin on the map: its sticker, name and when. Whoever is already there sits on the middle of its top edge, lifted widget/here-lift (10) off it, as a Face pile (chip size).

- Props: Name · When · Sticker.
- Code: _MiniContent (PlanPin, mini) · app/lib/components/plan_pin.dart
- Figma: node 100:1645 · key eaef061afb86579a911e952010a1d1696335a097 · properties: Name (text), When (text), Sticker (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1636)

### Pin tail

The blue tail under a pin, and the dash that marks the exact spot. The dash's bottom is the map point.

- Props: Size=mid|mini.
- Code: PinTail · app/lib/components/map_shapes.dart
- Figma: node 100:1658 · key 035ad83705a9eb59d61bf56eefc544923b4d6427 · properties: Size=mid|mini (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1654)

### Edge pin

A plan that's off-screen: its sticker in a small round surface on the screen's edge, with an Edge arrow beside it.

- Props: Sticker.
- Code: PlanPin (edge) · app/lib/components/plan_pin.dart
- Figma: node 100:1706 · key 64e90027f7416355a3e0e50d4b1b07605266383f · properties: Sticker (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1678)

### Edge arrow

Small blue triangle pointing at an off-screen place. Drawn pointing down: rotate the instance toward the place.

- Code: EdgeArrow(angle) · app/lib/components/map_shapes.dart
- Figma: node 100:1703 · key f809320bedc09e1db8e97346986903e750c26598 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1708)

### Info chip

One fact in a joined row of facts about a plan: who's coming or who's here, the price. Chips sit 2 px apart; only the row's outer corners are rounded.

- Props: Text · Faces, Face 2–4 (faces before the text) · Position=first|middle|last|only (which corners are rounded).
- Code: InfoChips(items) · app/lib/components/basics.dart
- Figma: node 100:1610 · key 07ae8dcef69f2b0bf6c10081ad74a3174c003895 · properties: Text (text), Faces (boolean), Face 2 (boolean), Face 3 (boolean), Face 4 (boolean), Position=first|middle|last|only (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1723)

### Rating line

A place's rating: a filled brand star, the rating and review count, then the place's type.

- Props: Rating → rating · Kind → kind.
- Code: RatingLine · app/lib/components/basics.dart
- Figma: node 100:1575 · key 84ff04c4b413df8208668d9738779dbcee33889c · properties: Rating (text), Kind (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1747)

### Face pile

People as a little pile: up to two stickers, then a +N bubble. On the map: someone walking, or a group together.

- Props: Count (the +N) · More (shows the bubble) · Second face.
- Code: FacePile(faces) · app/lib/components/basics.dart
- Figma: node 100:1708 · key 639b51ed94669c8cefbbdeb6991e0f03ea17d4cf · properties: Count (text), More (boolean), Second face (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1783)

### Me marker

My location: the blue dot with a white rim, and a soft cone toward where I face (rotate the Cone layer around the centre). In the app the blue slowly breathes.

- Code: MeMarker(heading) · app/lib/components/map_shapes.dart
- Figma: node 100:1713 · key fe0c4faf9c7be45aec0547cb1ac45901614a7541 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=144-1825)

## Scenes

The whole trip map at each moment of the story, built from the Map components. Every sheet and pop-up of that moment sits on one of these.

### Scene / Trip map · 2:10 PM

The trip map at 2:10 PM (Ren joins): nobody is out yet and dinner isn't decided, so there is no Up next.

- Use: Change the scene, never a screen's copy of it: every screen of that moment is an instance.
- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 116:3859 · key f93c4eb059e5ba0ebe21f8715cdfc6340530aff6 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-536)

### Scene / Trip map · 2:30 PM

The trip map at 2:30 PM (the dinner poll is open): nobody is out yet and there is no Up next until the poll closes. The Poll card sits on top of it in the screens.

- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 121:4528 · key 3f61b7efcd92dd2824ddca5b2faba345969731f6 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-814)

### Scene / Trip map · 3:00 PM

The trip map at 3:00 PM: the poll has closed, La Brasserie is Up next, and nobody has left yet.

- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 121:4589 · key adb6ac00f924c13596aea92f31c7a0f17b08d64b (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-1027)

### Scene / Trip map · 3:56 PM

The trip map at 3:56 PM, the app at launch: people walking to dinner, Up next La Brasserie at 5 PM, the bars and the map credit.

- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 104:1863 · key b29336192ff750b811e2c0907f5e7b913175bdfd (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-2457)

### Scene / Trip map · plan sent

The trip map at 3:56 PM just after sending a plan from Add: the camera has flown to Museu Calouste Gulbenkian and its Mini pin is on the map.

- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 128:7250 · key 292a49c90e1942daab720113ad86226632e26e5c (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-2718)

### Scene / Trip map · 5 PM

The trip map at 5 PM: the dinner is on (Now · You're here) and everyone is at the table, me included.

- Code: TripScreen · app/lib/screens/trip_screen.dart
- Figma: node 125:5326 · key 58b3cf40b6aae42240f396876a92e12fdbe94d68 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3681)

### Map / Lisbon today

The bare map at today's camera (Thu 14, zoom 14.1 around 38.7591, -9.1405): the background of the scenes. Drawn by the app's own tiles; keep the map credit visible.

- Code: TripTileLayer · app/lib/components/map_tiles.dart (image made by app/perf/figma_map.dart)
- Figma: node 100:1718 · key 5398844ecd0d65270a64c9d9614b79cfd1cf42e3 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3699)

### Map / Lisbon · Gulbenkian

The bare map after flying to a plan sent from Add (Museu Calouste Gulbenkian at the centre, zoom 14.1).

- Code: TripTileLayer · app/lib/components/map_tiles.dart (image made by app/perf/figma_map.dart)
- Figma: node 128:7248 · key 0a42a5cabd24a7ef493c5e48183c49a812e7037f (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3714)

## Full view

A plan's full view (Overview, Menu, Group): what opens from Up next.

### Sheet header

The full view's header: the Overview, Menu and Group tabs, and Close. The page scrolls up under it.

- Props: Selected=1|2|3 (Overview, Menu, Group).
- Code: DetailSheet · app/lib/components/detail_sheet.dart
- Storybook: Screens/Trip
- Figma: node 105:1966 · key 0e22c796699067c431ca1ec58ef250b7c4761861 · properties: Selected=1|2|3 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3824)

### Segmented tabs

Tabs on a muted track. Each tab replaces the page under it; the picked one rides on a raised white pill that springs to it.

- Props: Selected=1|2|3 → index. Set the labels on the nested Segments.
- Code: SegmentedTabs(tabs, index, onChanged) · app/lib/components/segmented_tabs.dart
- Figma: node 105:1923 · key 952e071fec1111b9c4926e61b1d30b2277de2eff · properties: Selected=1|2|3 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3845)

### Segment

One tab of Segmented tabs: its label, on the raised pill when picked.

- Props: Label · On=no|yes.
- Code: SegmentedTabs · app/lib/components/segmented_tabs.dart
- Figma: node 105:1901 · key 8f42a4826e020b17bc80f51b5940d58d7b11a65e · properties: Label (text), On=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3872)

### Page title

A page's title and the line under it: the place's name on Overview, the titles of Menu and Group.

- Props: Title · Subtitle.
- Code: _PageTitle · app/lib/components/detail_sheet.dart
- Figma: node 105:1967 · key afe9c393664045c778fb150b5fc463d0901300bb · properties: Title (text), Subtitle (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3898)

### Photo carousel

The place's photos as Material 3's multi-browse carousel at rest: a large photo, a medium (62 wide with its gap) and a small one (36).

- Code: _PhotoCarousel · app/lib/components/detail_sheet.dart
- Figma: node 105:1970 · key db7a0f3d4c71ef51a06d4b91d5c51a465dfdaa25 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3919)

### Know tip

A tip inside Know before you go: a short brand line on a muted block. Read, not tapped, so no arrow and no glass.

- Props: Tip → text.
- Code: KnowTip, KnowSection · app/lib/components/basics.dart
- Figma: node 105:1977 · key 0cb764fcb8027fd7e551eee0ea626fdea3c3f4c3 · properties: Tip (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-3937)

### Fact row

One fact from the place's Google Maps card: icon, the line (a status such as Open in green), and a smaller line under it.

- Props: Icon · More + Has more (the smaller line).
- Code: _FactRow · app/lib/components/detail_sheet.dart
- Figma: node 105:1979 · key a304d977a4e226ca1501ea6db1db6d3d77a86814 · properties: More (text), Has more (boolean), Icon (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4005)

### Menu row

One dish of the real menu: its photo as a sticker, name and description; the price, who else picked it, and Add. Rows alternate the sticker's tilt.

- Props: Name · Note + Has note · Price · Picked (Add shows the check) · Second face, Third face · Tilt=left|right.
- Code: _MenuRow · app/lib/components/detail_sheet.dart
- Figma: node 109:2341 · key 6542b8d95d95b3c0033d4ca214b217ca11a730c9 · properties: Name (text), Note (text), Has note (boolean), Price (text), Picked (boolean), Second face (boolean), Third face (boolean), Tilt=left|right (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4095)

### Dish sticker

A dish photo as a die-cut sticker: white edge, soft shadow, tilted ±3° in lists.

- Props: Size=menu (64, Menu row) | pick (32, a person's picks).
- Code: DishSticker · app/lib/components/basics.dart
- Figma: node 106:1939 · key 051820d0c423dd34ef829310b274e33482314005 · properties: Size=menu|pick (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4117)

### Person row

Someone on the trip, in Group: their face, where they are (worked out live), what they picked as a pile of dish stickers, and roughly what it comes to.

- Props: Name · Status · Cost · Face · Second pick · More picks.
- Code: _PersonRow · app/lib/components/detail_sheet.dart
- Figma: node 106:1972 · key 0d8d941497756ce2dc6471b59702583d5b13b6c9 · properties: Name (text), Status (text), Cost (text), Second pick (boolean), More picks (boolean), Face (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4371)

### More picks

The rest of a person's picks as one more sticker on the pile: +N.

- Props: Count.
- Code: _MorePicks · app/lib/components/detail_sheet.dart
- Figma: node 106:1940 · key f86aa75dbee254580006169f67e5c5a1e9820e53 · properties: Count (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4389)

### Hairline

A 1 px divider between rows of a list, inset to the rows' text.

- Code: Hairline · app/lib/components/basics.dart
- Figma: node 105:1986 · key 78591fa9ed710fe65eb3f18677096979fd19bc21 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=145-4458)

## Pop-ups

The footer's pop-ups: Itinerary, Money, Add (Plan something, Invite someone), and what Ren sees when he joins.

### Pop-up header

A pop-up's header, one line everywhere: Back (for a step inside it), its title and Close, on the buttons' centre line. The pop-up's line on what it's for opens its page (an Intro text), and its actions are in a Sheet footer. The page scrolls up under the header; the header is also the handle to drag it down.

- Props: Title · Back=no|yes.
- Code: TripSheet · app/lib/components/trip_sheet.dart
- Storybook: Pop-ups
- Figma: node 110:2813 · key c1ba4e00d44a14abab10af368306d4104cf96e55 · properties: Title (text), Back=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-903)

### Sheet footer

A pop-up's bottom, in view while its page scrolls: its actions over a hairline, one wide button, or two stacked, and a line under them if they need one. Every pop-up's actions are here; going back and closing are in the Pop-up header.

- Use: Plan something's Send to the group (with its note); Invite someone's Copy link. Two stacked actions when a pop-up needs them (Second action). Money's footer is the same bottom with the total above the button.
- Props: Primary, Secondary (nested Text buttons: Label, Show icon, Icon) · Second action (boolean) · Note shown + Note.
- Code: SheetFooter · app/lib/components/trip_sheet.dart
- Figma: node 165:6603 · key a86b3191539729790022b81402c1c22703b7e07f · properties: Second action (boolean), Note shown (boolean), Note (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=165-6616)

### Sheet section

A heading inside a pop-up's page, with an optional line under it (space/lg or space/xl above it).

- Props: Title → title · Subtitle + Has subtitle → subtitle.
- Code: SheetSection · app/lib/components/trip_sheet.dart
- Figma: node 110:2821 · key 92556b2e608e649c31802b76cf71005c06189527 · properties: Title (text), Subtitle (text), Has subtitle (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-944)

### Sheet row

One line in a pop-up's list: a sticker, a name (up to two lines), a line under it (brand for Up next), and what sits at the end: a time, an arrow, a button, or nothing.

- Props: Title → title · Subtitle → subtitle · Subtitle color=muted|brand → subtitleColor · End · Sticker → leading · Sticker shown (off for a picked place, whose sticker is on the map above) · Trailing=time|arrow|button|none → trailing.
- Code: SheetRow · app/lib/components/trip_sheet.dart
- Figma: node 110:2890 · key 7a6cc965ca8f256ec7571317104ec4d221560b06 · properties: Title (text), Subtitle (text), End (text), Sticker (instance swap), Sticker shown (boolean), Trailing=time|arrow|button|none, Subtitle color=muted|brand (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1069)

### Icon row

A Sheet row with an icon instead of a sticker: the trip so far in Join (where they're staying, dinner tonight).

- Props: Title · Subtitle · Subtitle color=muted|brand · Icon.
- Code: JoinFlow · app/lib/components/join.dart
- Figma: node 116:3998 · key 7d3792a57e53a3bc1ac96382d709881d752abc03 · properties: Title (text), Subtitle (text), Icon (instance swap), Subtitle color=muted|brand (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1112)

### Day heading

A day in Itinerary: the day's name, its number in the trip, and the Today tag on today.

- Props: Day · Number · Today.
- Code: ItineraryPage · app/lib/components/trip_pages.dart
- Storybook: Itinerary
- Figma: node 110:2816 · key de06bae695a0a4e06b6990c49623962133f28c59 · properties: Day (text), Number (text), Today (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1147)

### Tag

A small brand pill next to a heading or a name: Today, Won, Tonight.

- Props: Label.
- Code: _Tag · app/lib/components/trip_pages.dart, PollTag · app/lib/components/poll.dart
- Figma: node 110:2814 · key 455a4a151f208cc2fa3728029974c9994c089ccc · properties: Label (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1168)

### Segmented tabs / wide

Segmented tabs that fill the width: Money's Settle up, Balances, Expenses.

- Props: Selected=1|2|3 → index.
- Code: SegmentedTabs(wide: true) · app/lib/components/segmented_tabs.dart
- Figma: node 111:2823 · key 13fb1cfac4b8f143d938b02a26210dea34c05886 · properties: Selected=1|2|3 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1219)

### Owe pill

What I owe and Pay, while I owe it, at the bottom of Money just above its footer (where the thumb reaches). Pay opens paying it (Pay Maya). While it's on its way the line and the end change over: paying (my bank is confirming: a spinner) or waiting (marked as paid, waiting for them to confirm: a clock). Once it's paid it goes: the note at the top is the success.

- Props: Label · Amount · State (owe, paying, waiting).
- Code: OwePill · app/lib/components/trip_pages.dart
- Storybook: Money, Money · pay, Bank app
- Figma: node 123:5316 · key 3ffbc217e3e6fe29f00bf2485e1fa97ff76b2e2a · properties: Label (text), Amount (text), State=owe|paying|waiting (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1269)

### Payment row

One payment in Settle up: who pays whom (their faces), Pending or Paid (green) and Why, and the amount.

- Props: Title · Status (the line under it: Pending · Why) · State=pending|paid (Paid turns the line green) · Amount.
- Code: MoneyPage · app/lib/components/trip_pages.dart
- Storybook: Money
- Figma: node 123:5330 · key 28db45fc3fa9b38465c0ded01b908c2037d0a4cd · properties: Title (text), Status (text), Amount (text), State=pending|paid (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1486)

### Why

Why a payment is what it is: the payer's share of each expense, what they paid, and why it all goes to one person. Opens under its Payment row.

- Code: MoneyPage · app/lib/components/trip_pages.dart
- Figma: node 123:5331 · key 8c0cf6d68ed420a9eb8f396065610e2b9432d5a5 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1541)

### Money footer

Money's bottom, always in view: what the trip has cost so far and my part of it; Scan the bill under it while the dinner is on and its bill isn't in.

- Props: Title · Detail · Amount · Scan the bill (shows the button).
- Code: MoneyFooter · app/lib/components/trip_pages.dart
- Figma: node 111:2856 · key c05abf598c9c0029659406107630e32ed36c983b · properties: Title (text), Detail (text), Amount (text), Scan the bill (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1580)

### Add choice

One of Add's two choices (Plan something, Invite someone): a big title, a line on it, and an arrow. No box around it.

- Props: Title · Line.
- Code: _Choice · app/lib/components/trip_pages.dart
- Figma: node 111:2872 · key 05e14bc84287f8e2da19d18eb05a978d58e589c7 · properties: Title (text), Line (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1624)

### Search field

Find a place, in Plan something.

- Props: Query (the placeholder or what's typed).
- Code: AddPage · app/lib/components/trip_pages.dart
- Figma: node 111:2879 · key 4e9bc6eb375eeab55e168f76119b3cd5f72c3a3a · properties: Query (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1648)

### Place map

A place on a small map (zoom 15.5 around it, the app's tiles), its sticker in the middle, and the map credit: a place picked in Add, or a plan without photos.

- Props: Place=Gulbenkian|Tram 28.
- Code: AddPage, DetailSheet (mapOf) · app/lib/components/trip_pages.dart
- Figma: node 113:3691 · key 1c582817402eba70299fad362d83ae718f1a72a0 · properties: Place=Gulbenkian|Tram 28 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1669)

### Time row

From or To in Plan something's When step: the label and the time.

- Props: Label · Time.
- Code: AddPage · app/lib/components/trip_pages.dart
- Figma: node 111:2884 · key 64f9d7ebeddf7c61e17fbfe12d2220030115a6a0 · properties: Label (text), Time (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1691)

### Link pill

The invite link, alone in a muted pill as tall as a big button, in Invite someone. Copy link is in the pop-up's Sheet footer.

- Props: Link.
- Code: AddPage · app/lib/components/trip_pages.dart
- Figma: node 111:2833 · key 624e703ae5a595f8294e0d75fed9b1b9c9d9abe9 · properties: Link (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1720)

### Text field

A text input on a muted pill: Ren's name when he joins (no account, no password).

- Props: Value.
- Code: JoinFlow · app/lib/components/join.dart
- Figma: node 116:3999 · key 219eba4efcaae42c524e7dc80cd0de0d10cb3ab6 · properties: Value (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1739)

### Phone pill

Marks a screen as someone else's phone (Ren's phone) in the Join flow. A board label for the story, not app UI.

- Props: Label.
- Figma: node 116:3976 · key 0c5590987178d50cab76c4d31d553dd151c927d8 · properties: Label (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1759)

### Toast

A short note for everyone, down from the top under the status bar: a flat brand pill (not glass, so it never reads as a button), a check, the line, and Undo when there is one.

- Props: Label → label · Action=no|yes → actionLabel (Undo).
- Code: Toast · app/lib/components/toast.dart
- Figma: node 114:3693 · key f2600c07b75780baaeccef3d04bbecd48276bea3 · properties: Label (text), Action=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=146-1799)

### Pay amount

Who I pay and how much, big, at the top of Pay Maya: their sticker, the amount (Display) and "to Maya", centred, space/xl above what the transfer will say.

- Use: Pay Maya only.
- Props: Amount · To · Sticker (instance swap: the person's sticker).
- Code: PayPage · app/lib/components/trip_pages.dart
- Storybook: Money · pay
- Figma: node 176:6552 · key 9a06b20501b8fc33f757d80644bce4ecbe757a70 · properties: Amount (text), To (text), Sticker (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=176-6607)

### Pay line

One line of what the transfer will say (To, From, Reference, Arrives), in Pay Maya's muted box: the label on the left, the value at the end; Tap=yes adds an arrow when a tap changes it (From: pick another bank).

- Use: Inside Pay Maya's muted box (bg/muted, radius/card, space/sm across, space/2xs down, inset space/xs like Why's).
- Props: Label · Value · Tap (no, yes → onTap).
- Code: _PayLine · app/lib/components/trip_pages.dart
- Storybook: Money · pay
- Figma: node 176:6564 · key 4aefb1d354852cdb252f575edfb7dd9052a2364b · properties: Label (text), Value (text), Tap=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=176-6648)

### Bank logo

A bank's mark in Your bank's list: its first letter on a muted disc, bank/logo wide. The real app shows the bank's logo from the payment provider.

- Use: In a Sheet row's sticker slot (Sticker swapped to Bank logo), Trailing=arrow with the chevron-right icon and no subtitle.
- Props: Letter.
- Code: BankLogo · app/lib/components/trip_pages.dart
- Storybook: Money · your bank
- Figma: node 176:6565 · key fe8e5b9cdfe5043ebe1c78167839ba389aadaee1 · properties: Letter (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=176-6689)

## Poll

Choosing dinner: the poll on the map.

### Poll card

The dinner poll on the map. Compact under the day chips: the live sign and countdown, the question, and who has voted. Opens in place over a tinted, blurred map: the places, each with its votes and the vote.

- Props: Live line · Meta · State=compact|open → expanded.
- Code: PollCard · app/lib/components/poll.dart
- Storybook: Dinner tonight
- Figma: node 120:4568 · key 62bea369812bf43961db470b37ac23b35cfbc872 · properties: Live line (text), Meta (text), State=compact|open (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1129)

### Poll place

One place in the open poll: name, rating, food and price, its sticker, a bar of its votes, Details, who voted for it, and the vote (primary once it's mine).

- Props: Name · Rating · Food · Price · Sticker · My vote=no|yes.
- Code: _Place · app/lib/components/poll.dart
- Figma: node 119:4520 · key a7b63d08c48fb4139acee5d479a4e0868f901231 · properties: Name (text), Rating (text), Food (text), Price (text), Sticker (instance swap), My vote=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1150)

### Vote bar

A place's share of the five votes: brand for the one ahead, growing from the left as votes come in.

- Props: Votes=0…5 → votes.
- Code: VoteBar · app/lib/components/poll.dart
- Figma: node 119:4461 · key 841aa40c7556f9496f225a20d62181d2af877988 · properties: Votes=0|1|2|3|4|5 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1168)

### Live dot

Live: a red dot that slowly breathes while the poll is open.

- Code: LiveDot · app/lib/components/poll.dart
- Figma: node 119:4448 · key b520bf2afbfbf5efe04c5cd446dd0646628be180 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1189)

## Bill

The bill: the camera reads it and splits it by who had what.

### Scan frame

The camera's frame: four rounded corners, closing in on the paper once it's found (then in brand).

- Code: _Corners · app/lib/components/bill_scan.dart
- Figma: node 124:5389 · key 53390c44d4b84704cd635b7cf366be3f1642a03c (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1212)

### Receipt

The paper bill the camera reads: La Brasserie's real items and prices.

- Code: _Paper · app/lib/components/bill_scan.dart
- Figma: node 124:5347 · key e03d1ec21e288b9dd1bb76884b7708601d4c3106 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1268)

### Bill line

One line of the scanned bill: the menu dish it matched, quantity × price and who had it; its total and their faces. Tap it to change who had it.

- Props: Title · Subtitle · Amount · Face 2–5.
- Code: BillScan · app/lib/components/bill_scan.dart
- Figma: node 124:5327 · key 4e2678336eb34c38740a6b28c0145ec07eace2a8 · properties: Title (text), Subtitle (text), Amount (text), Face 2 (boolean), Face 3 (boolean), Face 4 (boolean), Face 5 (boolean) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1360)

### Share

One person's share of the bill: their face and the amount.

- Props: Amount · Face.
- Code: BillScan · app/lib/components/bill_scan.dart
- Figma: node 124:5339 · key 4c44234b5e7dfa43ebc2fb7e7d94b48452754c9f · properties: Amount (text), Face (instance swap) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1388)

### Payer

Who paid, at the bottom of the scanned bill. Tapping it opens a small menu of everyone at the table.

- Props: Label.
- Code: _PayerPicker · app/lib/components/bill_scan.dart
- Figma: node 124:5342 · key 150d7f56e53bce41cf86b2714fdca6be72686a81 · properties: Label (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1411)

## Paying

Paying what I owe from the app: TripUp hands off to my bank's app (open banking), I approve it there with Face ID, and the bank confirms. TripUp never holds the money.

### Face ID

The system's Face ID square in the middle of the bank's app: the face glyph and "Face ID" while it scans (face-id-ms), then a green check and "Approved" (approved-ms).

- Use: Inside Bank approval (its scanning and approved phases).
- Props: Phase (scanning, approved).
- Code: BankApp · app/lib/components/bank_app.dart
- Storybook: Bank app
- Figma: node 178:6568 · key b57e002eade74b3dbe46f4a4f91f996b66abfb4f · properties: Phase=scanning|approved (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=178-6851)

### Bank approval

My bank's app with the transfer TripUp started filled in: ‹ TripUp (iOS's back-to-app link), the bank's bar, "Approve payment", the transfer in a white card (amount, SEPA Instant · arrives in seconds, To, IBAN, Reference, From; none can be changed), Approve with Face ID and Cancel. A stand-in for the bank's own app, in a plain look of its own (c-bank colours) so it reads as another app.

- Use: The whole screen (it has its own status bar and home indicator).
- Avoid: TripUp's own glass or brand blue here: it's another app.
- Props: Phase (review, scanning, approved) · Bank · Amount · To · IBAN · Reference · From.
- Code: BankApp · app/lib/components/bank_app.dart
- Storybook: Bank app
- Figma: node 178:6806 · key 9869a0b9abdf86e4cd87258810b9cf2cff15109d · properties: Bank (text), Amount (text), To (text), IBAN (text), Reference (text), From (text), Phase=review|scanning|approved (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=178-6892)

## Live Activity

The poll outside the app: lock screen, Dynamic Island, notification. iOS widget code in Swift.

### Live Activity

The dinner poll on the lock screen: the live line and countdown, the question, and the three places as vote buttons.

- Use: Follows the system's light or dark look: set the Color and Component modes on the instance.
- Props: Live line · Countdown · Title.
- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6139 · key 021e8d0638680c38c499f553f91437d4d773b081 · properties: Live line (text), Countdown (text), Title (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1530)

### Activity place

One place on the Live Activity. The whole card is the vote button; brand-subtle with a filled check once it's mine.

- Props: Name · Count · Sticker · Mine=no|yes.
- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6138 · key f2b4306f8acb8a85d2ebbcd7b658b969309dbad8 · properties: Name (text), Count (text), Sticker (instance swap), Mine=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1573)

### Activity mark

The vote mark on an Activity place: an empty ring, or a filled check once it's mine.

- Props: Mine=no|yes.
- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6105 · key 9f032b13438271486929165c6b736ce769c73770 · properties: Mine=no|yes (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1591)

### Activity bar

The thin votes bar on an Activity place, brand for the one ahead.

- Props: Votes=0…5.
- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6117 · key bbd0df2506e543f3d376e11dd3a11615b4e6daee · properties: Votes=0|1|2|3|4|5 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1609)

### Island / compact

The poll in the Dynamic Island while another app is in front: the live dot and Poll, and the countdown.

- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6176 · key b7271097cc55a8538941e48645b87a2b0aa00cc0 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1632)

### Island / expanded

The Dynamic Island held open: votes so far, the countdown, and the three places to vote on. Always dark.

- Code: PollLiveActivity · app/ios/PollWidget/PollLiveActivity.swift
- Figma: node 131:6182 · key fc24614c18bb6b6c61cfabf6703fb65e6802a3d3 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1679)

### Notification

The poll's notification: iOS's own banner, sent as the poll opens. Tapping it opens the poll; holding it shows a vote button per place.

- Props: Title · Body.
- Code: PollBridge · app/ios/Runner/PollBridge.swift
- Figma: node 132:6153 · key 86bbbe218b2c9ab370e4ebc590c23c664c30cb41 · properties: Title (text), Body (text) (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1716)

### Notification actions

The vote buttons when the notification is held: one per place, by its short name. Voting doesn't open the app.

- Code: PollBridge · app/ios/Runner/PollBridge.swift
- Figma: node 132:6161 · key 466a8dedc8eb5ea5db8ed2da15b70b2453180095 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1739)

### App icon

TripUp's app icon at notification size.

- Code: app/ios/Runner/Assets.xcassets/AppIcon.appiconset
- Figma: node 132:6151 · key e8e5e377ba261039db387e6b0cea6ffd352c6b5e (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1751)

### Wallpaper

A plain stand-in for the phone's own wallpaper behind the lock screen. System UI, not the app's.

- Code: System UI (iOS), not in the app's code.
- Figma: node 134:6164 · key 6031dc6a49fc44950748155d1872bf8af8354ce4 (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=147-1763)

## Assets

Icons, stickers and photos the components use.

### Icon set

The Lucide icons the app uses, one component each (Icon/<lucide name>), on a 24 grid with a 2 px stroke at any size.

- Use: Swap them through the Icon property of Button, Text button, Fact row and Icon row. Never draw a new icon: add it to TuIcons first.
- Code: TuIcons, LucideIcon · app/lib/components/glass.dart
- Figma: node 93:1428 · properties: 28 components: Icon/<lucide name> (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=148-996)

### Sticker library

Die-cut photo stickers: real people (the group's faces), places, landmarks and food. One component each (Sticker/<set>/<name>).

- Use: Through a Sticker or Face property; sizes come from the sticker tokens (sticker/row, sticker/avatar).
- Code: Sticker · app/lib/components/basics.dart (images in app/assets/stickers)
- Figma: node 13:2 · properties: 70 components: Sticker / <set> / <name> (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=148-1011)

### Photo set

The place's photos (Photo/…) and the menu's dish photos (Dish/…), used by Photo carousel and Dish sticker.

- Code: app/assets/photos (place photos and assets/photos/menu); data in app/lib/data.dart
- Figma: node 104:2035 · properties: 26 components: Photo / <name>, Dish / <name> (https://www.figma.com/design/G13GoEmstoKyMr5nCh8eoQ/TripUp-Test-Task?node-id=148-1026)
