import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _checkAndNavigate();
      }
    });
  }

  Future<void> _checkAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('first_run') ?? true;
      
      if (!mounted) return;
      
      Widget nextScreen;
      if (isFirstRun) {
        nextScreen = const OnboardingScreen();
      } else {
        nextScreen = const MainNavigation();
      }
      
      if (mounted && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.note_alt,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Notebook Pro',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Notes • Tasks • Documents',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}