import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'jarmu_hozzaadasa.dart';
import 'szerviznaplo_kepernyo.dart'; // Importáljuk a szerviznapló képernyőt

class JarmuLista extends StatefulWidget {
  final bool selectionMode;

  const JarmuLista({super.key, this.selectionMode = false});

  @override
  State<JarmuLista> createState() => _JarmuListaState();
}

class _JarmuListaState extends State<JarmuLista> {
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

  // JAVÍTVA: A szerviznapló megnyitására szolgál
  void _navigateToServiceLog(Jarmu jarmu) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SzerviznaploKepernyo(vehicle: jarmu),
      ),
    );
    _loadVehicles(); // Frissítünk, hátha változott valami
  }

  // JAVÍTVA: A helyes, egységes 'delete' metódust hívja
  void _deleteVehicle(int id) async {
    final db = AdatbazisKezelo.instance;
    await db.delete('vehicles', id);
    _loadVehicles();
  }

  void _showDeleteConfirmation(Jarmu jarmu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
              'Jármű Törlése', style: TextStyle(color: Colors.white)),
          content: Text(
            'Biztosan törölni szeretnéd a(z) ${jarmu.make} ${jarmu
                .model} járművet és minden hozzá tartozó adatot?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                  'Mégse', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8)),
              child: const Text(
                  'Törlés', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _deleteVehicle(jarmu.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Válassz Járművet' : 'Járműpark'),
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
            final jarmuvek = snapshot.data ?? [];
            if (jarmuvek.isEmpty) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, size: 80,
                          color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      const Text(
                        'Még nincsenek járművek rögzítve.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nyomj a "+" gombra egy új jármű hozzáadásához.',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ));
            }
            return ListView.builder(
              itemCount: jarmuvek.length,
              itemBuilder: (context, index) {
                final jarmu = jarmuvek[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    title: Text(
                      '${jarmu.make} ${jarmu.model}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${jarmu.year} - ${jarmu.licensePlate}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      if (widget.selectionMode) {
                        Navigator.of(context).pop(jarmu);
                      } else {
                        // Normál módban a szerviznaplóra navigálunk
                        _navigateToServiceLog(jarmu);
                      }
                    },
                    trailing: widget.selectionMode
                        ? null
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // JAVÍTVA: Az ikon a szerkesztésre visz
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.amber),
                          tooltip: 'Jármű szerkesztése',
                          onPressed: () =>
                              _navigateAndReload(
                                  JarmuHozzaadasa(vehicleToEdit: jarmu)),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Jármű törlése',
                          onPressed: () => _showDeleteConfirmation(jarmu),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
      floatingActionButton: widget.selectionMode
          ? null
          : FloatingActionButton(
        onPressed: () => _navigateAndReload(const JarmuHozzaadasa()),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}