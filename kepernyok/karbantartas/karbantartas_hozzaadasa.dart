import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';

class KarbantartasHozzaadasa extends StatefulWidget {
  final int vehicleId;

  const KarbantartasHozzaadasa({super.key, required this.vehicleId});

  @override
  State<KarbantartasHozzaadasa> createState() =>
      _KarbantartasHozzaadasaState();
}

class _KarbantartasHozzaadasaState extends State<KarbantartasHozzaadasa> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();
  final _servicePlaceController = TextEditingController();
  final _laborCostController = TextEditingController();
  final _partsCostController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _mileageController.dispose();
    _servicePlaceController.dispose();
    _laborCostController.dispose();
    _partsCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMaintenance() async {
    if (_formKey.currentState!.validate()) {
      final laborCost = double.tryParse(_laborCostController.text) ?? 0.0;
      final partsCost = double.tryParse(_partsCostController.text) ?? 0.0;

      // A 'maintenance' tábla a 'serviceType' mezőt várja a 'description' helyett.
      // És a költségeket is a 'cost' mezőben tároljuk.
      // A Karbantartas modellnek megfelelően kell átadnunk az adatokat.
      final maintenanceData = {
        // 'id' -t az adatbázis generálja
        'vehicleId': widget.vehicleId,
        'serviceType': _descriptionController.text,
        // A leírás lesz a szerviz típusa
        'date': _selectedDate.toIso8601String(),
        'mileage': int.parse(_mileageController.text),
        'notes': _notesController.text,
        'cost': laborCost + partsCost,
        // A teljes költség a 'cost' mezőbe kerül
        // A régi, nem használt mezőket eltávolítottuk
      };

      // JAVÍTVA: A createMaintenance helyett az egységes insert metódust hívjuk.
      await AdatbazisKezelo.instance.insert('maintenance', maintenanceData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentOrange = Color.fromARGB(255, 255, 164, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Új karbantartás rögzítése')),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextFormField(
                  controller: _descriptionController,
                  labelText: 'Szerviz típusa (pl. Olajcsere)'),
              // Átnevezve a label
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _mileageController,
                  labelText: 'Kilométeróra állás',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Karbantartás dátuma: ${DateFormat('yyyy. MM. dd.').format(
                      _selectedDate)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: const Icon(
                    Icons.calendar_today, color: Colors.orange),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // A szerviz helye és a külön költségek már nem részei a modellnek
              // _buildTextFormField(
              //     controller: _servicePlaceController,
              //     labelText: 'Szerviz helye'),
              // const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _laborCostController,
                  labelText: 'Munkadíj (Ft)',
                  keyboardType: TextInputType.number,
                  required: false),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _partsCostController,
                  labelText: 'Alkatrészek ára (Ft)',
                  keyboardType: TextInputType.number,
                  required: false),
              const SizedBox(height: 16),
              _buildTextFormField(
                  controller: _notesController,
                  labelText: 'Megjegyzések',
                  maxLines: 3,
                  required: false),
              // A megjegyzés nem kötelező
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveMaintenance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Mentés'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
    bool required = true, // Hozzáadva, hogy a validáció rugalmas legyen
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.orange),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.orange)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Kérjük, töltse ki ezt a mezőt!';
        }
        if (keyboardType == TextInputType.number &&
            value!.isNotEmpty &&
            double.tryParse(value) == null) {
          return 'Kérjük, érvényes számot adjon meg!';
        }
        return null;
      },
    );
  }
}