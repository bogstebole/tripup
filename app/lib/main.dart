import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/theme.dart';
import 'design/tokens.dart';
import 'screens/trip_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
        child: DefaultTextStyle(style: TokText.bodyMd.copyWith(color: TokColors.light.textDefault), child: child!),
      ),
      home: const TripScreen(),
    );
  }
}
