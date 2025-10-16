import 'dart:io';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/modellek/karbantartas_bejegyzes.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../alap/adatbazis/adatbazis_kezelo.dart';

enum ExportAction { save, share }

class PdfSzolgaltatas {
  Future<bool> createAndExportPdf(Jarmu vehicle, BuildContext context,
      ExportAction action) async {
    final pdf = pw.Document();
    final bytes = await _buildPdf(pdf, vehicle);
    if (bytes == null) return false;

    final fileName = 'szervizlap_${vehicle.make}_${vehicle.licensePlate}.pdf'
        .replaceAll(' ', '_');

    if (action == ExportAction.save) {
      return await _saveToDevice(bytes, fileName);
    } else {
      return await _shareFile(bytes, fileName, context);
    }
  }

  Future<Uint8List?> _buildPdf(pw.Document pdf, Jarmu vehicle) async {
    final db = AdatbazisKezelo.instance;
    final serviceRecordsMap = await db.getServicesForVehicle(vehicle.id!);
    final serviceRecords = serviceRecordsMap
        .map((map) => Szerviz.fromMap(map))
        .where((szerviz) =>
    !szerviz.description.toLowerCase().contains('tankolás'))
        .toList();

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    // === AZ ÚJ FEJLÉC KÉP BETÖLTÉSE ===
    final headerImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/pdf_fejlec.png')).buffer
            .asUint8List());

    final vehicleBrandLogo = await _getVehicleBrandLogo(vehicle.make);

    const accentColor = PdfColor.fromInt(0xFFF57C00);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        // === ITT HASZNÁLJUK AZ ÚJ FEJLÉCFÜGGVÉNYT ===
        header: (pw.Context context) => _buildPdfHeader(headerImage),
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
    return pdf.save();
  }

  // --- Mentés és megosztás (változatlan) ---
  Future<bool> _saveToDevice(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt <= 28) {
        var status = await Permission.storage.request();
        if (!status.isGranted) return false;
      }
    }
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) return false;
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _shareFile(Uint8List bytes, String fileName,
      BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Szervizlap a járműről.',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Logó letöltés (változatlan) ---
  Future<pw.MemoryImage?> _getVehicleBrandLogo(String brand) async {
    try {
      final domain = brand.toLowerCase().replaceAll(' ', '') + '.com';
      final url = Uri.parse('https://logo.clearbit.com/$domain');
      final response = await http.get(
          url, headers: {'User-Agent': 'car_maintenance_app/1.0'});
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print("Márkalogó letöltési hiba: $e");
    }
    return null;
  }

  // ==========================================================
  // === EZ AZ ÚJ, LEBUTÍTOTT FEJLÉC FÜGGVÉNY ===
  // ==========================================================
  pw.Widget _buildPdfHeader(pw.MemoryImage headerImage) {
    return pw.Container(
      height: 80, // A magasságot megtartjuk, hogy az arányok jók legyenek
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Image(headerImage,
          fit: pw.BoxFit.fill), // Kitölti a rendelkezésre álló helyet
    );
  }

  // --- A kód többi része változatlan marad ---
  pw.Widget _buildVehicleInfoSection(Jarmu vehicle, pw.MemoryImage? brandLogo,
      PdfColor accentColor) {
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
                pw.Text('${vehicle.make} ${vehicle.model}', style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 22)),
                pw.SizedBox(height: 5),
                pw.Text(vehicle.licensePlate, style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                    color: accentColor)),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    _buildInfoRow('Évjárat:', vehicle.year.toString()),
                    _buildInfoRow('Vezérlés:', vehicle.vezerlesTipusa ?? '-'),
                    _buildInfoRow('Alvázszám:', vehicle.vin ?? '-'),
                  ],
                ),
              ],
            ),
          ),
          if (brandLogo != null)
            pw.Expanded(
              flex: 2,
              child: pw.SizedBox(height: 80,
                  child: pw.Image(brandLogo, fit: pw.BoxFit.contain)),
            ),
        ],
      ),
    );
  }

  pw.TableRow _buildInfoRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(padding: const pw.EdgeInsets.all(2),
          child: pw.Text(
              label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(value)),
    ]);
  }

  pw.Widget _buildPdfSectionTitle(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 16, color: accentColor)),
        pw.Container(height: 2,
            color: PdfColors.grey300,
            margin: const pw.EdgeInsets.only(top: 3, bottom: 10)),
      ],
    );
  }

  pw.Widget _buildServiceHistoryTable(List<Szerviz> records,
      PdfColor accentColor) {
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
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: accentColor),
      rowDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight,
        2: pw.Alignment.centerLeft, 3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generálva: ${DateFormat('yyyy.MM.dd HH:mm').format(
            DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text('Olajfolt Szerviz-napló App v1.0',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }
}