// lib/kepernyok/jarmuvek/szerviznaplo_kepernyo.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas.dart';

class SzerviznaploKepernyo extends StatefulWidget {
  final Jarmu vehicle;

  const SzerviznaploKepernyo({super.key, required this.vehicle});

  @override
  State<SzerviznaploKepernyo> createState() => _SzerviznaploKepernyoState();
}

class _SzerviznaploKepernyoState extends State<SzerviznaploKepernyo> {
  late Future<List<Karbantartas>> _maintenanceRecordsFuture;
  late Jarmu _currentVehicle;

  // JAVÍTVA: A felesleges vezérlők törölve
  final _mileageController = TextEditingController();
  String? _selectedServiceType;
  DateTime _selectedDate = DateTime.now();

  final List<String> _serviceTypes = [
    'Olajcsere',
    'Levegőszűrő csere',
    'Pollenszűrő csere',
    'Üzemanyagszűrő csere',
    'Vezérműszíj/lánc csere',
    'Akkumulátor csere',
    'Fékbetét csere (első)',
    'Fékbetét csere (hátsó)',
    'Fékfolyadék csere',
    'Hűtőfolyadék csere',
    'Műszaki vizsga',
    'Egyéb ellenőrzés',
  ];

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
    _loadMaintenanceRecords();
  }

  void _loadMaintenanceRecords() {
    setState(() {
      _maintenanceRecordsFuture = AdatbazisKezelo.instance
          .getMaintenanceForVehicle(_currentVehicle.id!)
          .then((maps) =>
          maps.map((map) => Karbantartas.fromMap(map)).toList());
    });
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditMaintenance({Karbantartas? record}) async {
    _selectedServiceType = record?.serviceType;
    _mileageController.text = record?.mileage.toString() ?? '';
    _selectedDate =
    record != null ? DateTime.parse(record.date) : DateTime.now();

    final bool? success = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(record == null
                  ? 'Új Szervizbejegyzés'
                  : 'Bejegyzés Szerkesztése',
                  style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Szerviz típus választó
                    _buildDropdown(setDialogState),
                    const SizedBox(height: 16),
                    // Dátum választó
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    // Km óra állás
                    _buildTextField(_mileageController, 'Kilométeróra-állás',
                        TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                      'Mégse', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: () async {
                    if (_selectedServiceType == null) return;
                    if (_mileageController.text.isEmpty &&
                        _selectedServiceType != 'Műszaki vizsga') return;

                    // JAVÍTVA: A Karbantartas objektum a helyes, egyszerűsített formában jön létre
                    final newRecord = Karbantartas(
                      id: record?.id,
                      vehicleId: _currentVehicle.id!,
                      serviceType: _selectedServiceType!,
                      date: _selectedDate.toIso8601String(),
                      mileage: int.tryParse(_mileageController.text) ?? 0,
                    );

                    final db = AdatbazisKezelo.instance;
                    if (record == null) {
                      await db.insert('maintenance', newRecord.toMap());
                    } else {
                      await db.update('maintenance', newRecord.toMap());
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                      'Mentés', style: TextStyle(color: Colors.orange)),
                ),
              ],
            );
          },
        );
      },
    );

    if (success == true) {
      _loadMaintenanceRecords();
    }
  }

  Widget _buildDropdown(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedServiceType,
          hint: const Text('Válassz szerviz típust...',
              style: TextStyle(color: Colors.white70)),
          isExpanded: true,
          dropdownColor: const Color(0xFF252525),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
          onChanged: (String? newValue) {
            setDialogState(() {
              _selectedServiceType = newValue;
            });
          },
          items: _serviceTypes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('yyyy. MM. dd.').format(_selectedDate),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      TextInputType keyboardType) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
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
      body: FutureBuilder<List<Karbantartas>>(
        future: _maintenanceRecordsFuture,
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
                        record.serviceType, style: const TextStyle(color: Colors
                        .orange, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${DateFormat('yyyy. MM. dd.').format(DateTime.parse(
                          record.date))}\n${record.mileage} km',
                      style: const TextStyle(color: Colors.white70,
                          height: 1.4),
                    ),
                    // JAVÍTVA: A 'cost' megjelenítése el lett távolítva
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.edit, color: Colors.blueAccent),
                          onPressed: () =>
                              _addOrEditMaintenance(record: record),
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
                              await AdatbazisKezelo.instance.delete(
                                  'maintenance', record.id!);
                              _loadMaintenanceRecords();
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () => _addOrEditMaintenance(record: record),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditMaintenance(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}