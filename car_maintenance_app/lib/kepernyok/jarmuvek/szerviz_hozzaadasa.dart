// lib/kepernyok/jarmuvek/szerviz_hozzaadasa.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/karbantartas.dart';

class SzervizHozzaadasa extends StatefulWidget {
  final int vehicleId;
  final Karbantartas? serviceToEdit;

  const SzervizHozzaadasa({
    super.key,
    required this.vehicleId,
    this.serviceToEdit,
  });

  @override
  State<SzervizHozzaadasa> createState() => _SzervizHozzaadasaState();
}

class _SzervizHozzaadasaState extends State<SzervizHozzaadasa> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serviceTypeController;
  late TextEditingController _dateController;
  late TextEditingController _mileageController;

  // JAVÍTVA: Felesleges controllerek törölve
  // late TextEditingController _notesController;
  // late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    final service = widget.serviceToEdit;
    _serviceTypeController = TextEditingController(text: service?.serviceType);
    _dateController = TextEditingController(
        text: service != null
            ? service.date.substring(0, 10)
            : DateTime.now().toIso8601String().substring(0, 10));
    _mileageController =
        TextEditingController(text: service?.mileage.toString());
    // JAVÍTVA: Felesleges controllerek inicializálása törölve
    // _notesController = TextEditingController(text: service?.notes);
    // _costController = TextEditingController(text: service?.cost?.toString());
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _dateController.dispose();
    _mileageController.dispose();
    // JAVÍTVA: Felesleges controllerek dispose-olása törölve
    // _notesController.dispose();
    // _costController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  void _saveService() async {
    if (_formKey.currentState!.validate()) {
      // JAVÍTVA: A Karbantartas objektum a helyes, egyszerűsített formában jön létre
      final maintenanceData = Karbantartas(
        id: widget.serviceToEdit?.id,
        vehicleId: widget.vehicleId,
        serviceType: _serviceTypeController.text,
        date: _dateController.text,
        mileage: int.parse(_mileageController.text),
      );

      if (widget.serviceToEdit != null) {
        await AdatbazisKezelo.instance.update(
            'maintenance', maintenanceData.toMap());
      } else {
        await AdatbazisKezelo.instance.insert(
            'maintenance', maintenanceData.toMap());
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.serviceToEdit == null
            ? 'Új Szerviz'
            : 'Szerviz Szerkesztése'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveService,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_serviceTypeController, 'Szerviz típusa'),
            _buildTextField(
              _dateController,
              'Dátum',
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
            _buildTextField(_mileageController, 'Kilométeróra állás',
                keyboardType: TextInputType.number),
            // JAVÍTVA: Felesleges TextField-ek törölve
            // _buildTextField(
            //     _costController, 'Költség (opcionális)', required: false,
            //     keyboardType: TextInputType.number),
            // _buildTextField(
            //     _notesController, 'Megjegyzések (opcionális)', required: false,
            //     maxLines: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller,
      String label, {
        bool required = true,
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        bool readOnly = false,
        VoidCallback? onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.orange),
          ),
        ),
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Ez a mező kötelező';
          }
          return null;
        },
      ),
    );
  }
}