import 'package:car_maintenance_app/kepernyok/beallitasok/beallitasok_kepernyo.dart';
import 'package:car_maintenance_app/kepernyok/fogyasztas/fogyasztas_kalkulator_kepernyo.dart';
import 'package:car_maintenance_app/kepernyok/jarmuvek/jarmupark_kepernyo.dart';
import 'package:car_maintenance_app/kepernyok/karbantartas/karbantartas_emlekezteto.dart';
import 'package:car_maintenance_app/kepernyok/jarmuvek/szerviznaplo_kepernyo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';

class FooldalKepernyo extends StatefulWidget {
  const FooldalKepernyo({super.key});

  @override
  State<FooldalKepernyo> createState() => _FooldalKepernyoState();
}

class _FooldalKepernyoState extends State<FooldalKepernyo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateTo(Widget page) async {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _selectVehicleAndNavigate(String destination) async {
    final db = AdatbazisKezelo.instance;
    final vehiclesMap = await db.getVehicles();
    final vehicles = vehiclesMap.map((e) => Jarmu.fromMap(e)).toList();

    if (!mounted) return;

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nincs jármű a parkban! Előbb vegyél fel egyet.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final Jarmu? selected = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title:
          const Text(
              'Válassz járművet!', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      '${vehicles[index].make} ${vehicles[index].model}',
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(context).pop(vehicles[index]),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      if (destination == 'szerviznaplo') {
        _navigateTo(SzerviznaploKepernyo(vehicle: selected));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 20.0),
              child: Image.asset(
                'assets/images/olajfoltiras.png',
                height: 50,
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      // JÁRMŰPARK KÁRTYA
                      _buildMenuCard(
                        context,
                        icon: Icons.directions_car_filled,
                        title: 'Járműpark',
                        subtitle: 'Autóid kezelése, adatok módosítása',
                        color: Colors.cyan,
                        onTap: () => _navigateTo(const JarmuparkKepernyo()),
                      ),

                      // KARBANTARTÁSI EMLÉKEZTETŐ KÁRTYA
                      _buildMenuCard(
                        context,
                        icon: Icons.notifications_active,
                        title: 'Karbantartási Emlékeztető',
                        subtitle: 'Rögzített állapotok és esedékességek',
                        color: Colors.amber,
                        onTap: () =>
                            _navigateTo(const KarbantartasEmlekezteto()),
                      ),

                      // FOGYASZTÁS KALKULÁTOR KÁRTYA
                      _buildMenuCard(
                        context,
                        icon: Icons.calculate,
                        title: 'Fogyasztás kalkulátor',
                        subtitle: 'Tervezett utak költségének becslése',
                        color: Colors.green,
                        onTap: () =>
                            _navigateTo(const FogyasztasKalkulatorKepernyo()),
                      ),

                      // SZERVIZNAPLÓ KÁRTYA
                      _buildMenuCard(
                        context,
                        icon: Icons.history_edu,
                        title: 'Szerviznapló',
                        subtitle: 'Elvégzett javítások és költségek',
                        color: Colors.blueAccent,
                        onTap: () => _selectVehicleAndNavigate('szerviznaplo'),
                      ),

                      // 2. LÉPÉS: Ide illesztjük be az új Beállítások kártyát
                      _buildMenuCard(
                        context,
                        icon: Icons.settings,
                        // Ikon
                        title: 'Beállítások',
                        // Cím
                        subtitle: 'Import, export és egyéb opciók',
                        // Alcím
                        color: Colors.grey.shade600,
                        // Szín
                        onTap: () =>
                            _navigateTo(
                                const BeallitasokKepernyo()), // Navigáció az új képernyőre
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Az _buildMenuCard függvény változatlan marad
  Widget _buildMenuCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.6), color.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14)),
                  ],
                ),
              ),
              const Icon(
                  Icons.arrow_forward_ios, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}