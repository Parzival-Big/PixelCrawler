import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/save_service.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveService.load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      home: const MainMenuScreen(),
    );
  }
}
