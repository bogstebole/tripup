import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../design/theme.dart';
import '../design/tokens.dart';

/// The web build on a computer. A browser window is far wider than a phone, and the app stretched across it blows up
/// everything sized from the screen (the map still on the trip card, its stickers). So on a wide window the app sits
/// in a phone-sized frame in the middle, the size of the Figma screens, scaled down to fit the window's height: it
/// looks as it does on the phone. In a phone's browser, and in the app itself, it fills the screen as usual.
class WebPhoneFrame extends StatelessWidget {
  const WebPhoneFrame({super.key, required this.child});
  final Widget child;

  static final _screen = GlobalKey();

  /// The app's screen, to measure where something sits on it (`localToGlobal(..., ancestor: WebPhoneFrame.screen)`):
  /// in the frame the window's coordinates are off by the frame's place and scale. Without a frame it's the window.
  /// The same key holds the app with or without the frame, so resizing the window across the line keeps its state.
  static RenderObject? get screen => _screen.currentContext?.findRenderObject();

  @override
  Widget build(BuildContext context) {
    final window = MediaQuery.of(context);
    final app = KeyedSubtree(key: _screen, child: child);
    // The text is always the design's size: the phone's text size setting (Dynamic Type, Android's font size) and the
    // browser's font size don't scale it. The prototype is judged on its layout, so it looks the same on every phone
    if (!kIsWeb || window.size.width < TokDim.webFrameMinWindow) return MediaQuery(data: window.copyWith(textScaler: TextScaler.noScaling), child: app);
    const phone = Size(TokDim.webFrameWidth, TokDim.webFrameHeight);
    return ColoredBox(
      color: context.tok.bgMuted,
      child: Padding(
        padding: const EdgeInsets.all(TokDim.webFrameMargin),
        child: FittedBox(
          fit: BoxFit.scaleDown,   // smaller on a short window, never larger than the phone
          child: Container(
            width: phone.width,
            height: phone.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(TokDim.webFrameRadius), boxShadow: TokShadow.elevationOverlay),
            // Everything inside lays itself out for the phone's screen, not the window
            child: MediaQuery(
              data: window.copyWith(size: phone, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero, viewInsets: EdgeInsets.zero, textScaler: TextScaler.noScaling),
              child: app,
            ),
          ),
        ),
      ),
    );
  }
}
