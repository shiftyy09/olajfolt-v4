import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';

class SzerviznaploKepernyo extends StatefulWidget {
  final Jarmu vehicle;

  const SzerviznaploKepernyo({super.key, required this.vehicle});

  @override
  State<SzerviznaploKepernyo> createState() => _SzerviznaploKepernyoState();
}

class _SzerviznaploKepernyoState extends State<SzerviznaploKepernyo> {
  late Future<List<Szerviz>> _serviceRecordsFuture;
  late Jarmu _currentVehicle;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadServiceRecords();
  }

  void _loadServiceRecords() {
    setState(() {
      _serviceRecordsFuture = AdatbazisKezelo.instance
          .getServicesForVehicle(_currentVehicle.id!)
          .then((maps) => maps.map((map) => Szerviz.fromMap(map)).toList());
    });
  }

  // === ÚJ WIDGET: INFORMÁCIÓS ABLAK MEGNYITÁSA ===
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.cyanAccent),
                SizedBox(width: 10),
                Text('Hogyan működik?', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ez a képernyő a járműved összes rögzített eseményét mutatja, a legújábbal elöl.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Itt láthatod:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• A manuálisan felvett szervizeket (narancs).',
                      style: TextStyle(color: Colors.white70)),
                  Text('• A tankolásokat (zöld).',
                      style: TextStyle(color: Colors.white70)),
                  Text('• Az automatikus emlékeztetőket (piros).',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                    'Értem', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          ),
    );
  }


  Future<void> _addOrEditService({Szerviz? record}) async {
    final descriptionController = TextEditingController(
        text: record?.description);
    final costController = TextEditingController(
        text: record?.cost.toString() == '0' ? '' : record?.cost.toString());
    final mileageController = TextEditingController(
        text: record?.mileage.toString());
    DateTime selectedDate = record?.date ?? DateTime.now();

    final bool? success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Text(
                  record == null ? 'Új Szervizesemény' : 'Esemény Szerkesztése',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                        descriptionController, 'Leírás (pl. Olajcsere)',
                        Icons.description),
                    const SizedBox(height: 16),
                    _buildTextField(costController, 'Költség (Ft)', Icons.paid,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField(
                        mileageController, 'Kilométeróra-állás', Icons.speed,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildDatePicker(
                      selectedDate,
                          (newDate) =>
                          setDialogState(() => selectedDate = newDate),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                      'Mégse', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (descriptionController.text.isEmpty) return;
                    final newRecord = Szerviz(
                      id: record?.id,
                      vehicleId: _currentVehicle.id!,
                      description: descriptionController.text,
                      date: selectedDate,
                      cost: int.tryParse(costController.text) ?? 0,
                      mileage: int.tryParse(mileageController.text) ?? 0,
                    );

                    final db = AdatbazisKezelo.instance;
                    if (record == null) {
                      await db.insert('services', newRecord.toMap());
                    } else {
                      await db.update('services', newRecord.toMap());
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                  child: const Text('Mentés', style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      _loadServiceRecords();
    }
  }

  // Dialógus ablakhoz tartozó segéd-widgetek
  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2)),
      ),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number ? [
        FilteringTextInputFormatter.digitsOnly
      ] : [],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kérjük, töltse ki a mezőt!';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(DateTime date, Function(DateTime) onDateChanged) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != date) {
          onDateChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                    Icons.calendar_today, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Text(DateFormat('yyyy. MM. dd.').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${_currentVehicle.make} Szerviznapló'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: _showInfoDialog,
            tooltip: 'Hogyan működik?',
          ),
        ],
      ),
      body: FutureBuilder<List<Szerviz>>(
        future: _serviceRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Hiba történt: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nincsenek rögzített események.',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Hely a FAB-nak
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(records[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditService(),
        backgroundColor: Colors.orange,
        tooltip: 'Új szervizesemény',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // === ÚJ WIDGET: A LÁTVÁNYOS SZERVIZKÁRTYA ===
  Widget _buildServiceCard(Szerviz record) {
    // Színkódolás a bejegyzés típusa alapján
    final String desc = record.description.toLowerCase();
    final Color cardColor;
    final IconData cardIcon;

    if (desc.startsWith('tankolás')) {
      cardColor = Colors.green;
      cardIcon = Icons.local_gas_station;
    } else if (desc.contains('esedékes')) {
      cardColor = Colors.red.shade400;
      cardIcon = Icons.warning_amber_rounded;
    } else {
      cardColor = Colors.orange;
      cardIcon = Icons.build;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: cardColor.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () => _addOrEditService(record: record),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(cardIcon, color: cardColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      record.description,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(
                    Icons.calendar_today,
                    DateFormat('yyyy. MM. dd.').format(record.date),
                  ),
                  _buildInfoColumn(
                    Icons.speed,
                    '${NumberFormat.decimalPattern('hu_HU').format(
                        record.mileage)} km',
                  ),
                  if (record.cost > 0)
                    _buildInfoColumn(
                      Icons.paid,
                      '${NumberFormat.decimalPattern('hu_HU').format(
                          record.cost)} Ft',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Segéd-widget a kártya alján lévő információs oszlopokhoz
  Widget _buildInfoColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}