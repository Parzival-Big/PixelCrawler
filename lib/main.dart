import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/save_service.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveService.load();
  // Phones, tablets and foldables (folded portrait ↔ open landscape) — never
  // lock orientation so a fold/unfold does not require an app restart.
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const PixelCrawlerApp());
}

class PixelCrawlerApp extends StatelessWidget {
  const PixelCrawlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Crawler',
      debugShowCheckedModeBanner: false,
      theme: buildPixelTheme(),
      builder: (context, child) {
        // Keep text readable when the OS font scale is extreme on tablets.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainMenuScreen(),
    );
  }
}
