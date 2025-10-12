import 'package:flutter/material.dart';
import 'kepernyok/indito/indito_kepernyo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CarMaintenanceApp());
}

class CarMaintenanceApp extends StatelessWidget {
  const CarMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Szerviz-napló',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 164, 0),
          brightness: Brightness.dark,
          primary: const Color.fromARGB(255, 255, 164, 0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color.fromARGB(255, 255, 164, 0),
          centerTitle: true,
        ),
      ),
      home: const InditoKepernyo(),
    );
  }
}