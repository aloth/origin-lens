import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/main_screen.dart';
import 'package:origin_lens/src/rust/frb_generated.dart';
import 'services/reverse_image_search_service.dart';
import 'services/synthid_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await RustLib.init();

  final serpApiKey = dotenv.env['SERPAPI'] ?? '';
  final imgbbKey = dotenv.env['imgbb_key'] ?? '';
  final googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

  ReverseImageSearchService.instance.configure(
    apiKey: serpApiKey,
    imgbbApiKey: imgbbKey,
  );

  SynthIdService.instance.configure(apiKey: googleApiKey);

  runApp(const OriginLensApp());
}

class OriginLensApp extends StatelessWidget {
  const OriginLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Origin Lens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      onGenerateRoute: (settings) {
        String? sharedFilePath;
        if (settings.name != null && settings.name != '/') {
          sharedFilePath = settings.name;
        }

        return MaterialPageRoute(
          builder: (context) =>
              MainScreen(initialSharedFilePath: sharedFilePath),
        );
      },
    );
  }
}
