// lib/kepernyok/karbantartas/karbantartas_lista.dart
import 'package:flutter/material.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/karbantartas.dart';
import '../jarmuvek/szerviz_hozzaadasa.dart';

class KarbantartasLista extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;

  const KarbantartasLista({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<KarbantartasLista> createState() => _KarbantartasListaState();
}

class _KarbantartasListaState extends State<KarbantartasLista> {
  late Future<List<Karbantartas>> _maintenanceFuture;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _refreshMaintenanceList();
  }

  void _refreshMaintenanceList() {
    setState(() {
      _maintenanceFuture = AdatbazisKezelo.instance
          .getMaintenanceForVehicle(widget.vehicleId)
          .then((maps) =>
          maps.map((map) => Karbantartas.fromMap(map)).toList());
    });
  }

  void _navigateAndRefresh({Karbantartas? serviceToEdit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SzervizHozzaadasa(
              vehicleId: widget.vehicleId,
              serviceToEdit: serviceToEdit,
            ),
      ),
    );
    if (result == true) {
      _dataChanged = true;
      _refreshMaintenanceList();
    }
  }

  void _deleteService(Karbantartas service) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
                'Törlés megerősítése', style: TextStyle(color: Colors.white)),
            content: const Text(
                'Biztosan törölni szeretnéd ezt a szervizbejegyzést?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Mégse')),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                      'Törlés', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
    );

    if (confirmed == true) {
      await AdatbazisKezelo.instance.delete('maintenance', service.id!);
      _dataChanged = true;
      _refreshMaintenanceList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // JAVÍTVA: A WillPopScope lecserélve a modern PopScope-ra
    return PopScope(
      canPop: false, // A rendszer alapértelmezett visszalépését letiltjuk
      onPopInvoked: (bool didPop) {
        // Ha a rendszer megpróbál visszalépni (pl. gesztussal), akkor fut le ez
        if (didPop) return;
        Navigator.pop(context, _dataChanged);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Szerviznapló'),
              Text(widget.vehicleName,
                  style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          // A vezető ikon is a PopScope logikáját használja
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _dataChanged),
          ),
        ),
        body: FutureBuilder<List<Karbantartas>>(
            future: _maintenanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hiba: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nincsenek szervizbejegyzések.',
                    style: TextStyle(color: Colors.white70, fontSize: 18)));
              }
              final maintenanceRecords = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: maintenanceRecords.length,
                itemBuilder: (context, index) {
                  final record = maintenanceRecords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      title: Text(record.serviceType,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      // JAVÍTVA: A 'cost' mezőre való hivatkozás eltávolítva
                      subtitle: Text(
                          '${record.date.substring(0, 10)} - ${record
                              .mileage} km',
                          style: const TextStyle(
                              color: Colors.white70, height: 1.5)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.amber),
                            onPressed: () =>
                                _navigateAndRefresh(serviceToEdit: record),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteService(record),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateAndRefresh(),
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}