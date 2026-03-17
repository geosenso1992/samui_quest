import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/game_provider.dart'; // Import toegevoegd voor sync

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool isLoginMode = true; // Default: eerst inloggen
  bool _obscurePassword = true;
  bool _rememberPassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      if (savedEmail != null) {
        emailController.text = savedEmail;
      }
      if (savedPassword != null) {
        passwordController.text = savedPassword;
        _rememberPassword = true;
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      if (_rememberPassword) {
        await prefs.setString('saved_password', password);
      } else {
        await prefs.remove('saved_password');
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  // Gecombineerde functie voor Login & Registratie
  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();

    // Basis Validatie
    if (email.isEmpty || password.isEmpty || (!isLoginMode && username.isEmpty)) {
      setState(() => errorMessage = 'Vul alle velden in.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (isLoginMode) {
        // --- LOGICA VOOR INLOGGEN ---
        final UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Direct de data synchroniseren voor Robinhood2
        if (mounted) {
          await context.read<GameProvider>().syncUserData(userCred.user!.uid);
        }
        await _saveCredentials(email, password);
      } else {
        // --- LOGICA VOOR REGISTREREN ---
        final user = await AuthService().register(email, password);
        if (user != null) {
          await DatabaseService().createNewUser(user.uid, username);
          if (mounted) {
            await context.read<GameProvider>().syncUserData(user.uid);
          }
          await _saveCredentials(email, password);
        }
      }

      if (!mounted) return;
      // Navigeer naar home en wis geschiedenis
      Navigator.of(context).pushReplacementNamed('/home');

    } catch (e) {
      setState(() => errorMessage = 'Fout: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/seedscape1.png",
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.55),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, screenHeight * 0.32, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isLoginMode ? "Welkom terug, Explorer!" : "Maak een nieuw account",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFCC00),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
             
                // Username alleen tonen bij Registratie
                if (!isLoginMode) ...[
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gebruikersnaam',
                      labelStyle: const TextStyle(color: Color(0xFFFFCC00)),
                      filled: true,
                      fillColor: const Color(0xFF0F1440).withValues(alpha: 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFFFCC00)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
             
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'E-mailadres',
                    labelStyle: const TextStyle(color: Color(0xFFFFCC00)),
                    filled: true,
                    fillColor: const Color(0xFF0F1440).withValues(alpha: 0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: Color(0xFFFFCC00)),
                  ),
                ),
                const SizedBox(height: 16),
             
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Wachtwoord',
                    labelStyle: const TextStyle(color: Color(0xFFFFCC00)),
                    filled: true,
                    fillColor: const Color(0xFF0F1440).withValues(alpha: 0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCC00)),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFFFFCC00),
                      ),
                    ),
                  ),
                ),
             
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberPassword,
                      activeColor: const Color(0xFFFFCC00),
                      checkColor: Colors.black,
                      onChanged: (value) {
                        setState(() => _rememberPassword = value ?? true);
                      },
                    ),
                    const Text(
                      "Wachtwoord onthouden",
                      style: TextStyle(
                        color: Color(0xFFFFCC00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 10),

                // De Hoofdknop (Login of Register)
                ElevatedButton(
                  onPressed: isLoading ? null : handleAuth,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 56),
                    backgroundColor:
                        const Color(0xFF1F2A66).withValues(alpha: 0.85),
                    foregroundColor: const Color(0xFFFFCC00),
                    side: BorderSide(
                      color: const Color(0xFF11194A).withValues(alpha: 0.95),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isLoginMode ? 'Inloggen' : 'Start je Avontuur!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 14),

                // De Wisselknop
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLoginMode = !isLoginMode;
                      errorMessage = '';
                    });
                  },
                  child: Text(
                    isLoginMode
                        ? "Nog geen account? Maak hier een nieuw account aan."
                        : "Heb je al een account? Log hier in",
                    style: const TextStyle(
                      color: Color(0xFFFFCC00),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
