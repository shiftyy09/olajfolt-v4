// lib/kepernyok/jarmuvek/jarmupark_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
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
    _loadVehicles();
  }

  void _deleteVehicle(Jarmu vehicle) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
                'Törlés megerősítése', style: TextStyle(color: Colors.white)),
            content: Text(
                'Biztosan törölni szeretnéd a(z) ${vehicle.make} ${vehicle
                    .model} járművet?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                      'Mégse', style: TextStyle(color: Colors.white70))),
              TextButton(
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8)),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                    'Törlés', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await AdatbazisKezelo.instance.delete('vehicles', vehicle.id!);
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
      appBar: AppBar(title: const Text('Járműpark'),
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
            return Center(child: Text('Hiba: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)));
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return Center(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 80,
                          color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      const Text('Még nincsenek járművek rögzítve.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text(
                          'Nyomj a "+" gombra egy új jármű hozzáadásához.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 16))
                    ])));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final logoPath = _getLogoPath(
                  vehicle.make); // <-- Itt generáljuk a logó útvonalát
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  // === EZ AZ ATOMBOMBA VERZIÓ ===
                  leading: SizedBox(
                    width: 80, height: 40,
                    child: Image.asset(
                      logoPath, // Megpróbáljuk betölteni a képet
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // HA NEM SIKERÜL, A HIBA JELENIK MEG PIROS SZÖVEGGEL
                        return Center(
                          child: Text(
                            logoPath.replaceAll('assets/images/', ''),
                            style: const TextStyle(color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.clip, softWrap: true,
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text('${vehicle.make} ${vehicle.model}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${vehicle.licensePlate} - ${vehicle.year}',
                      style: const TextStyle(color: Colors.white70)),
                  onTap: () => _navigateToServiceLog(vehicle),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit,
                        color: Colors.amber),
                        onPressed: () =>
                            _navigateAndReload(
                                JarmuHozzaadasa(vehicleToEdit: vehicle))),
                    IconButton(icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                        onPressed: () => _deleteVehicle(vehicle)),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndReload(const JarmuHozzaadasa()),
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.black)),
    );
  }
}