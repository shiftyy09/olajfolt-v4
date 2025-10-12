// lib/kepernyok/indito/indito_kepernyo.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart'; // <-- Fontos: importáljuk az adatbázis-kezelőt
import '../fooldal/fooldal_kepernyo.dart';

class InditoKepernyo extends StatefulWidget {
  const InditoKepernyo({super.key});

  @override
  State<InditoKepernyo> createState() => _InditoKepernyoState();
}

// JAVÍTVA: Animációhoz szükséges 'Mixin' hozzáadása
class _InditoKepernyoState extends State<InditoKepernyo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeApp(); // A navigációt átnevezzük és módosítjuk
  }

  // JAVÍTVA: Pulzáló animáció beállítása
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )
      ..repeat(reverse: true); // Ismétlődő, oda-vissza animáció

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // JAVÍTVA: A navigációt az adatbázis betöltéséhez kötjük
  void _initializeApp() async {
    // Elindítjuk az adatbázis-kapcsolat kiépítését a háttérben.
    // Ez az első művelet, ami időbe telhet.
    await AdatbazisKezelo.instance.database;

    // Amint az adatbázis kész, azonnal navigálunk.
    // A 'mounted' ellenőrzés fontos, hogy ne fussunk hibára.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        // Áttűnési animáció a szebb váltásért
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const FooldalKepernyo(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // JAVÍTVA: A logót egy animációt kezelő widgetbe csomagoljuk
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/olajfolt.png',
                width: 250,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Szerviz-napló',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 164, 0),
              ),
            ),
            // JAVÍTVA: A felesleges töltésjelző és a nagy térköz eltávolítva
          ],
        ),
      ),
    );
  }
}