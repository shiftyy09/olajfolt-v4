import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/szolgaltatasok/csv_szolgaltatas.dart'; // ÚJ IMPORT
import 'package:car_maintenance_app/szolgaltatasok/pdf_szolgaltatas.dart';
import 'package:car_maintenance_app/widgetek/kozos_widgetek.dart';
import 'package:flutter/material.dart';

class BeallitasokKepernyo extends StatefulWidget {
  const BeallitasokKepernyo({super.key});

  @override
  State<BeallitasokKepernyo> createState() => _BeallitasokKepernyoState();
}

class _BeallitasokKepernyoState extends State<BeallitasokKepernyo> {
  final PdfSzolgaltatas _pdfSzolgaltatas = PdfSzolgaltatas();
  final CsvSzolgaltatas _csvSzolgaltatas = CsvSzolgaltatas(); // ÚJ PÉLDÁNY
  bool _isPdfExporting = false;
  bool _isCsvExporting = false; // ÚJ ÁLLAPOT

  // PDF Export (VÁLTOZATLAN)
  Future<void> _handlePdfExport() async {
    setState(() => _isPdfExporting = true);

    final db = AdatbazisKezelo.instance;
    final vehiclesMap = await db.getVehicles();
    final vehicles = vehiclesMap.map((map) => Jarmu.fromMap(map)).toList();

    if (!mounted) {
      setState(() => _isPdfExporting = false);
      return;
    }

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nincs jármű a parkban, nincs mit exportálni!'),
          backgroundColor: Colors.redAccent));
      setState(() => _isPdfExporting = false);
      return;
    }

    final Jarmu? selectedVehicle = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Válassz járművet',
                style: TextStyle(color: Colors.white)),
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
      setState(() => _isPdfExporting = false);
      return;
    }

    final ExportAction? action = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Válassz műveletet',
                style: TextStyle(color: Colors.white)),
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
                  title: const Text('Megosztás...',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.of(context).pop(ExportAction.share),
                ),
              ],
            ),
          ),
    );

    if (action == null) {
      setState(() => _isPdfExporting = false);
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
          SnackBar(
              content: Text('Hiba az exportálás során: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isPdfExporting = false);
  }

  // === ÚJ FUNKCIÓ: CSV Export ===
  Future<void> _handleCsvExport() async {
    setState(() => _isCsvExporting = true);

    final String? filePath = await _csvSzolgaltatas.exportAllDataToCsv();

    if (!mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Minden adat sikeresen exportálva a "Letöltések" mappába!'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Hiba a CSV exportálás során.'),
        backgroundColor: Colors.redAccent,
      ));
    }

    setState(() => _isCsvExporting = false);
  }


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
          _buildSectionHeader(context, 'Adatkezelés'),
          KozosMenuKartya(
            icon: Icons.picture_as_pdf,
            title: 'Adatlap exportálása (PDF)',
            subtitle: 'Generálj egy adatlapot a járművedről',
            color: Colors.red.shade400,
            onTap: _isPdfExporting ? () {} : _handlePdfExport,
            trailing: _isPdfExporting
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
            onTap: _isCsvExporting ? () {} : _handleCsvExport,
            // CSERÉLVE
            trailing: _isCsvExporting // ÚJ
                ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
                : null,
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
          _buildSectionHeader(context, 'Értesítések'),
          KozosMenuKartya(
            icon: Icons.notifications_active,
            title: 'Karbantartás értesítések',
            subtitle: 'Értesítés a közelgő eseményekről',
            color: Colors.orange.shade400,
            onTap: () {},
            trailing: Switch(
              value: false,
              onChanged: (bool value) {},
              activeColor: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Információ'),
          KozosMenuKartya(
            icon: Icons.info_outline,
            title: 'Névjegy',
            subtitle: 'Verzió: 1.0.0',
            color: Colors.orange.shade400,
            onTap: () {},
          ),
        ],
      ),
    );
  }

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