// lib/kepernyok/karbantartas/karbantartas_adatbevitel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KarbantartasAdatbevitel extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  final String vezerlesTipusa;

  const KarbantartasAdatbevitel({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.vezerlesTipusa,
  });

  @override
  State<KarbantartasAdatbevitel> createState() =>
      _KarbantartasAdatbevitelState();
}

class _KarbantartasAdatbevitelState extends State<KarbantartasAdatbevitel> {
  // ÚJ CONTROLLEREK A MEZŐKHÖZ
  final _lastOilChangeKmController = TextEditingController();
  final _lastTimingBeltKmController = TextEditingController();
  final _lastBrakeFluidKmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Betöltjük a korábban mentett adatokat, ha vannak
  }

  @override
  void dispose() {
    _lastOilChangeKmController.dispose();
    _lastTimingBeltKmController.dispose();
    _lastBrakeFluidKmController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastOilChangeKmController.text =
          (prefs.getInt('lastOilChangeKm_${widget.vehicleId}') ?? '')
              .toString();
      _lastTimingBeltKmController.text =
          (prefs.getInt('lastTimingBeltKm_${widget.vehicleId}') ?? '')
              .toString();
      _lastBrakeFluidKmController.text =
          (prefs.getInt('lastBrakeFluidKm_${widget.vehicleId}') ?? '')
              .toString();
    });
  }

  // AZ ÚJ MENTÉSI LOGIKA
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('lastOilChangeKm_${widget.vehicleId}',
        int.tryParse(_lastOilChangeKmController.text) ?? 0);

    if (widget.vezerlesTipusa == 'Szíj') {
      await prefs.setInt('lastTimingBeltKm_${widget.vehicleId}',
          int.tryParse(_lastTimingBeltKmController.text) ?? 0);
    }

    await prefs.setInt('lastBrakeFluidKm_${widget.vehicleId}',
        int.tryParse(_lastBrakeFluidKmController.text) ?? 0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alapadatok sikeresen mentve!'),
          backgroundColor: Colors.green,
        ),
      );
      // Visszaadjuk a "true" értéket, jelezve a sikeres mentést.
      Navigator.of(context).pop(true);
    }
  }

  // Egy segédfüggvény a beviteli mezők egységes kinézetéhez
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.orange),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.vehicleName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Szerviz Alapadatok Megadása',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add meg a legutóbbi szervizek kilométeróra állását.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ÚJ BEVITELI MEZŐK
            _buildTextField(
              controller: _lastOilChangeKmController,
              label: 'Utolsó olajcsere (km)',
            ),
            const SizedBox(height: 16),
            if (widget.vezerlesTipusa == 'Szíj') ...[
              _buildTextField(
                controller: _lastTimingBeltKmController,
                label: 'Utolsó vezérműszíj csere (km)',
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(
              controller: _lastBrakeFluidKmController,
              label: 'Utolsó fékolaj csere (km)',
            ),

            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text('Mentés'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}