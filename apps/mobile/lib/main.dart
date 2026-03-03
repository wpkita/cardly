import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/game_lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _getInitialRoute() {
    if (kIsWeb) {
      final path = Uri.base.path;
      return path.isEmpty || path == '/' ? '/' : path;
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cardly - Rummy 500',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      onGenerateRoute: (settings) {
        // Handle /join/ROOMCODE URLs
        if (settings.name != null && settings.name!.startsWith('/join/')) {
          final roomCode = settings.name!
              .substring(6)
              .toUpperCase(); // Extract and uppercase room code
          return MaterialPageRoute(
            builder: (context) => GameLobbyScreen(joinRoomId: roomCode),
            settings: settings,
          );
        }

        // Default routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const GameLobbyScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const GameLobbyScreen(),
              settings: settings,
            );
        }
      },
      initialRoute: _getInitialRoute(),
    );
  }
}
