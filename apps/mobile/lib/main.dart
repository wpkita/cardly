import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/game_lobby_screen.dart';
import 'services/game_service.dart';
import 'services/signalr_game_service.dart';

void main() {
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
    return Provider<GameService>(
      create: (_) => SignalRGameService(baseUrl: 'http://localhost:8080'),
      child: MaterialApp(
        title: 'Cardly - Rummy 500',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        onGenerateRoute: (settings) {
          // Handle /join/ROOMCODE URLs
          if (settings.name != null && settings.name!.startsWith('/join/')) {
            final roomCode = settings.name!
                .substring(6)
                .toUpperCase();
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
      ),
    );
  }
}
