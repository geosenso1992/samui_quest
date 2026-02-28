import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class FinalWordScreen extends StatelessWidget {
  const FinalWordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    const String finalWord = "KINGCOBRA";

    return Scaffold(
      appBar: AppBar(title: const Text("Final Word")),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/maps/jungle.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Wrap(
            spacing: 6,
            children: List.generate(finalWord.length, (index) {

              final String letter = finalWord[index];

              // 🔥 Check op positie (veel stabieler)
              bool unlocked = index < game.unlockedLetters.length;

              return Container(
                width: 36,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: unlocked
                      ? Colors.green.withOpacity(0.8)
                      : Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  unlocked ? letter : "?",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}