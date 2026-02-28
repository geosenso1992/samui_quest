import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // Background image
          SizedBox.expand(
            child: Image.asset(
              "assets/samui2.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [

                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "<- Back to Start",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.greenAccent,
                          width: 3,
                        ),
                      ),
                      child: const SingleChildScrollView(
                        child: Column(
                          children: [

                            Text(
                              "HOW TO PLAY",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 20),

                            Text(
                              "🌴 Explore the island and go to each quest location.\n\n"
                              "⏱️ After unlocking the quest, you have 60 seconds to answer the question.\n\n"
                              "✅ Correct answers unlock a secret LETTER.\n\n"
                              "🔤 Collect all letters to solve the FINAL WORD.\n\n"
                              "🏝️ Finish all quests to become the Samui Quest Master!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}