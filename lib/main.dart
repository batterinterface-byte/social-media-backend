import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const NotebookApp());
}

class NotebookApp extends StatelessWidget {
  const NotebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notebook Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 4),
        navigationBarTheme: NavigationBarThemeData(labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, indicatorColor: Colors.teal.withValues(alpha: 0.2)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 4),
        navigationBarTheme: NavigationBarThemeData(labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, indicatorColor: Colors.teal.withValues(alpha: 0.2)),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}