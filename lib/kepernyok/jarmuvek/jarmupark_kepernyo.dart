import 'dart:io'; // Fájlkezeléshez
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'jarmu_hozzaadasa.dart';
import 'szerviznaplo_kepernyo.dart';

class JarmuparkKepernyo extends StatefulWidget {
  const JarmuparkKepernyo({super.key});

  @override
  State<JarmuparkKepernyo> createState() => _JarmuparkKepernyoState();
}

class _JarmuparkKepernyoState extends State<JarmuparkKepernyo> {
  Future<List<Jarmu>>? _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = AdatbazisKezelo.instance.getVehicles().then(
            (maps) => maps.map((map) => Jarmu.fromMap(map)).toList(),
      );
    });
  }

  void _navigateAndReload(Widget page) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (result == true) {
      _loadVehicles();
    }
  }

  void _navigateToServiceLog(Jarmu jarmu) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SzerviznaploKepernyo(vehicle: jarmu),
      ),
    );
  }

  void _deleteVehicle(Jarmu vehicle) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title:
            const Text(
                'Törlés megerősítése', style: TextStyle(color: Colors.white)),
            content: Text(
                'Biztosan törölni szeretnéd a(z) ${vehicle.make} ${vehicle
                    .model} járművet és minden hozzá tartozó adatot?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child:
                  const Text('Mégse', style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Törlés',
                    style:
                    TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      final db = AdatbazisKezelo.instance;
      await db.deleteServicesForVehicle(vehicle.id!);
      await db.delete('vehicles', vehicle.id!);
      _loadVehicles();
    }
  }

  String _getLogoPath(String make) {
    String safeName = removeDiacritics(make.toLowerCase());
    safeName = safeName.replaceAll(RegExp(r'\s+'), '-');
    safeName = safeName.replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    return 'assets/images/$safeName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text('Járműpark'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: FutureBuilder<List<Jarmu>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Hiba: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_outlined,
                              size: 80, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          const Text('Még nincsenek járművek rögzítve.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text(
                              'Nyomj a "+" gombra egy új jármű hozzáadásához.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16))
                        ])));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              return _buildVehicleCard(vehicles[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndReload(const JarmuHozzaadasa()),
          backgroundColor: Colors.orange,
          tooltip: 'Új jármű hozzáadása',
          child: const Icon(Icons.add, color: Colors.black)),
    );
  }

  // === VÉGLEGESEN JAVÍTOTT, LETISZTULT KÁRTYA DIZÁJN ===
  Widget _buildVehicleCard(Jarmu vehicle) {
    final logoPath = _getLogoPath(vehicle.make);
    final bool hasUserImage =
        vehicle.imagePath != null && vehicle.imagePath!.isNotEmpty;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: const Color(0xFF1E1E1E),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- BAL OLDALI SZEKCIÓ: Információk ---
          Expanded(
            child: InkWell(
              onTap: () => _navigateToServiceLog(vehicle),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.licensePlate.toUpperCase()} • ${vehicle.year}',
                      style: TextStyle(
                          color: Colors.orange.shade200, fontSize: 14),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      children: [
                        Icon(Icons.speed, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat.decimalPattern('hu_HU').format(vehicle
                              .mileage)} km',
                          style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // --- Gombok ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          color: Colors.orange,
                          tooltip: 'Jármű szerkesztése',
                          onPressed: () =>
                              _navigateAndReload(JarmuHozzaadasa(
                                  vehicleToEdit: vehicle)),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          color: Colors.redAccent,
                          tooltip: 'Jármű törlése',
                          onPressed: () => _deleteVehicle(vehicle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- JOBB OLDALI SZEKCIÓ: Kép vagy Logó ---
          SizedBox(
            width: 120,
            height: 170, // Magasság a kártya konzisztens méretéhez
            child: hasUserImage
                ? ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(15.0)),
              child: Image.file(
                File(vehicle.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildLogoContainer(logoPath),
              ),
            )
                : _buildLogoContainer(logoPath),
          ),
        ],
      ),
    );
  }

  // Segéd-widget a logó megjelenítéséhez
  Widget _buildLogoContainer(String logoPath) {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.directions_car,
                  color: Colors.white24, size: 40);
            },
          ),
        ),
      ),
    );
  }

  // Segéd-widget a gombok egységes stílusához
  Widget _buildActionButton(
      {required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}