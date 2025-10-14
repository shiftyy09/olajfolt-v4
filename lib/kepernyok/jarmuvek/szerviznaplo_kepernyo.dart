import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';

// === JAVÍTÁS 1: A HELYES, ÚJ SZERVIZ MODELL IMPORTÁLÁSA ===
import '../../modellek/karbantartas_bejegyzes.dart';

class SzerviznaploKepernyo extends StatefulWidget {
  final Jarmu vehicle;

  const SzerviznaploKepernyo({super.key, required this.vehicle});

  @override
  State<SzerviznaploKepernyo> createState() => _SzerviznaploKepernyoState();
}

class _SzerviznaploKepernyoState extends State<SzerviznaploKepernyo> {
  // === JAVÍTÁS 2: A FUTURE MÁR SZERVIZ LISTÁT VÁR ===
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
      // === JAVÍTÁS 3: A HELYES ADATBÁZIS FÜGGVÉNY HÍVÁSA ===
      _serviceRecordsFuture = AdatbazisKezelo.instance
          .getServicesForVehicle(_currentVehicle.id!)
          .then((maps) => maps.map((map) => Szerviz.fromMap(map)).toList());
    });
  }

  Future<void> _addOrEditService({Szerviz? record}) async {
    // Vezérlők inicializálása a felugró ablakhoz
    final descriptionController = TextEditingController(
        text: record?.description);
    final costController = TextEditingController(text: record?.cost.toString());
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
                          (newDate) {
                        setDialogState(() => selectedDate = newDate);
                      },
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

                    // === JAVÍTÁS 4: ÚJ SZERVIZ OBJEKTUM LÉTREHOZÁSA ===
                    final newRecord = Szerviz(
                      id: record?.id,
                      vehicleId: _currentVehicle.id!,
                      description: descriptionController.text,
                      date: selectedDate,
                      cost: int.tryParse(costController.text) ?? 0,
                      mileage: int.tryParse(mileageController.text) ?? 0,
                    );

                    final db = AdatbazisKezelo.instance;
                    // === JAVÍTÁS 5: A HELYES TÁBLÁBA MENTÜNK ===
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
      _loadServiceRecords(); // Adatok újratöltése mentés után
    }
  }

  // === ÚJ, LETISZTULT WIDGET ÉPÍTŐK A FELUGRÓ ABLAKHOZ ===

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange)),
      ),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number ? [
        FilteringTextInputFormatter.digitsOnly
      ] : [],
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
        decoration: BoxDecoration(color: const Color(0xFF252525),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                    Icons.calendar_today, color: Colors.white70, size: 20),
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
      ),
      // === JAVÍTÁS 6: A FUTUREBUILDER IS SZERVIZ TÍPUST VÁR ===
      body: FutureBuilder<List<Szerviz>>(
        future: _serviceRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hiba: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nincsenek szervizbejegyzések.',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
            );
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 8),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    title: Text(
                        record.description, style: const TextStyle(color: Colors
                        .orange, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${NumberFormat
                          .currency(
                          locale: 'hu_HU', symbol: 'Ft', decimalDigits: 0)
                          .format(record.cost)}\n'
                          '${DateFormat('yyyy. MM. dd.').format(record
                          .date)} • ${record.mileage} km',
                      style: const TextStyle(color: Colors.white70,
                          height: 1.5),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _addOrEditService(record: record),
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final bool? confirm = await showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: const Text('Törlés megerősítése',
                                        style: TextStyle(color: Colors.white)),
                                    content: const Text(
                                        'Biztosan törölni szeretnéd ezt a bejegyzést?',
                                        style: TextStyle(
                                            color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Mégse'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Törlés',
                                            style: TextStyle(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              // === JAVÍTÁS 7: A HELYES 'services' TÁBLÁBÓL TÖRLÜNK ===
                              await AdatbazisKezelo.instance.delete(
                                  'services', record.id!);
                              _loadServiceRecords();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () => _addOrEditService(record: record),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditService(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}