import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; // A 'max' függvényhez
import 'package:intl/intl.dart'; // Dátumformázáshoz
import '../../alap/adatbazis/adatbazis_kezelo.dart';
import '../../modellek/jarmu.dart';
import '../../modellek/karbantartas.dart';

class KarbantartasEmlekezteto extends StatefulWidget {
  const KarbantartasEmlekezteto({super.key});

  @override
  State<KarbantartasEmlekezteto> createState() =>
      _KarbantartasEmlekeztetoState();
}

class _KarbantartasEmlekeztetoState extends State<KarbantartasEmlekezteto> {
  Jarmu? _selectedVehicle;
  Future<List<Karbantartas>>? _maintenanceFuture;
  final TextEditingController _mileageController = TextEditingController();

  final Map<String, int> _serviceIntervals = {
    'Olajcsere': 15000,
    'Levegőszűrő csere': 30000,
    'Pollenszűrő csere': 30000,
    'Üzemanyagszűrő csere': 60000,
    'Vezérműszíj/lánc csere': 120000,
    'Akkumulátor csere': 200000,
    'Fékbetét csere (első)': 50000,
    'Fékbetét csere (hátsó)': 70000,
    'Fékfolyadék csere': 60000,
    'Hűtőfolyadék csere': 100000,
    'Egyéb ellenőrzés': 15000,
    // A Műszaki vizsgának nincs km intervalluma, azt külön kezeljük
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
    final vehicles =
    (await db.getVehicles()).map((e) => Jarmu.fromMap(e)).toList();

    if (!mounted) return;

    if (vehicles.isEmpty) {
      setState(() {
        _selectedVehicle = null;
      });
      return;
    }

    Jarmu? selected = vehicles.length == 1 ? vehicles.first : await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title:
          const Text(
              'Válassz járművet!', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      '${vehicles[index].make} ${vehicles[index].model}',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(vehicles[index].licensePlate,
                      style: const TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.of(context).pop(vehicles[index]),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _loadDataForVehicle(selected);
    } else {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _loadDataForVehicle(Jarmu vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _mileageController.text = vehicle.mileage.toString();
      _maintenanceFuture = AdatbazisKezelo.instance
          .getMaintenanceForVehicle(vehicle.id!)
          .then((data) =>
          data.map((item) => Karbantartas.fromMap(item)).toList());
    });
  }

  Future<void> _updateMileage() async {
    if (_selectedVehicle == null) return;

    final newMileage = int.tryParse(_mileageController.text);
    if (newMileage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Érvénytelen kilométeróra-állás!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Okosabb ellenőrzés
    final allServices = await AdatbazisKezelo.instance.getMaintenanceForVehicle(
        _selectedVehicle!.id!);
    int maxServiceMileage = 0;
    if (allServices.isNotEmpty) {
      final kmServices = allServices.where((s) =>
      Karbantartas
          .fromMap(s)
          .serviceType != 'Műszaki vizsga');
      if (kmServices.isNotEmpty) {
        maxServiceMileage = kmServices
            .map((s) =>
        Karbantartas
            .fromMap(s)
            .mileage)
            .reduce(max);
      }
    }

    if (newMileage < maxServiceMileage) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Az új érték ($newMileage km) nem lehet kisebb, mint a legutóbbi rögzített szerviz ($maxServiceMileage km)!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final updatedVehicle = Jarmu(
        id: _selectedVehicle!.id,
        make: _selectedVehicle!.make,
        model: _selectedVehicle!.model,
        year: _selectedVehicle!.year,
        licensePlate: _selectedVehicle!.licensePlate,
        vin: _selectedVehicle!.vin,
        vezerlesTipusa: _selectedVehicle!.vezerlesTipusa,
        mileage: newMileage);

    await AdatbazisKezelo.instance.update('vehicles', updatedVehicle.toMap());

    setState(() {
      _selectedVehicle = updatedVehicle;
    });

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kilométeróra-állás frissítve!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Karbantartas? _findLastService(List<Karbantartas> allServices, String type) {
    try {
      final servicesOfType = allServices
          .where((s) => s.serviceType == type)
          .toList();
      if (servicesOfType.isEmpty) return null;
      // Km alapúaknál a legmagasabb km-t, dátum alapúnál a legújabb dátumot keressük
      if (type == 'Műszaki vizsga') {
        servicesOfType.sort((a, b) =>
            DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
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
        title: Text(
          _selectedVehicle != null
              ? 'Emlékeztető: ${_selectedVehicle!.make}'
              : 'Karbantartási Emlékeztető',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedVehicle != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _selectVehicle(context),
            )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedVehicle == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Nincs jármű a parkban.\nElőször vegyél fel egyet a Járműparkban!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    if (_maintenanceFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildMileageUpdater(),
        Expanded(
          child: FutureBuilder<List<Karbantartas>>(
            future: _maintenanceFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Hiba: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
              }

              final allServices = snapshot.data ?? [];
              final List<Widget> cards = [];

              // 1. MŰSZAKI VIZSGA KÁRTYA HOZZÁADÁSA (ha van)
              final lastExam = _findLastService(allServices, 'Műszaki vizsga');
              if (lastExam != null) {
                cards.add(_buildExamInfoCard(exam: lastExam));
              }

              // 2. TÖBBI (KM-ALAPÚ) KÁRTYA HOZZÁADÁSA
              final serviceTypes = _serviceIntervals.keys.toList();
              final kmCards = serviceTypes.map((serviceType) {
                final lastService = _findLastService(allServices, serviceType);
                if (lastService != null) {
                  return _buildServiceInfoCard(
                    currentVehicleMileage: _selectedVehicle!.mileage,
                    title: serviceType,
                    lastMileage: lastService.mileage,
                  );
                }
                return null;
              }).whereType<Widget>().toList();

              cards.addAll(kmCards);

              if (cards.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Ehhez a járműhöz nincsenek események rögzítve a Jármű szerkesztése képernyőn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
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

  Widget _buildMileageUpdater() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.speed, color: Colors.cyan),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _mileageController,
                style: const TextStyle(color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Aktuális km óra állás',
                  labelStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            ElevatedButton(
              onPressed: _updateMileage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                  'Frissít', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  // ÚJ: Kártya a műszaki vizsgához
  Widget _buildExamInfoCard({ required Karbantartas exam }) {
    final expiryDate = DateTime.parse(exam.date);
    final daysLeft = expiryDate
        .difference(DateTime.now())
        .inDays;

    final statusColor = _getDateStatusColor(daysLeft: daysLeft);
    final formattedDate = DateFormat('yyyy. MM. dd.').format(expiryDate);
    String statusText;
    if (daysLeft > 0) {
      statusText = 'Még $daysLeft nap van hátra';
    } else if (daysLeft == 0) {
      statusText = 'Ma jár le!';
    } else {
      statusText = 'Lejárt ${daysLeft.abs()} napja!';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: statusColor, width: 1.5)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: statusColor, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Műszaki vizsga',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Lejárat', formattedDate),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // KM-alapú kártya
  Widget _buildServiceInfoCard({
    required int currentVehicleMileage,
    required String title,
    required int lastMileage,
  }) {
    final interval = _serviceIntervals[title] ?? 1000000;
    final kmSinceLastService = currentVehicleMileage - lastMileage;
    final kmLeft = interval - kmSinceLastService;
    final double progress = (kmSinceLastService / interval).clamp(0.0, 1.0);

    final statusColor = _getStatusColor(kmLeft: kmLeft, interval: interval);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconDataForService(title), color: statusColor,
                    size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Előző csere', '$lastMileage km'),
                _buildInfoColumn('Intervallum', '$interval km'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade700,
              color: statusColor,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                kmLeft > 0 ? 'Még hátrvan: $kmLeft km' : 'Csere esedékes!',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  IconData _getIconDataForService(String serviceType) {
    if (serviceType.contains('Műszaki')) return Icons.calendar_today;
    if (serviceType.contains('Olaj')) return Icons.filter_list;
    if (serviceType.contains('Fék')) return Icons.car_repair_outlined;
    if (serviceType.contains('szűrő')) return Icons.air;
    if (serviceType.contains('Vezérmű')) return Icons.settings;
    if (serviceType.contains('Akkumulátor')) return Icons.battery_charging_full;
    if (serviceType.contains('Hűtőfolyadék')) return Icons.opacity;
    return Icons.miscellaneous_services;
  }

  // Szín km alapján
  Color _getStatusColor({required int kmLeft, required int interval}) {
    if (kmLeft <= 0) {
      return Colors.redAccent.shade200; // PIROS
    } else if (kmLeft <= interval * 0.3) {
      return Colors.amber.shade400; // SÁRGA
    } else {
      return Colors.green.shade400; // ZÖLD
    }
  }

  // ÚJ: Szín dátum alapján
  Color _getDateStatusColor({required int daysLeft}) {
    if (daysLeft <= 30) {
      return Colors.redAccent.shade200; // PIROS (30 napon belül)
    } else if (daysLeft <= 90) {
      return Colors.amber.shade400; // SÁRGA (90 napon belül)
    } else {
      return Colors.green.shade400; // ZÖLD
    }
  }
}