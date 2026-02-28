import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';

import '../models/quest_location.dart';
import '../providers/game_provider.dart';

class QuestScreen extends StatefulWidget {
  final QuestLocation location;

  const QuestScreen({super.key, required this.location});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  String? selectedAnswer;
  bool answered = false;

  late List<String> options;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    // Je kan dit later dynamisch maken per quest
    options = [
      widget.location.answer, // altijd juiste antwoord toevoegen
      "Pizza Napoli",
      "Mama Mia",
      "Italian Corner",
    ];

    options.shuffle();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void selectAnswer(String answer) {
    if (answered) return;

    setState(() {
      selectedAnswer = answer;
      answered = true;
    });

    if (answer == widget.location.answer) {
      _confettiController.play();

      final provider = context.read<GameProvider>();

      // ✅ Alleen als nog niet bezocht
      if (provider.markVisited(widget.location.id)) {
        provider.unlockLetter(widget.location.letter);
      }

      // ✅ Kleine delay voor UX
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  Color _getButtonColor(String option) {
    if (!answered) return Colors.blueAccent;

    if (option == widget.location.answer) {
      return Colors.green;
    }

    if (option == selectedAnswer) {
      return Colors.red;
    }

    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.title),
      ),
      body: Stack(
        children: [
          /// ================= MAIN CONTENT =================
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.location.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                /// ✅ Answer buttons
                ...options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => selectAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getButtonColor(option),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                if (answered &&
                    selectedAnswer == widget.location.answer)
                  const Text(
                    "✅ Correct! Letter unlocked!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                if (answered &&
                    selectedAnswer != widget.location.answer)
                  const Text(
                    "❌ Wrong answer!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),

          /// ================= CONFETTI =================
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}