// lib/kepernyok/karbantartas/karbantartas_emlekezteto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas_bejegyzes.dart'; // Ez a Szerviz modellt tartalmazza

class KarbantartasEmlekezteto extends StatefulWidget {
  const KarbantartasEmlekezteto({super.key});

  @override
  State<KarbantartasEmlekezteto> createState() =>
      _KarbantartasEmlekeztetoState();
}

class _KarbantartasEmlekeztetoState extends State<KarbantartasEmlekezteto> {
  Jarmu? _selectedVehicle;
  Future<List<Szerviz>>? _serviceHistoryFuture;
  final TextEditingController _mileageController = TextEditingController();

  // === JAVÍTVA: A kulcsszavak egyszerűbbek a könnyebb keresés érdekében ===
  final Map<String, int> _serviceIntervals = {
    'Olaj': 15000, // Elég az "Olaj" szóra keresni
    'Levegőszűrő': 30000,
    'Pollenszűrő': 30000,
    'Üzemanyagszűrő': 60000,
    'Vezérlés': 120000, // Elég a "Vezérlés" szóra keresni
    'Fékbetét (első)': 50000,
    'Fékbetét (hátsó)': 70000,
    'Fékfolyadék': 60000,
    'Hűtőfolyadék': 100000,
  };
  final Map<String, int> _dateIntervalsInYears = {
    'Műszaki': 2, // Elég a "Műszaki" szóra keresni
    'Akkumulátor': 5,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _selectVehicle(context));
  }

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectVehicle(BuildContext context) async {
    final db = AdatbazisKezelo.instance;
    final vehicles = (await db.getVehicles())
        .map((e) => Jarmu.fromMap(e))
        .toList();
    if (!mounted) return;
    if (vehicles.isEmpty) {
      setState(() => _selectedVehicle = null);
      return;
    }
    Jarmu? selected = vehicles.length == 1 ? vehicles.first : await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
                'Válassz járművet!', style: TextStyle(color: Colors.white)),
            content: SizedBox(width: double.maxFinite, child: ListView.builder(
              shrinkWrap: true, itemCount: vehicles.length,
              itemBuilder: (context, index) =>
                  ListTile(
                    title: Text(
                        '${vehicles[index].make} ${vehicles[index].model}',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(vehicles[index].licensePlate,
                        style: const TextStyle(color: Colors.white70)),
                    onTap: () => Navigator.of(context).pop(vehicles[index]),
                  ),
            )),
          ),
    );
    if (selected != null) {
      _loadDataForVehicle(selected);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _loadDataForVehicle(Jarmu vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _mileageController.text = vehicle.mileage.toString();
      _serviceHistoryFuture = AdatbazisKezelo.instance
          .getServicesForVehicle(vehicle.id!)
          .then((data) => data.map((item) => Szerviz.fromMap(item)).toList());
    });
  }

  Future<void> _updateMileage() async {
    if (_selectedVehicle == null) return;
    final newMileage = int.tryParse(_mileageController.text);
    if (newMileage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Érvénytelen kilométeróra-állás!'),
          backgroundColor: Colors.redAccent));
      return;
    }
    final updatedVehicle = _selectedVehicle!.copyWith(mileage: newMileage);
    await AdatbazisKezelo.instance.update('vehicles', updatedVehicle.toMap());
    setState(() {
      _selectedVehicle = updatedVehicle;
    });
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kilométeróra-állás frissítve!'),
        backgroundColor: Colors.green));
  }

  Szerviz? _findLastService(List<Szerviz> allServices, String keyword) {
    try {
      final servicesOfType = allServices
          .where((s) =>
          s.description.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
      if (servicesOfType.isEmpty) return null;
      if (_dateIntervalsInYears.containsKey(keyword)) {
        servicesOfType.sort((a, b) => b.date.compareTo(a.date));
      } else {
        servicesOfType.sort((a, b) => b.mileage.compareTo(a.mileage));
      }
      return servicesOfType.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(_selectedVehicle != null
            ? 'Emlékeztető: ${_selectedVehicle!.make}'
            : 'Karbantartási Emlékeztető'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedVehicle != null) IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _selectVehicle(context))
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedVehicle == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0),
        child: Text('Nincs jármű a parkban.\nElőször vegyél fel egyet!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18)),
      ));
    }
    if (_serviceHistoryFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildMileageUpdater(),
        Expanded(
          child: FutureBuilder<List<Szerviz>>(
            future: _serviceHistoryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text(
                  'Hiba: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));

              final allServices = snapshot.data ?? [];
              final List<Widget> cards = [];

              // Dátum alapú kártyák
              _dateIntervalsInYears.forEach((keyword, years) {
                final lastService = _findLastService(allServices, keyword);
                if (lastService != null) {
                  // A kártya címének a teljes, szép nevet adjuk, ne csak a kulcsszót
                  String cardTitle = keyword == 'Műszaki'
                      ? 'Műszaki vizsga'
                      : keyword;
                  cards.add(_buildExamInfoCard(exam: lastService,
                      title: cardTitle,
                      validForYears: years));
                }
              });

              // Km alapú kártyák
              _serviceIntervals.forEach((keyword, interval) {
                final lastService = _findLastService(allServices, keyword);
                if (lastService != null) {
                  // A kártya címének a teljes, szép nevet adjuk, ne csak a kulcsszót
                  String cardTitle = keyword == 'Olaj'
                      ? 'Olajcsere'
                      : keyword == 'Vezérlés' ? 'Vezérléscsere' : keyword;
                  cards.add(_buildServiceInfoCard(
                      currentVehicleMileage: _selectedVehicle!.mileage,
                      title: cardTitle,
                      lastMileage: lastService.mileage));
                }
              });

              if (cards.isEmpty) {
                return const Center(
                    child: Padding(padding: EdgeInsets.all(24.0),
                      child: Text(
                          'Rögzíts egy eseményt a Szerviznaplóban, hogy itt megjelenjenek az emlékeztetők!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 18)),
                    ));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: cards[index],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- A kártyákat építő widgetek ---
  // A többi widget változatlan, csak idemásoltam őket a teljesség kedvéért
  Widget _buildMileageUpdater() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.speed, color: Colors.cyan),
        const SizedBox(width: 12),
        Expanded(child: TextField(
          controller: _mileageController,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(labelText: 'Aktuális km óra állás',
              labelStyle: TextStyle(color: Colors.white54, fontSize: 14),
              border: InputBorder.none,
              isDense: true),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        )),
        ElevatedButton(onPressed: _updateMileage,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text('Frissít', style: TextStyle(color: Colors.black)),
        ),
      ]),
    ));
  }

  Widget _buildExamInfoCard(
      { required Szerviz exam, required String title, required int validForYears }) {
    final expiryDate = DateTime(
        exam.date.year + validForYears, exam.date.month, exam.date.day);
    final daysLeft = expiryDate
        .difference(DateTime.now())
        .inDays;
    final statusColor = _getDateStatusColor(daysLeft: daysLeft);
    final formattedDate = DateFormat('yyyy. MM. dd.').format(expiryDate);
    String statusText;
    if (daysLeft > 0)
      statusText = 'Még $daysLeft nap van hátra';
    else if (daysLeft == 0)
      statusText = 'Ma jár le!';
    else
      statusText = 'Lejárt ${daysLeft.abs()} napja!';
    return Card(elevation: 4,
      margin: const EdgeInsets.only(bottom: 0),
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: statusColor, width: 1.5)),
      child: Padding(padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.calendar_today, color: statusColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold))
            ]),
            const Divider(height: 24, color: Colors.white24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildInfoColumn('Lejárat', formattedDate),
                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(statusText, style: TextStyle(color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))
                      ])
                ]),
          ])),
    );
  }

  Widget _buildServiceInfoCard(
      { required int currentVehicleMileage, required String title, required int lastMileage }) {
    final interval = _serviceIntervals[title] ?? _serviceIntervals.entries
        .firstWhere((e) => title.contains(e.key))
        .value;
    final kmSinceLastService = currentVehicleMileage - lastMileage;
    final kmLeft = interval - kmSinceLastService;
    final double progress = (kmSinceLastService / interval).clamp(0.0, 1.0);
    final statusColor = _getStatusColor(kmLeft: kmLeft, interval: interval);
    return Card(elevation: 4,
      margin: const EdgeInsets.only(bottom: 0),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(16.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_getIconDataForService(title), color: statusColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold))
            ]),
            const Divider(height: 24, color: Colors.white24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Előző csere', '$lastMileage km'),
                  _buildInfoColumn('Intervallum', '$interval km')
                ]),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress,
                backgroundColor: Colors.grey.shade700,
                color: statusColor,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3)),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight,
                child: Text(
                    kmLeft > 0 ? 'Még hátravan: $kmLeft km' : 'Csere esedékes!',
                    style: TextStyle(color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
          ])),
    );
  }

  Widget _buildInfoColumn(String label, String value) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ]);

  IconData _getIconDataForService(String serviceType) {
    if (serviceType.contains('Műszaki')) return Icons.calendar_today;
    if (serviceType.contains('Olaj')) return Icons.filter_list;
    if (serviceType.contains('Fék')) return Icons.directions_car_filled;
    if (serviceType.contains('szűrő')) return Icons.air;
    if (serviceType.contains('Vezérlés')) return Icons.settings;
    if (serviceType.contains('Akkumulátor')) return Icons.battery_charging_full;
    if (serviceType.contains('Hűtőfolyadék')) return Icons.opacity;
    return Icons.miscellaneous_services;
  }

  Color _getStatusColor({required int kmLeft, required int interval}) {
    if (kmLeft <= 0) return Colors.redAccent.shade200;
    if (kmLeft <= interval * 0.3) return Colors.amber.shade400;
    return Colors.green.shade400;
  }

  Color _getDateStatusColor({required int daysLeft}) {
    if (daysLeft <= 30) return Colors.redAccent.shade200;
    if (daysLeft <= 90) return Colors.amber.shade400;
    return Colors.green.shade400;
  }
}