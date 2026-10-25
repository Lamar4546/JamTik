import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/supabase_config.dart';
import 'screens/login_screen.dart';
 import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await dotenv.load(fileName: '.env');
     assert(SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty,
         'Fill in SUPABASE_URL and SUPABASE_ANON_KEY in .env');
     await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);

  // Covers manual log out AND a revoked/expired session.
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedOut) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  });
  runApp(const JamTikApp());
}

class JamTikApp extends StatelessWidget {
  const JamTikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'jamTik',
      debugShowCheckedModeBanner: false,
      theme: buildJamTikTheme(),
      // Keeps the phone layout centred when running on web / tablet / desktop.
      builder: (context, child) => ColoredBox(
        color: Colors.black,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
