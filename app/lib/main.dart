import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/theme.dart';
import 'design/tokens.dart';
import 'screens/trip_screen.dart';
import 'startup_timings.dart';

void main() {
  StartupTimings.begin();
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) => StartupTimings.mark('Your trips drawn (first frame)'));
  // Edge to edge, as on iOS: the app draws under see-through system bars (Android 8-9: MainActivity does the layout)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(systemBarsOver(dark: true));
  runApp(const TripUpApp());
}

class TripUpApp extends StatelessWidget {
  const TripUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: TokFont.sans, splashFactory: NoSplash.splashFactory),
      builder: (context, child) => Tok(
        colors: TokColors.light,
        child: DefaultTextStyle(
          style: TokText.bodyMd.copyWith(color: TokColors.light.textDefault),
          // The startup timings' hidden panel sits over everything (long-press "Your trips")
          child: Stack(children: [child!, const StartupPanel()]),
        ),
      ),
      home: const TripScreen(),
    );
  }
}
