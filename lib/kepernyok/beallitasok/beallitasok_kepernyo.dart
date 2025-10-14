// lib/kepernyok/beallitasok/beallitasok_kepernyo.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/modellek/karbantartas_bejegyzes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class BeallitasokKepernyo extends StatelessWidget {
  const BeallitasokKepernyo({super.key});

  Future<void> _selectVehicleAndExport(BuildContext context) async {
    final db = AdatbazisKezelo.instance;
    final vehiclesMap = await db.getVehicles();
    final vehicles = vehiclesMap.map((map) => Jarmu.fromMap(map)).toList();

    if (!context.mounted) return;

    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nincs jármű a parkban, nincs mit exportálni!'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final Jarmu? selectedVehicle = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Válassz járművet',
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    '${vehicles[index].make} ${vehicles[index].model}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.of(context).pop(vehicles[index]),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedVehicle != null) {
      await _exportToPdf(context, selectedVehicle);
    }
  }

  Future<pw.MemoryImage?> _getVehicleBrandLogo(String brand) async {
    try {
      final domain = brand.toLowerCase().replaceAll(' ', '') + '.com';
      final url = Uri.parse('https://logo.clearbit.com/$domain');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print("Márkalogó letöltési hiba: $e");
    }
    return null;
  }

  Future<void> _exportToPdf(BuildContext context, Jarmu vehicle) async {
    final pdf = pw.Document();
    final db = AdatbazisKezelo.instance;

    final serviceRecordsMap = await db.getServicesForVehicle(vehicle.id!);
    final serviceRecords = serviceRecordsMap.map((map) => Szerviz.fromMap(map)).toList();

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    final appLogoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/olajfoltiras.png')).buffer.asUint8List(),
    );

    final vehicleBrandLogo = await _getVehicleBrandLogo(vehicle.make);

    const accentColor = PdfColor.fromInt(0xFFF57C00); // Narancssárga
    const headerColor = PdfColors.black; // Fekete

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => _buildPdfHeader(appLogoImage, headerColor),
        footer: (pw.Context context) => _buildPdfFooter(),
        build: (pw.Context context) {
          return [
            _buildVehicleInfoSection(vehicle, vehicleBrandLogo, accentColor),
            pw.SizedBox(height: 25),
            _buildPdfSectionTitle('Szerviztörténet', accentColor),
            _buildServiceHistoryTable(serviceRecords, accentColor),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final fileName = 'szervizlap_${vehicle.make}_${vehicle.licensePlate}.pdf'.replaceAll(' ', '_');
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      Share.shareXFiles(
        [XFile(file.path)],
        text: 'Szervizlap a(z) ${vehicle.make} ${vehicle.model} járműről.',
      );
    } catch (e) {
      print('PDF Export Hiba: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hiba a PDF exportálás során: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // === JAVÍTVA: Középre igazított logó és fekete háttér ===
  pw.Widget _buildPdfHeader(pw.MemoryImage logo, PdfColor headerColor) {
    return pw.Container(
      height: 70,
      // A háttérszín most már fixen fekete, hogy a logó háttere beleolvadjon
      color: PdfColors.black,
      // A child egy Center widget, ami középre igazítja a logót
      child: pw.Center(
        child: pw.Image(
          logo,
          fit: pw.BoxFit.contain, // A logó méretezése, hogy beleférjen
        ),
      ),
    );
  }

  pw.Widget _buildVehicleInfoSection(Jarmu vehicle, pw.MemoryImage? brandLogo, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  vehicle.licensePlate,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: accentColor),
                ),
                pw.SizedBox(height: 10),
                _buildInfoRow('Évjárat:', vehicle.year.toString()),
                _buildInfoRow('Vezérlés:', vehicle.vezerlesTipusa ?? '-'),
                _buildInfoRow('Alvázszám:', vehicle.vin ?? '-'),
              ],
            ),
          ),
          if (brandLogo != null)
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                height: 80,
                child: pw.Image(brandLogo, fit: pw.BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSectionTitle(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: accentColor)),
        pw.Container(height: 2, color: PdfColors.grey300, margin: const pw.EdgeInsets.only(top: 3, bottom: 10)),
      ],
    );
  }

  pw.Widget _buildServiceHistoryTable(List<Szerviz> records, PdfColor accentColor) {
    if (records.isEmpty) {
      return pw.Text('Nincsenek rögzített szervizesemények.');
    }
    const headers = ['Dátum', 'KM állás', 'Leírás', 'Költség'];
    final data = records.map((record) {
      return [
        DateFormat('yyyy.MM.dd').format(record.date),
        '${NumberFormat.decimalPattern('hu_HU').format(record.mileage)} km',
        record.description,
        '${NumberFormat.decimalPattern('hu_HU').format(record.cost)} Ft'
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: accentColor),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generálva: ${DateFormat('yyyy.MM.dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text('Olajfolt Szerviz-napló App v1.0', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  // === A FELÜLETET ÉPÍTŐ WIDGETEK (VÁLTOZATLANOK) ===
  @override
  Widget build(BuildContext context) {
    // ... (A build függvényed és a hozzá tartozó segédfüggvények változatlanul maradnak)
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Beállítások'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          _buildSectionHeader(context, 'Adatkezelés'),
          _buildSettingsTile(
            icon: Icons.picture_as_pdf,
            title: 'Adatlap exportálása (PDF)',
            subtitle: 'Generálj egy adatlapot a járművedről',
            onTap: () {
              _selectVehicleAndExport(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Teljes mentés készítése (CSV)',
            subtitle: 'Minden adat kimentése importáláshoz',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV export funkció hamarosan...')),
              );
            },
          ),
          const Divider(color: Colors.white24, indent: 16, endIndent: 16),
          _buildSectionHeader(context, 'Értesítések'),
          _buildSwitchTile(
              icon: Icons.notifications_active,
              title: 'Karbantartás PUSH üzenetek',
              subtitle: 'Értesítés a közelgő eseményekről',
              value: true,
              onChanged: (bool value) {}),
          const Divider(color: Colors.white24, indent: 16, endIndent: 16),
          _buildSectionHeader(context, 'Információ'),
          _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'Névjegy',
              subtitle: 'Verzió: 1.0.0',
              onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
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

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title:
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.orange,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      ),
    );
  }
}
