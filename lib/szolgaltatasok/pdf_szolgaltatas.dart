import 'dart:io';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/modellek/karbantartas_bejegyzes.dart';
import 'package:device_info_plus/device_info_plus.dart'; // <--- ÚJ FONTOS IMPORT
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
        .toList();

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    final appLogoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/olajfoltiras.png')).buffer
            .asUint8List());
    final vehicleBrandLogo = await _getVehicleBrandLogo(vehicle.make);

    const accentColor = PdfColor.fromInt(0xFFF57C00);
    const headerColor = PdfColors.black;

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) =>
            _buildPdfHeader(appLogoImage, headerColor),
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

  // --- JAVÍTVA: Mentés logikája modern Android verziókhoz ---
  Future<bool> _saveToDevice(Uint8List bytes, String fileName) async {
    // A modern Android verziókon (10+) nincs szükség külön engedélyre a 'Downloads' mappába való íráshoz.
    // A régebbi verziókhoz viszont kellhet, ezért egy verzió-ellenőrzést végzünk.
    if (Platform.isAndroid) {
      // Csak Android 9 (API 28) és régebbi verziókon kérünk engedélyt.
      // Az újabbaknál a rendszer automatikusan engedélyezi a mentést a Letöltésekbe.
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt <= 28) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          print("Nincs engedély a tárhely írására régebbi Android verzión.");
          return false;
        }
      }
    }
    // iOS-en a Downloads mappa elérése automatikusan engedélyezett

    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        print("Letöltések mappa nem található.");
        return false;
      }
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('Fájl sikeresen mentve ide: $filePath');
      return true;
    } catch (e) {
      print('Hiba a fájl mentésekor: $e');
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
        text: 'Szervizlap a(z) járműről.',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      return true;
    } catch (e) {
      print('Hiba a fájl megosztásakor: $e');
      return false;
    }
  }

  Future<pw.MemoryImage?> _getVehicleBrandLogo(String brand) async {
    try {
      final domain = brand.toLowerCase().replaceAll(' ', '') + '.com';
      final url = Uri.parse('https://logo.clearbit.com/$domain');
      final response =
      await http.get(url, headers: {'User-Agent': 'car_maintenance_app/1.0'});
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      print("Márkalogó letöltési hiba: $e");
    }
    return null;
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo, PdfColor headerColor) {
    return pw.Container(
      height: 70,
      color: headerColor,
      child: pw.Center(
        child: pw.Image(logo, fit: pw.BoxFit.contain),
      ),
    );
  }

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
                pw.Text(
                  '${vehicle.make} ${vehicle.model}',
                  style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  vehicle.licensePlate,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: accentColor),
                ),
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
              child: pw.Container(
                height: 80,
                child: pw.Image(brandLogo, fit: pw.BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  pw.TableRow _buildInfoRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(
            label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Text(value),
      ),
    ]);
  }

  pw.Widget _buildPdfSectionTitle(String title, PdfColor accentColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
                color: accentColor)),
        pw.Container(
            height: 2,
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
        pw.Text('Generálva: ${DateFormat('yyyy.MM.dd HH:mm').format(
            DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Text('Olajfolt Szerviz-napló App v1.0',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }
}