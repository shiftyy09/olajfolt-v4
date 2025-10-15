import 'dart:io';

// A közös widgetek importálása a te projektstruktúrád alapján
import 'package:car_maintenance_app/widgetek/kozos_widgetek.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
  // A háttérlogika és a változók érintetlenek maradnak...
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
  File? _imageFile;
  bool _isPickingImage = false; // Dupla kattintás elleni védelem

  final List<String> _dateBasedServiceTypes = ['Műszaki vizsga'];
  final List<String> _kmBasedServiceTypes = [
    'Olajcsere',
    'Légszűrő',
    'Pollenszűrő',
    'Gyújtógyertya',
    'Üzemanyagszűrő',
    'Vezérlés (Szíj)',
    'Fékbetét (első)',
    'Fékbetét (hátsó)',
    'Fékfolyadék',
    'Hűtőfolyadék',
    'Kuplung',
  ];
  late List<String> _allServiceTypes;
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

  // A HÁTTÉRLOGIKA (initState, dispose, stb.) VÁLTOZATLAN MARAD
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

    if (widget.vehicleToEdit?.imagePath != null &&
        widget.vehicleToEdit!.imagePath!.isNotEmpty) {
      _imageFile = File(widget.vehicleToEdit!.imagePath!);
    }

    if (_selectedMake != null && !_supportedCarMakes.contains(_selectedMake)) {
      if (_selectedMake!.isNotEmpty)
        _supportedCarMakes.insert(0, _selectedMake!);
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

  Future<void> _loadMaintenanceData(Jarmu vehicle) async {
    final records =
    await AdatbazisKezelo.instance.getServicesForVehicle(vehicle.id!);
    for (var recordMap in records) {
      final record = Szerviz.fromMap(recordMap);
      for (var type in _allServiceTypes) {
        if (record.description
            .toLowerCase()
            .contains(type.toLowerCase().replaceAll(" (szíj)", ""))) {
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

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
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
    String? finalImagePath;
    if (_imageFile != null) {
      if (widget.vehicleToEdit == null ||
          _imageFile!.path != widget.vehicleToEdit?.imagePath) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(_imageFile!.path);
        final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');
        finalImagePath = savedImage.path;
      } else {
        finalImagePath = widget.vehicleToEdit?.imagePath;
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
        imagePath: finalImagePath);
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
          if (type == 'Vezérlés (Szíj)' && _selectedVezerlesTipus != 'Szíj') {
            continue;
          }
          if (_serviceEnabledStates[type] == true) {
            String description = '$type (automatikus bejegyzés)';
            int cost = 0;
            if (_dateBasedServiceTypes.contains(type) &&
                _dateBasedServiceDates[type] != null) {
              final serviceRecord = Szerviz(
                  vehicleId: vehicleId,
                  description: description,
                  date: _dateBasedServiceDates[type]!,
                  cost: cost,
                  mileage: vehicle.mileage);
              await db.insert('services', serviceRecord.toMap());
            } else if (_kmBasedServiceTypes.contains(type)) {
              final controller = _kmBasedServiceControllers[type];
              final mileageToSave = int.tryParse(controller?.text ?? '');
              if (mileageToSave != null) {
                final serviceRecord = Szerviz(
                    vehicleId: vehicleId,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.isUniqueConstraintError()
                ? 'Hiba: Ez a rendszám már foglalt!'
                : 'Adatbázis hiba!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  // === TELJESEN ÚJRAÍRT BUILD FÜGGVÉNY ===
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFF121212),
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
            widget.vehicleToEdit == null ? 'Új Jármű' : 'Jármű Szerkesztése'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // --- Alapinformációk ---
            _buildMakeDropdown(),
            _buildTextField(
                title: 'Modell',
                controller: _modelController,
                icon: Icons.star_outline),
            _buildTextField(
                title: 'Évjárat',
                controller: _yearController,
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                maxLength: 4),
            _buildDropdown(title: 'Vezérlés', icon: Icons.settings),
            _buildTextField(
                title: 'Kilométeróra',
                controller: _mileageController,
                icon: Icons.speed,
                keyboardType: TextInputType.number),
            _buildTextField(
                title: 'Rendszám',
                controller: _licensePlateController,
                icon: Icons.pin),
            _buildTextField(
                title: 'Alvázszám',
                controller: _vinController,
                icon: Icons.qr_code,
                optional: true),

            // --- Képfeltöltés ---
            _buildImageUploader(),

            const SizedBox(height: 16),
            // --- Karbantartás ---
            KozosMenuKartya(
              icon: Icons.handyman_outlined,
              title: "Karbantartási emlékeztetők",
              subtitle: "Automatikus értesítések beállítása",
              color: Colors.purple,
              // A Főoldalon is lila volt a hasonló menü
              onTap: () =>
                  setState(() => _remindersEnabled = !_remindersEnabled),
              trailing: Switch(
                value: _remindersEnabled,
                onChanged: (value) => setState(() => _remindersEnabled = value),
                activeColor: Colors.purple,
                inactiveThumbColor: Colors.grey,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _remindersEnabled
                  ? _buildReminderContent()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 100), // Tér a lebegő gombnak
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
    );
  }

  // === ÚJ, KÖZÖS WIDGETEN ALAPULÓ SEGÉDFÜGGVÉNYEK ===

  Widget _buildTextField({required String title,
    required TextEditingController controller,
    required IconData icon,
    bool optional = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength}) {
    return KozosBemenetiKartya(
      icon: icon,
      title: optional ? '$title (opcionális)' : title,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        validator: (value) {
          if (!optional && (value == null || value.isEmpty))
            return 'Kötelező mező';
          if (title == 'Évjárat' &&
              value != null &&
              value.isNotEmpty &&
              value.length != 4) return '4 számjegy';
          return null;
        },
      ),
    );
  }

  Widget _buildMakeDropdown() {
    return KozosBemenetiKartya(
      icon: Icons.directions_car,
      title: 'Márka',
      padding: const EdgeInsets.only(left: 16, right: 10, top: 12, bottom: 12),
      child: DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: "Keresés...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange))),
          ),
          menuProps: MenuProps(backgroundColor: const Color(0xFF2A2A2A)),
          itemBuilder: (context, item, isSelected) =>
              ListTile(
                  title: Text(item,
                      style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.white))),
        ),
        dropdownDecoratorProps: const DropDownDecoratorProps(
          baseStyle: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          dropdownSearchDecoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true),
        ),
        items: _supportedCarMakes,
        selectedItem: _selectedMake,
        onChanged: (String? newValue) =>
            setState(() => _selectedMake = newValue),
        validator: (value) =>
        (value == null || value.isEmpty) ? 'Kötelező mező' : null,
      ),
    );
  }

  Widget _buildDropdown({required String title, required IconData icon}) {
    return KozosBemenetiKartya(
      icon: icon,
      title: title,
      padding: const EdgeInsets.only(left: 16, right: 10, top: 12, bottom: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedVezerlesTipus,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
          onChanged: (String? newValue) {
            if (newValue != null)
              setState(() {
                _selectedVezerlesTipus = newValue;
                if (newValue == 'Lánc') {
                  _serviceEnabledStates['Vezérlés (Szíj)'] = false;
                  _kmBasedServiceControllers['Vezérlés (Szíj)']?.clear();
                  _serviceErrors['Vezérlés (Szíj)'] = null;
                }
              });
          },
          items: _vezerlesOptions
              .map<DropdownMenuItem<String>>(
                  (String value) =>
                  DropdownMenuItem<String>(
                      value: value, child: Text(value)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    bool hasImage = _imageFile != null;
    return KozosMenuKartya(
      icon: Icons.image_outlined,
      title: hasImage ? "Kép cseréje" : "Autód fényképének csatolása",
      subtitle: hasImage ? "Koppints a módosításhoz" : "Galéria megnyitása",
      color: Colors.pinkAccent,
      onTap: _pickImage,
      trailing: hasImage
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _imageFile!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      )
          : const Icon(Icons.add_a_photo_outlined, color: Colors.white30),
    );
  }

  // Az emlékeztetőkhöz tartozó widgetek (ezek a te kódodból származnak, stílusuk maradhat)
  Widget _buildReminderContent() {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ..._dateBasedServiceTypes.map((type) => _buildDatePickerRow(type)),
            ..._kmBasedServiceTypes.map((type) {
              if (type == 'Vezérlés (Szíj)' &&
                  _selectedVezerlesTipus != 'Szíj') {
                return const SizedBox.shrink();
              }
              return _buildMileageInputRow(type,
                  key: ValueKey('mileage_input_$type'));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(String serviceType) {
    final hint = 'Lejárati dátum';
    bool isEnabled = _serviceEnabledStates[serviceType] ?? false;
    String dateText = _dateBasedServiceDates[serviceType] != null
        ? DateFormat('yyyy. MM. dd.')
        .format(_dateBasedServiceDates[serviceType]!)
        : hint;
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
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(dateText,
                  style: TextStyle(
                      color: isEnabled ? Colors.white : Colors.grey[600],
                      fontSize: 16)),
              const SizedBox(width: 8),
              Icon(Icons.edit_calendar,
                  color: isEnabled ? Colors.white70 : Colors.transparent,
                  size: 20)
            ])));
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
                      label: const Text('km',
                          style: TextStyle(color: Colors.black)),
                      backgroundColor:
                      isEnabled ? Colors.white70 : Colors.transparent,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ))));
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
            ? (hasError ? Colors.red.withOpacity(0.25) : Colors.black
            .withOpacity(0.3))
            : Colors.transparent,
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
                          child: Text(errorText!,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)))
                  ],
                ))));
  }
}