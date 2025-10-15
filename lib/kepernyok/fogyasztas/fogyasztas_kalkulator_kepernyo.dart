import 'package:car_maintenance_app/alap/adatbazis/adatbazis_kezelo.dart';
import 'package:car_maintenance_app/modellek/jarmu.dart';
import 'package:car_maintenance_app/modellek/karbantartas_bejegyzes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FogyasztasKalkulatorKepernyo extends StatefulWidget {
  final Jarmu vehicle;

  const FogyasztasKalkulatorKepernyo({super.key, required this.vehicle});

  @override
  State<FogyasztasKalkulatorKepernyo> createState() =>
      _FogyasztasKalkulatorKepernyoState();
}

class _FogyasztasKalkulatorKepernyoState
    extends State<FogyasztasKalkulatorKepernyo> {
  final _formKey = GlobalKey<FormState>();
  final _literController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _odometerController = TextEditingController();

  double _monthlyCost = 0;
  double _monthlyLiters = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _literController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
    _loadMonthlyStats();
  }

  // ===================================
  //  ÚJ FÜGGVÉNY: INFORMÁCIÓS ABLAK
  // ===================================
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
                    'Ezen a képernyőn egyszerűen rögzítheted a tankolásaidat, a program pedig automatikusan összegzi a havi költségeidet.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 15),
                  Text('Működése:', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                      '1. Töltsd ki a tankolt mennyiséget, az egységárat és a km-óra állását.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('2. A "Teljes költség" automatikusan kiszámolódik.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text(
                      '3. A "Mentés" gombbal az adatokat elmentjük a Szerviznaplóba.',
                      style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 15),
                  Text(
                    'Az alsó kártya mindig az aktuális hónapban elköltött összesített üzemanyag-költséget és mennyiséget mutatja.',
                    style: TextStyle(color: Colors.white70),
                  ),
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

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoading = true);
    final db = AdatbazisKezelo.instance;
    final allServices = await db.getServicesForVehicle(widget.vehicle.id!);
    final now = DateTime.now();

    double cost = 0;
    double liters = 0;

    for (var serviceMap in allServices) {
      final service = Szerviz.fromMap(serviceMap);
      if (service.date.month == now.month &&
          service.date.year == now.year &&
          service.description.startsWith('Tankolás')) {
        cost += service.cost;
        final literString =
        service.description
            .split('(')
            .last
            .replaceAll(' liter)', '');
        liters += double.tryParse(literString) ?? 0;
      }
    }

    setState(() {
      _monthlyCost = cost;
      _monthlyLiters = liters;
      _isLoading = false;
    });
  }

  void _calculateTotal() {
    final liters =
        double.tryParse(_literController.text.replaceAll(',', '.')) ?? 0;
    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    if (liters > 0 && price > 0) {
      final total = liters * price;
      _totalCostController.text = total.toStringAsFixed(0);
    } else {
      _totalCostController.text = '';
    }
  }

  Future<void> _saveFueling() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final liters =
          double.tryParse(_literController.text.replaceAll(',', '.')) ?? 0;
      final cost =
      (double.tryParse(_totalCostController.text.replaceAll(',', '.')) ?? 0)
          .toInt();
      final odometer =
          int.tryParse(_odometerController.text.replaceAll(',', '.')) ?? 0;

      final newFueling = Szerviz(
        vehicleId: widget.vehicle.id!,
        date: DateTime.now(),
        mileage: odometer,
        description: 'Tankolás ($liters liter)',
        cost: cost,
      );

      final db = AdatbazisKezelo.instance;
      await db.insert('services', newFueling.toMap());

      _literController.clear();
      _priceController.clear();
      _odometerController.clear();
      _loadMonthlyStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tankolás sikeresen rögzítve!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _literController.dispose();
    _priceController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${widget.vehicle.make} - Tankolás'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ===================================
        //  KIEGÉSZÍTÉS: INFO GOMB AZ APPBAR-BAN
        // ===================================
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.cyanAccent),
            onPressed: _showInfoDialog,
            tooltip: 'Hogyan működik?',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            _buildStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Új tankolás rögzítése',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _literController,
              labelText: 'Tankolt mennyiség (liter)',
              icon: Icons.opacity_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _priceController,
              labelText: 'Egységár (Ft/liter)',
              icon: Icons.price_change_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _odometerController,
              labelText: 'Jelenlegi km-óra állás',
              icon: Icons.speed_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _totalCostController,
              labelText: 'Teljes költség (Ft)',
              icon: Icons.monetization_on_outlined,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.save, size: 24),
      label: const Text('Tankolás mentése'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green.shade600,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        elevation: 5,
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: _saveFueling,
    );
  }

  Widget _buildStatsCard() {
    final monthName =
    DateFormat.MMMM('hu_HU').format(DateTime.now()).toUpperCase();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: Colors.cyan.withOpacity(0.3), width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName havi összegzés',
              style: TextStyle(
                  color: Colors.cyan.shade300,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              icon: Icons.monetization_on_outlined,
              label: 'Összesen költöttél',
              value:
              '${NumberFormat.decimalPattern('hu_HU').format(_monthlyCost)} Ft',
              color: Colors.white,
            ),
            const Divider(color: Colors.white24, height: 25),
            _buildResultRow(
              icon: Icons.local_gas_station_outlined,
              label: 'Összesen tankoltál',
              value: '${_monthlyLiters.toStringAsFixed(2)} liter',
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow({required IconData icon,
    required String label,
    required String value,
    required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
          color: readOnly ? Colors.white70 : Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: readOnly ? const Color(0xFF252525) : const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (readOnly) return null;
        if (value == null || value.isEmpty) {
          return 'Kérjük, töltse ki ezt a mezőt!';
        }
        if (double.tryParse(value.replaceAll(',', '.')) == null) {
          return 'Kérjük, érvényes számot adjon meg!';
        }
        return null;
      },
    );
  }
}