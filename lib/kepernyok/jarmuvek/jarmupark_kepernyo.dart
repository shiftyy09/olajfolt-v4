// lib/kepernyok/jarmuvek/jarmupark_kepernyo.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'jarmu_hozzaadasa.dart';


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
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Mégse'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                    'Törlés', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // JAVÍTVA: Helyes, egységes adatbázis hívás
      await AdatbazisKezelo.instance.delete('vehicles', vehicle.id!);
      _loadVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Járműpark'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Jarmu>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)));
          }
          final vehicles = snapshot.data ?? [];
          if (vehicles.isEmpty) {
            return const Center(
              child: Text(
                'Még nincsenek járművek a parkban.\nAdj hozzá egyet a + gombbal!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: Colors.cyan,
                    child: Text(
                      vehicle.make.substring(0, 1),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    '${vehicle.make} ${vehicle.model}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${vehicle.licensePlate} - ${vehicle.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.amber),
                        onPressed: () =>
                            _navigateAndReload(
                                JarmuHozzaadasa(vehicleToEdit: vehicle)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteVehicle(vehicle),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndReload(const JarmuHozzaadasa()),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}