import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart';

class JarmuHozzaadasa extends StatefulWidget {
  final Jarmu? vehicleToEdit;

  const JarmuHozzaadasa({super.key, this.vehicleToEdit});

  @override
  State<JarmuHozzaadasa> createState() => _JarmuHozzaadasaState();
}

class _JarmuHozzaadasaState extends State<JarmuHozzaadasa> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMake;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;
  String _selectedVezerlesTipus = 'Szíj';
  bool _remindersEnabled = false;
  final Map<String, TextEditingController> _kmBasedServiceControllers = {};
  final Map<String, DateTime?> _dateBasedServiceDates = {};
  final Map<String, bool> _serviceEnabledStates = {};
  final Map<String, String?> _serviceErrors = {};
  bool _isLoading = true;

  // === MÓDOSÍTVA: Szerviztípusok és intervallumok a kéréseid alapján ===
  final List<String> _dateBasedServiceTypes = ['Műszaki vizsga'];
  final List<String> _kmBasedServiceTypes = [
    'Olajcsere',
    'Légszűrő',
    'Pollenszűrő',
    'Gyújtógyertya', // HOZZÁADVA
    'Üzemanyagszűrő',
    'Vezérlés (Szíj)', // PONTOSÍTVA
    'Fékbetét (első)',
    'Fékbetét (hátsó)',
    'Fékfolyadék',
    'Hűtőfolyadék',
    'Kuplung', // HOZZÁADVA (Aksi helyett)
  ];
  late List<String> _allServiceTypes;

  final Map<String, Color> _iconColors = {
    'Márka': Colors.cyan,
    'Modell': Colors.lightBlue,
    'Évjárat': Colors.teal,
    'Vezérlés': Colors.purple,
    'Kilométeróra': Colors.amber,
    'Rendszám': Colors.green,
    'Alvázszám': Colors.blueGrey
  };
  final List<String> _supportedCarMakes = [
    'Abarth',
    'Alfa Romeo',
    'Aston Martin',
    'Audi',
    'Bentley',
    'BMW',
    'Bugatti',
    'Cadillac',
    'Chevrolet',
    'Chrysler',
    'Citroën',
    'Dacia',
    'Daewoo',
    'Daihatsu',
    'Dodge',
    'Donkervoort',
    'DS',
    'Ferrari',
    'Fiat',
    'Fisker',
    'Ford',
    'Honda',
    'Hummer',
    'Hyundai',
    'Infiniti',
    'Iveco',
    'Jaguar',
    'Jeep',
    'Kia',
    'KTM',
    'Lada',
    'Lamborghini',
    'Lancia',
    'Land Rover',
    'Lexus',
    'Lotus',
    'Maserati',
    'Maybach',
    'Mazda',
    'McLaren',
    'Mercedes-Benz',
    'MG',
    'Mini',
    'Mitsubishi',
    'Morgan',
    'Nissan',
    'Opel',
    'Peugeot',
    'Porsche',
    'Renault',
    'Rolls-Royce',
    'Rover',
    'Saab',
    'Seat',
    'Skoda',
    'Smart',
    'SsangYong',
    'Subaru',
    'Suzuki',
    'Tesla',
    'Toyota',
    'Volkswagen',
    'Volvo'
  ];
  final List<String> _vezerlesOptions = ['Szíj', 'Lánc', 'Nincs'];

  @override
  void initState() {
    super.initState();
    _selectedMake = widget.vehicleToEdit?.make;
    _modelController = TextEditingController(text: widget.vehicleToEdit?.model);
    _yearController =
        TextEditingController(text: widget.vehicleToEdit?.year?.toString());
    _licensePlateController =
        TextEditingController(text: widget.vehicleToEdit?.licensePlate);
    _vinController = TextEditingController(text: widget.vehicleToEdit?.vin);
    _mileageController =
        TextEditingController(text: widget.vehicleToEdit?.mileage?.toString());
    _selectedVezerlesTipus = widget.vehicleToEdit?.vezerlesTipusa ?? 'Szíj';

    if (_selectedMake != null && !_supportedCarMakes.contains(_selectedMake)) {
      if (_selectedMake!.isNotEmpty) _supportedCarMakes.insert(
          0, _selectedMake!);
    }

    _mileageController.addListener(() {
      if (_remindersEnabled) setState(() => _validateAllServices());
    });

    _allServiceTypes = [..._dateBasedServiceTypes, ..._kmBasedServiceTypes];
    for (var type in _allServiceTypes) {
      _serviceEnabledStates[type] = false;
      _serviceErrors[type] = null;
      if (_kmBasedServiceTypes.contains(type)) {
        _kmBasedServiceControllers[type] = TextEditingController();
      } else {
        _dateBasedServiceDates[type] = null;
      }
    }

    if (widget.vehicleToEdit != null) {
      _remindersEnabled = true;
      _loadMaintenanceData(widget.vehicleToEdit!);
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadMaintenanceData(Jarmu vehicle) async {
    final records = await AdatbazisKezelo.instance.getServicesForVehicle(
        vehicle.id!);
    for (var recordMap in records) {
      final record = Szerviz.fromMap(recordMap);
      for (var type in _allServiceTypes) {
        if (record.description.toLowerCase().contains(
            type.toLowerCase().replaceAll(" (szíj)", ""))) {
          _serviceEnabledStates[type] = true;
          if (_dateBasedServiceTypes.contains(type)) {
            _dateBasedServiceDates[type] = record.date;
          } else if (_kmBasedServiceControllers.containsKey(type)) {
            _kmBasedServiceControllers[type]!.text = record.mileage.toString();
          }
          break;
        }
      }
    }
    if (mounted) {
      _validateAllServices();
      setState(() => _isLoading = false);
    }
  }

  void _validateService(String serviceType, String? value,
      {bool isFromToggle = false}) {
    if (!(_serviceEnabledStates[serviceType] ?? false)) {
      _serviceErrors[serviceType] = null;
      return;
    }

    final currentMileage = int.tryParse(_mileageController.text);
    if (currentMileage == null || currentMileage == 0) {
      _serviceErrors[serviceType] = 'Add meg a jármű fő km-óra állását!';
      return;
    }

    if (isFromToggle && (value == null || value.isEmpty)) {
      _kmBasedServiceControllers[serviceType]?.text = currentMileage.toString();
      _serviceErrors[serviceType] = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
      return;
    }

    if (value == null || value.isEmpty) {
      _serviceErrors[serviceType] = 'Kötelező megadni a km-t!';
      return;
    }

    final serviceMileage = int.tryParse(value);
    if (serviceMileage == null) {
      _serviceErrors[serviceType] = 'Hibás számformátum!';
      return;
    }

    if (serviceMileage > currentMileage) {
      _serviceErrors[serviceType] = 'Nem lehet több, mint a fő km!';
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

  @override
  void dispose() {
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _kmBasedServiceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveOrUpdateVehicle() async {
    if (_selectedMake == null || _selectedMake!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Válassz márkát!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kérlek, töltsd ki a kötelező alap adatokat!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating));
      return;
    }

    if (_remindersEnabled) {
      _validateAllServices();
      await Future.delayed(const Duration(milliseconds: 50));
      if (_serviceErrors.values.any((e) => e != null)) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Javítsd a hibás emlékeztető adatokat!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating));
        return;
      }
    }

    final vehicle = Jarmu(
      id: widget.vehicleToEdit?.id,
      make: _selectedMake!,
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
      }

      await db.deleteServicesForVehicle(vehicleId);

      if (_remindersEnabled) {
        for (var type in _allServiceTypes) {
          // Speciális eset: A 'Vezérlés (Szíj)' emlékeztetőt csak akkor mentsük, ha a jármű szíjas
          if (type == 'Vezérlés (Szíj)' && _selectedVezerlesTipus != 'Szíj') {
            continue; // Kihagyjuk ezt a ciklust, ha nem szíjas az autó
          }

          if (_serviceEnabledStates[type] == true) {
            String description = '$type (automatikus bejegyzés)';
            int cost = 0;

            if (_dateBasedServiceTypes.contains(type) &&
                _dateBasedServiceDates[type] != null) {
              final serviceRecord = Szerviz(vehicleId: vehicleId,
                  description: description,
                  date: _dateBasedServiceDates[type]!,
                  cost: cost,
                  mileage: vehicle.mileage);
              await db.insert('services', serviceRecord.toMap());
            } else if (_kmBasedServiceTypes.contains(type)) {
              final controller = _kmBasedServiceControllers[type];
              final mileageToSave = int.tryParse(controller?.text ?? '');
              if (mileageToSave != null) {
                final serviceRecord = Szerviz(vehicleId: vehicleId,
                    description: description,
                    date: DateTime.now(),
                    cost: cost,
                    mileage: mileageToSave);
                await db.insert('services', serviceRecord.toMap());
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Jármű sikeresen mentve!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            e.isUniqueConstraintError()
                ? 'Hiba: Ez a rendszám már foglalt!'
                : 'Adatbázis hiba!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF121212),
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: Text(
              widget.vehicleToEdit == null ? 'Új Jármű' : 'Jármű Szerkesztése'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Alapinformációk',
                children: [
                  _buildMakeDropdown(),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _buildTextField(
                        controller: _modelController,
                        label: 'Modell',
                        icon: Icons.star_outline)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(controller: _yearController,
                        label: 'Évjárat',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        maxLength: 4)),
                  ]),
                  const SizedBox(height: 16),
                  _buildDropdown(label: 'Vezérlés', icon: Icons.settings),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _mileageController,
                      label: 'Kilométeróra',
                      icon: Icons.speed,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _licensePlateController,
                      label: 'Rendszám',
                      icon: Icons.pin),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _vinController,
                      label: 'Alvázszám',
                      optional: true,
                      icon: Icons.qr_code),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionCard(
                title: 'Karbantartás',
                children: [
                  _buildReminderToggle(),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _remindersEnabled
                        ? _buildReminderContent()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
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
            label: const Text('Mentés', style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderToggle() {
    return GestureDetector(
        onTap: () {
          setState(() => _remindersEnabled = !_remindersEnabled);
          if (_remindersEnabled) _validateAllServices();
        },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: Text("Karbantartási emlékeztetők",
                      style: TextStyle(color: Colors.white, fontSize: 16))),
                  Switch(
                      value: _remindersEnabled,
                      onChanged: (bool value) {
                        setState(() => _remindersEnabled = value);
                        if (value) _validateAllServices();
                      },
                      activeColor: Colors.orange)
                ])));
  }

  Widget _buildReminderContent() {
    return Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(children: [
          ..._dateBasedServiceTypes.map((type) => _buildDatePickerRow(type)),
          ..._kmBasedServiceTypes.map((type) {
            // A vezérlés (szíj) sort csak akkor jelenítjük meg, ha a jármű szíjas
            if (type == 'Vezérlés (Szíj)' && _selectedVezerlesTipus != 'Szíj') {
              return const SizedBox.shrink(); // Üres widget, ha nem szíjas
            }
            return _buildMileageInputRow(
                type, key: ValueKey('mileage_input_$type'));
          }),
        ]));
  }

  Widget _buildDatePickerRow(String serviceType) {
    final hint = 'Lejárati dátum';
    bool isEnabled = _serviceEnabledStates[serviceType] ?? false;
    String dateText = _dateBasedServiceDates[serviceType] != null
        ? DateFormat('yyyy. MM. dd.').format(
        _dateBasedServiceDates[serviceType]!) : hint;

    Future<void> pickDate() async {
      final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _dateBasedServiceDates[serviceType] ?? DateTime.now(),
          firstDate: DateTime(DateTime
              .now()
              .year - 15),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
      if (picked != null && picked != _dateBasedServiceDates[serviceType]) {
        setState(() => _dateBasedServiceDates[serviceType] = picked);
      }
    }

    return _buildServiceTile(
        title: serviceType,
        isEnabled: isEnabled,
        onToggle: (value) =>
            setState(() => _serviceEnabledStates[serviceType] = value),
        child: GestureDetector(
          onTap: !isEnabled ? null : pickDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dateText, style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey[600],
                  fontSize: 16)),
              const SizedBox(width: 8),
              Icon(Icons.edit_calendar,
                  color: isEnabled ? Colors.white70 : Colors.transparent,
                  size: 20),
            ],
          ),
        )
    );
  }

  Widget _buildMileageInputRow(String serviceType, {Key? key}) {
    if (!_kmBasedServiceControllers.containsKey(serviceType))
      return const SizedBox.shrink();

    bool isEnabled = _serviceEnabledStates[serviceType] ?? false;
    return _buildServiceTile(
        key: key,
        title: serviceType,
        isEnabled: isEnabled,
        errorText: _serviceErrors[serviceType],
        onToggle: (value) {
          setState(() {
            _serviceEnabledStates[serviceType] = value;
            _validateService(
                serviceType, _kmBasedServiceControllers[serviceType]!.text,
                isFromToggle: true);
            if (!value) {
              _kmBasedServiceControllers[serviceType]?.clear();
              _serviceErrors[serviceType] = null;
            }
          });
        },
        child: SizedBox(
            width: 130,
            child: TextFormField(
                controller: _kmBasedServiceControllers[serviceType],
                enabled: isEnabled,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() => _validateService(serviceType, value));
                },
                decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: const Text(
                          'km', style: TextStyle(color: Colors.black)),
                      backgroundColor: isEnabled ? Colors.white70 : Colors
                          .transparent,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                )
            )
        )
    );
  }

  Widget _buildServiceTile(
      {required String title, required Widget child, required bool isEnabled, String? errorText, required Function(bool) onToggle, Key? key}) {
    final bool hasError = errorText != null;
    return Material(
        key: key,
        color: isEnabled ? (hasError ? Colors.red.withOpacity(0.25) : Colors
            .black.withOpacity(0.3)) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
            onTap: () => onToggle(!isEnabled),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Checkbox(
                          value: isEnabled,
                          onChanged: (v) => onToggle(v ?? false),
                          activeColor: Colors.orange,
                          checkColor: Colors.black,
                          side: BorderSide(color: Colors.white70, width: 1.5)),
                      Expanded(child: Text(title, style: const TextStyle(
                          color: Colors.white, fontSize: 16))),
                      child
                    ]),
                    if (hasError && isEnabled)
                      Padding(
                          padding: const EdgeInsets.only(
                              left: 48.0, bottom: 8.0, right: 16.0),
                          child: Text(errorText!, style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600))
                      )
                  ],
                )
            )
        )
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.orange,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...children
            ]));
  }

  Widget _buildTextField(
      {TextEditingController? controller, String? label, bool optional = false, TextInputType keyboardType = TextInputType
          .text, int? maxLength, IconData? icon, Widget? child}) {
    Color color = _iconColors[label?.replaceAll(' (opcionális)', '')] ??
        Colors.grey;
    Widget content = child ?? TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number ? [
          FilteringTextInputFormatter.digitsOnly
        ] : [],
        decoration: InputDecoration(
            labelText: optional ? '$label (opcionális)' : label,
            labelStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty))
            return 'Kötelező mező';
          if (label == 'Évjárat' && value != null && value.isNotEmpty &&
              value.length != 4) return '4 számjegy';
          return null;
        });
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          if (icon != null) _buildGradientIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],));
  }

  Widget _buildMakeDropdown() {
    return _buildTextField(
      label: 'Márka', icon: Icons.directions_car, child: DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(hintText: "Keresés...",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange)),),),
        menuProps: MenuProps(backgroundColor: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context, item, isSelected) =>
            Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(item, style: TextStyle(
              color: isSelected ? Colors.orange : Colors.white,
              fontSize: 16)),),
      ),
      dropdownDecoratorProps: const DropDownDecoratorProps(
        baseStyle: TextStyle(color: Colors.white, fontSize: 16),
        dropdownSearchDecoration: InputDecoration(
            border: InputBorder.none, contentPadding: EdgeInsets.all(0)),),
      items: _supportedCarMakes,
      selectedItem: _selectedMake,
      onChanged: (String? newValue) => setState(() => _selectedMake = newValue),
      validator: (value) =>
      (value == null || value.isEmpty)
          ? 'Kötelező mező'
          : null,
    ),
    );
  }

  Widget _buildDropdown({required String label, IconData? icon}) {
    Color color = _iconColors[label] ?? Colors.grey;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          if (icon != null) _buildGradientIcon(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: _selectedVezerlesTipus,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2a2a2a),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() {
                      _selectedVezerlesTipus = newValue;
                      // Ha láncosra vált, töröljük a szíj-emlékeztető állapotát
                      if (newValue == 'Lánc') {
                        _serviceEnabledStates['Vezérlés (Szíj)'] = false;
                        _kmBasedServiceControllers['Vezérlés (Szíj)']?.clear();
                        _serviceErrors['Vezérlés (Szíj)'] = null;
                      }
                    });
                  },
                  items: _vezerlesOptions.map<DropdownMenuItem<String>>((
                      String value) =>
                      DropdownMenuItem<String>(
                      value: value, child: Text(value))).toList())))
        ]));
  }

  Widget _buildGradientIcon({required IconData icon, required Color color}) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.6), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)
            ]),
        child: Icon(icon, color: Colors.white, size: 24));
  }
}