import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'rummy_500_screen.dart';
import 'screens/game_lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

  // This widget is the root of your application.
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
          final roomCode = settings.name!.substring(6).toUpperCase(); // Extract and uppercase room code
          return MaterialPageRoute(
            builder: (context) => GameLobbyScreen(joinRoomId: roomCode),
            settings: settings,
          );
        }

        // Default routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Cardly'),
              settings: settings,
            );
          case '/rummy':
            return MaterialPageRoute(
              builder: (context) => const Rummy500Screen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const MyHomePage(title: 'Cardly'),
              settings: settings,
            );
        }
      },
      initialRoute: _getInitialRoute(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cardly',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Play Card Games Online',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Rummy500Screen(),
                  ),
                );
              },
              icon: const Icon(Icons.style),
              label: const Text('Play Rummy 500'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
