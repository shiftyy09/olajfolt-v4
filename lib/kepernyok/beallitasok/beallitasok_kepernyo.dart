import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/szolgaltatasok/pdf_szolgaltatas.dart';
import 'package:car_maintenance_app/widgetek/kozos_menu_kartya.dart'; // <-- ÚJ IMPORT
import 'package:flutter/material.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  bool _isExporting = false;

  Future<void> _handlePdfExport() async {
    setState(() => _isExporting = true);

    final db = AdatbazisKezelo.instance;
    final vehiclesMap = await db.getVehicles();
    final vehicles = vehiclesMap.map((map) => Jarmu.fromMap(map)).toList();

    if (!mounted) {
      setState(() => _isExporting = false);
      return;
    }

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nincs jármű a parkban, nincs mit exportálni!'),
          backgroundColor: Colors.redAccent));
      setState(() => _isExporting = false);
      return;
    }

    final Jarmu? selectedVehicle = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
                'Válassz járművet', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: vehicles.length,
                itemBuilder: (context, index) =>
                    ListTile(
                      title: Text(
                          '${vehicles[index].make} ${vehicles[index].model}',
                          style: const TextStyle(color: Colors.white)),
                      onTap: () => Navigator.of(context).pop(vehicles[index]),
                    ),
              ),
            ),
          ),
    );

    if (selectedVehicle == null) {
      setState(() => _isExporting = false);
      return;
    }

    final ExportAction? action = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
                'Válassz műveletet', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt, color: Colors.white70),
                  title: const Text('Mentés a telefonra',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(context).pop(ExportAction.save),
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.white70),
                  title: const Text(
                      'Megosztás...', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(context).pop(ExportAction.share),
                ),
              ],
            ),
          ),
    );

    if (action == null) {
      setState(() => _isExporting = false);
      return;
    }

    try {
      final bool success = await _pdfSzolgaltatas.createAndExportPdf(
          selectedVehicle, context, action);

      if (mounted && success && action == ExportAction.save) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PDF sikeresen mentve a "Letöltések" mappába!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hiba az exportálás során: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isExporting = false);
  }

  // === FELÜLET ÉPÍTÉSE AZ ÚJ WIDGETTEL ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        children: [
          // ADATKEZELÉS SZEKCIÓ
          _buildSectionHeader(context, 'Adatkezelés'),
          KozosMenuKartya(
            icon: Icons.picture_as_pdf,
            title: 'Adatlap exportálása (PDF)',
            subtitle: 'Generálj egy adatlapot a járművedről',
            color: Colors.red.shade400,
            onTap: _isExporting ? () {} : _handlePdfExport,
            trailing: _isExporting
                ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
          KozosMenuKartya(
            icon: Icons.upload_file,
            title: 'Mentés exportálása (CSV)',
            subtitle: 'Minden adat kimentése egyetlen fájlba',
            color: Colors.blue.shade400,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('CSV export funkció hamarosan...')),
              );
            },
          ),
          KozosMenuKartya(
            icon: Icons.download,
            title: 'Mentés importálása (CSV)',
            subtitle: 'Adatok visszatöltése mentésből',
            color: Colors.green.shade400,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('CSV import funkció hamarosan...')),
              );
            },
          ),

          const SizedBox(height: 20),

          // ÉRTESÍTÉSEK SZEKCIÓ
          _buildSectionHeader(context, 'Értesítések'),
          KozosMenuKartya(
            icon: Icons.notifications_active,
            title: 'Karbantartás értesítések',
            subtitle: 'Értesítés a közelgő eseményekről',
            color: Colors.orange.shade400,
            onTap: () {},
            // A kártya is kattintható lehet, vagy csak a switch
            trailing: Switch(
              value: false, // Inaktív alapból, amíg nincs kész
              onChanged: (bool value) {},
              activeColor: Colors.orange.shade400,
            ),
          ),

          const SizedBox(height: 20),

          // INFORMÁCIÓ SZEKCIÓ
          _buildSectionHeader(context, 'Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 1.0.0',
            color: Colors.purple.shade300,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Szekció cím widget
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.orange.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}