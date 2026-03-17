import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

import 'firebase_options.dart';
import 'providers/game_provider.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);
    await AudioService().init();
    await AudioService().playBackground();
    logger.i("🔥 Firebase succesvol gestart!");
  } catch (e) {
    logger.e("❌ Firebase fout: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>(
          create: (_) => GameProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // De AuthWrapper beslist of we naar Register of Home gaan
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/register': (context) => const RegisterScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Wachten op antwoord van Firebase Auth service
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        // 2. Gebruiker is ingelogd
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // We starten de sync op de achtergrond.
          // Omdat we de HomeScreen returnen, zal die openen.
          // Mocht de sync falen, dan zie je in ieder geval de interface.
          Future.microtask(() async {
            final game = context.read<GameProvider>();
            await game.loadLocalSnapshot(user.uid);
            await game.syncUserDataWithFallback(user.uid);
          }).catchError((e) {
            logger.e("Sync fout in Wrapper: $e");
          });

          return const HomeScreen();
        }

        // 3. Geen actieve sessie gevonden -> naar Register/Login
        return const RegisterScreen();
      },
    );
  }
}
