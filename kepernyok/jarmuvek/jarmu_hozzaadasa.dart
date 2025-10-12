import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import 'package:car_maintenance_app/modellek/karbantartas.dart';

class JarmuHozzaadasa extends StatefulWidget {
  final Jarmu? vehicleToEdit;

  const JarmuHozzaadasa({super.key, this.vehicleToEdit});

  @override
  State<JarmuHozzaadasa> createState() => _JarmuHozzaadasaState();
}

class _JarmuHozzaadasaState extends State<JarmuHozzaadasa> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;

  String _selectedVezerlesTipus = 'Szíj';
  final List<String> _vezerlesOptions = ['Szíj', 'Lánc'];
  bool _remindersEnabled = false;

  final Map<String, TextEditingController> _kmBasedServiceControllers = {};
  final Map<String, DateTime?> _dateBasedServiceDates = {};
  final Map<String, bool> _serviceEnabledStates = {};
  final Map<String, String?> _serviceErrors = {};

  final List<String> _dateBasedServiceTypes = [
    'Műszaki vizsga',
    'Akkumulátor csere'
  ];
  final List<String> _kmBasedServiceTypes = [
    'Olajcsere',
    'Levegőszűrő csere',
    'Pollenszűrő csere',
    'Üzemanyagszűrő csere',
    'Vezérműszíj/lánc csere',
    'Fékbetét csere (első)',
    'Fékbetét csere (hátsó)',
    'Fékfolyadék csere',
    'Hűtőfolyadék csere',
  ];
  late List<String> _allServiceTypes;

  final Map<String, Color> _iconColors = {
    'Márka': Colors.cyan,
    'Modell': Colors.lightBlue,
    'Évjárat': Colors.teal,
    'Vezérlés': Colors.purple,
    'Kilométeróra': Colors.amber,
    'Rendszám': Colors.green,
    'Alvázszám': Colors.blueGrey,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicleToEdit?.make);
    _modelController = TextEditingController(text: widget.vehicleToEdit?.model);
    _yearController =
        TextEditingController(text: widget.vehicleToEdit?.year?.toString());
    _licensePlateController =
        TextEditingController(text: widget.vehicleToEdit?.licensePlate);
    _vinController = TextEditingController(text: widget.vehicleToEdit?.vin);
    _mileageController = TextEditingController(
        text: widget.vehicleToEdit?.mileage?.toString());
    _selectedVezerlesTipus = widget.vehicleToEdit?.vezerlesTipusa ?? 'Szíj';

    _mileageController.addListener(() {
      if (_remindersEnabled) {
        setState(() => _validateAllServices());
      }
    });

    _allServiceTypes = [..._dateBasedServiceTypes, ..._kmBasedServiceTypes];
    _initializeServiceControllers();

    if (widget.vehicleToEdit != null) {
      // JAVÍTVA: Szerkesztéskor azonnal kinyitjuk a karbantartási listát
      _remindersEnabled = true;
      _loadMaintenanceData(widget.vehicleToEdit!);
    } else {
      _isLoading = false;
    }
  }

  void _initializeServiceControllers() {
    for (var type in _allServiceTypes) {
      if (_kmBasedServiceTypes.contains(type)) {
        _kmBasedServiceControllers[type] = TextEditingController();
      } else {
        _dateBasedServiceDates[type] = null;
      }
      _serviceEnabledStates[type] = false;
      _serviceErrors[type] = null;
    }
  }

  Future<void> _loadMaintenanceData(Jarmu vehicle) async {
    final records =
    await AdatbazisKezelo.instance.getMaintenanceForVehicle(vehicle.id!);
    for (var recordMap in records) {
      final record = Karbantartas.fromMap(recordMap);
      final serviceType = record.serviceType;
      if (_serviceEnabledStates.containsKey(serviceType)) {
        _serviceEnabledStates[serviceType] = true;
        if (_dateBasedServiceTypes.contains(serviceType)) {
          _dateBasedServiceDates[serviceType] = DateTime.tryParse(record.date);
        } else if (_kmBasedServiceControllers.containsKey(serviceType)) {
          _kmBasedServiceControllers[serviceType]!.text =
              record.mileage.toString();
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Betöltés után azonnal validálunk, hogy az esetleges hibák eltűnjenek
        _validateAllServices();
      });
    }
  }

  // JAVÍTVA: A validáció mostantól automatikusan kitölti az üres mezőket
  void _validateService(String serviceType, String? value) {
    if (!(_serviceEnabledStates[serviceType] ?? false)) {
      _serviceErrors[serviceType] = null;
      return;
    }

    final currentMileage = int.tryParse(_mileageController.text);
    if (currentMileage == null || currentMileage == 0) {
      _serviceErrors[serviceType] = 'Fő km állás hiányzik!';
      return;
    }

    // Ha üres a mező, de be van pipálva, automatikusan kitöltjük az aktuális km-rel
    if (value == null || value.isEmpty) {
      // A setState a builden kívül itt nem biztonságos, de a controller értékét beállíthatjuk.
      // A következő build ciklus már a helyes értékkel fogja felépíteni.
      _kmBasedServiceControllers[serviceType]?.text = currentMileage.toString();
      _serviceErrors[serviceType] = null; // Töröljük a hibát
      // Hívunk egy setState-et, hogy a UI frissüljön az új értékkel
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    final serviceMileage = int.tryParse(value);
    if (serviceMileage == null) {
      _serviceErrors[serviceType] = 'Hibás szám!';
      return;
    }

    if (serviceMileage > currentMileage) {
      _serviceErrors[serviceType] = 'Több, mint a fő km!';
      return;
    }

    _serviceErrors[serviceType] = null;
  }

  void _validateAllServices() {
    for (var type in _kmBasedServiceTypes) {
      if (_kmBasedServiceControllers.containsKey(type)) {
        _validateService(type, _kmBasedServiceControllers[type]!.text);
      }
    }
  }

  Future<void> _saveOrUpdateVehicle() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kérlek, töltsd ki a kötelező alap adatokat!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Mentés előtt még egyszer validálunk mindent
    if (_remindersEnabled) {
      _validateAllServices();
      // Rövid késleltetés, hogy a validáció által beállított controller értékek biztosan "átmenjenek"
      await Future.delayed(const Duration(milliseconds: 50));
      if (_serviceErrors.values.any((e) => e != null)) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Javítsd a hibás emlékeztető adatokat!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final vehicle = Jarmu(
      id: widget.vehicleToEdit?.id,
      make: _makeController.text,
      model: _modelController.text,
      year: int.parse(_yearController.text),
      licensePlate: _licensePlateController.text.toUpperCase(),
      vin: _vinController.text.isNotEmpty ? _vinController.text : null,
      vezerlesTipusa: _selectedVezerlesTipus,
      mileage: int.tryParse(_mileageController.text) ?? 0,
    );

    try {
      final db = AdatbazisKezelo.instance;
      int vehicleId;

      if (widget.vehicleToEdit == null) {
        vehicleId = await db.insert('vehicles', vehicle.toMap());
      } else {
        vehicleId = vehicle.id!;
        await db.update('vehicles', vehicle.toMap());
        await db.deleteMaintenanceForVehicle(vehicleId);
      }

      if (_remindersEnabled) {
        for (var type in _allServiceTypes) {
          if (_serviceEnabledStates[type] == true) {
            if (_dateBasedServiceTypes.contains(type) &&
                _dateBasedServiceDates[type] != null) {
              await db.insert('maintenance', Karbantartas(
                vehicleId: vehicleId,
                serviceType: type,
                date: _dateBasedServiceDates[type]!.toIso8601String(),
                mileage: 0,
              ).toMap());
            } else if (_kmBasedServiceTypes.contains(type)) {
              final controller = _kmBasedServiceControllers[type];
              // Ha a controller üres, a jármű aktuális km-ét mentjük
              final mileageToSave = int.tryParse(controller?.text ?? '') ??
                  vehicle.mileage;
              await db.insert('maintenance', Karbantartas(
                vehicleId: vehicleId,
                serviceType: type,
                mileage: mileageToSave,
                date: DateTime.now().toIso8601String(),
              ).toMap());
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jármű sikeresen mentve!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.isUniqueConstraintError()
                ? 'Hiba: Ez a rendszám már foglalt!'
                : 'Adatbázis hiba!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ismeretlen hiba történt: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _kmBasedServiceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  // --- Az UI Építő Widgetek Innentől Változatlanok ---
  // A bemásolt kódodban ez a rész már helyes volt, így nem módosítom.
  // A teljesség kedvéért itt van az egész.

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: Text(
              widget.vehicleToEdit == null ? 'Új Jármű' : 'Jármű Szerkesztése',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                            title: 'Alapinformációk',
                            children: [
                              Row(children: [
                                Expanded(
                                    child: _buildTextField(_makeController,
                                        'Márka',
                                        icon: Icons.directions_car)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _buildTextField(
                                        _modelController, 'Modell',
                                        icon: Icons.star_outline)),
                              ]),
                              const SizedBox(height: 16),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: _buildTextField(
                                            _yearController, 'Évjárat',
                                            icon: Icons.calendar_today,
                                            keyboardType: TextInputType.number,
                                            maxLength: 4)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child: _buildDropdown(
                                            label: 'Vezérlés',
                                            icon: Icons.settings)),
                                  ]),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _mileageController, 'Kilométeróra',
                                  icon: Icons.speed,
                                  keyboardType: TextInputType.number),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _licensePlateController, 'Rendszám',
                                  icon: Icons.pin),
                              const SizedBox(height: 16),
                              _buildTextField(_vinController, 'Alvázszám',
                                  optional: true, icon: Icons.qr_code),
                            ]),
                        const SizedBox(height: 24),
                        _buildSectionCard(title: 'Karbantartás', children: [
                          _buildReminderToggle(),
                          AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _remindersEnabled
                                  ? _buildReminderContent()
                                  : const SizedBox.shrink()),
                        ]),
                        const SizedBox(height: 120),
                      ])),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _saveOrUpdateVehicle,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.save, color: Colors.black),
            label: const Text('Mentés',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _showAddCustomServiceDialog() {
    final TextEditingController customServiceController =
    TextEditingController();
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF2a2a2a),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            title: const Text('Egyedi szerviz hozzáadása',
                style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: customServiceController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Szerviz neve (pl. DPF tisztítás)',
                labelStyle: const TextStyle(color: Colors.white70),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange)),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Mégse',
                    style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (customServiceController.text.isNotEmpty) {
                    setState(() {
                      final newService = customServiceController.text;
                      if (!_allServiceTypes.contains(newService)) {
                        _allServiceTypes.add(newService);
                        _kmBasedServiceTypes.add(newService);
                        _kmBasedServiceControllers[newService] =
                            TextEditingController();
                        _serviceEnabledStates[newService] = true;
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Hozzáadás',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
    );
  }

  Widget _buildReminderToggle() {
    return GestureDetector(
      onTap: () =>
          setState(() {
            _remindersEnabled = !_remindersEnabled;
            if (_remindersEnabled) {
              _validateAllServices();
            }
          }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12)),
        child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Flexible(
              child: Text("Karbantartási emlékeztetők",
                  style: TextStyle(color: Colors.white, fontSize: 16))),
          Switch(
              value: _remindersEnabled,
              onChanged: (bool value) =>
                  setState(() {
                    _remindersEnabled = value;
                    if (_remindersEnabled) {
                      _validateAllServices();
                    }
                  }),
              activeColor: Colors.orange,
              activeTrackColor: Colors.orange.withOpacity(0.5),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.4))
        ]),
      ),
    );
  }

  Widget _buildReminderContent() {
    return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(children: [
          ..._dateBasedServiceTypes.map((type) => _buildDatePickerRow(type)),
          ..._kmBasedServiceTypes.map((type) =>
              _buildMileageInputRow(
                type,
                key: ValueKey('mileage_input_$type'),
              )),
          const SizedBox(height: 16),
          TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
              label: const Text('Egyedi szerviz hozzáadása',
                  style: TextStyle(color: Colors.orange)),
              onPressed: _showAddCustomServiceDialog,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))))
        ]));
  }

  Widget _buildDatePickerRow(String serviceType) {
    final hint = serviceType == 'Akkumulátor csere'
        ? 'Utolsó csere dátuma'
        : 'Lejárati dátum';
    bool isEnabled = _serviceEnabledStates[serviceType] ?? false;
    String dateText = _dateBasedServiceDates[serviceType] != null
        ? DateFormat('yyyy. MM. dd.')
        .format(_dateBasedServiceDates[serviceType]!)
        : hint;
    return _buildServiceTile(
        key: ValueKey('date_picker_$serviceType'),
        title: serviceType,
        isEnabled: isEnabled,
        onToggle: (value) =>
            setState(() {
              _serviceEnabledStates[serviceType] = value;
              if (!value) _dateBasedServiceDates[serviceType] = null;
            }),
        child: GestureDetector(
            onTap: !isEnabled
                ? null
                : () async {
              final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate:
                  _dateBasedServiceDates[serviceType] ?? DateTime.now(),
                  firstDate: DateTime(DateTime
                      .now()
                      .year - 10),
                  lastDate:
                  DateTime.now().add(const Duration(days: 365 * 5)));
              if (picked != null &&
                  picked != _dateBasedServiceDates[serviceType]) {
                setState(
                        () => _dateBasedServiceDates[serviceType] = picked);
              }
            },
            child: Text(dateText,
                style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey[600],
                    fontSize: 16))));
  }

  Widget _buildMileageInputRow(String serviceType, {Key? key}) {
    if (!_kmBasedServiceControllers.containsKey(serviceType)) {
      return const SizedBox.shrink();
    }
    bool isEnabled = _serviceEnabledStates[serviceType] ?? false;
    return _buildServiceTile(
      key: key,
      title: serviceType,
      isEnabled: isEnabled,
      errorText: _serviceErrors[serviceType],
      onToggle: (value) {
        setState(() {
          _serviceEnabledStates[serviceType] = value;
          // Most már a checkbox bekapcsolásakor is validálunk/kitöltünk
          _validateService(
              serviceType, _kmBasedServiceControllers[serviceType]?.text);
          if (!value) _kmBasedServiceControllers[serviceType]?.clear();
        });
      },
      child: SizedBox(
        width: 120,
        child: TextFormField(
          controller: _kmBasedServiceControllers[serviceType],
          enabled: isEnabled,
          textAlign: TextAlign.right,
          style: TextStyle(color: isEnabled ? Colors.white : Colors.grey[600]),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            // Gépelés közben is validálunk
            _validateService(serviceType, value);
            // setState itt nem kell, mert a _validateService már gondoskodik róla ha kell
          },
          decoration: InputDecoration(
            hintText: 'km',
            hintStyle: TextStyle(color: Colors.grey[700]),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...children
        ]));
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = true,
        bool optional = false,
        TextInputType keyboardType = TextInputType.text,
        int? maxLength,
        IconData? icon}) {
    Color color =
        _iconColors[label.replaceAll(' (opcionális)', '')] ?? Colors.grey;
    return TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: InputDecoration(
            labelText: optional ? '$label (opcionális)' : label,
            prefixIcon: icon != null ? _buildGradientIcon(icon, color) : null,
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Colors.redAccent, width: 1)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: Colors.redAccent, width: 2)),
            counterText: ''),
        validator: (value) {
          if (!optional && required && (value == null || value.isEmpty)) {
            return 'Kötelező mező';
          }
          if (label == 'Évjárat' &&
              value != null &&
              value.isNotEmpty &&
              value.length != 4) return '4 számjegy';
          return null;
        });
  }

  Widget _buildDropdown({required String label, IconData? icon}) {
    Color color = _iconColors[label] ?? Colors.grey;
    return Container(
        padding: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          if (icon != null) _buildGradientIcon(icon, color, isDropdown: true),
          Expanded(
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                      value: _selectedVezerlesTipus,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2a2a2a),
                      style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.orange),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedVezerlesTipus = newValue);
                        }
                      },
                      items: _vezerlesOptions.map<DropdownMenuItem<String>>(
                              (String value) =>
                              DropdownMenuItem<String>(
                                  value: value, child: Text(value))).toList())))
        ]));
  }

  Widget _buildGradientIcon(IconData icon, Color color,
      {bool isDropdown = false}) {
    return Container(
        margin: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withOpacity(0.6), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1)
            ]),
        child: Icon(icon, color: Colors.white, size: 24));
  }

  Widget _buildServiceTile({required String title,
    required Widget child,
    required bool isEnabled,
    String? errorText,
    required Function(bool) onToggle,
    Key? key}) {
    final bool hasError = errorText != null;
    return Material(
        key: key,
        color: isEnabled
            ? (hasError
            ? Colors.red.withOpacity(0.25)
            : Colors.black.withOpacity(0.3))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: () => onToggle(!isEnabled),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                child: Column(children: [
                  Row(children: [
                    Checkbox(
                        value: isEnabled,
                        onChanged: (v) => onToggle(v ?? false),
                        activeColor: Colors.orange,
                        checkColor: Colors.black,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: Colors.white70, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    Expanded(
                        child: Text(title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16))),
                    child
                  ]),
                  if (hasError && isEnabled)
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 48.0, bottom: 8.0, right: 16.0),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                errorText == 'Kötelező kitölteni!'
                                    ? 'Az emlékeztetőhöz ezt kötelező kitölteni!'
                                    : errorText == 'Több, mint a fő km!'
                                    ? 'Ez több, mint a jármű aktuális KM-e!'
                                    : errorText == 'Fő km állás hiányzik!'
                                    ? 'Előbb add meg a fő kilométeróra állást!'
                                    : errorText,
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12))))
                ]))));
  }
}