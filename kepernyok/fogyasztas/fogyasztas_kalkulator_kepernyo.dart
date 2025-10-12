// lib/kepernyok/fogyasztas/fogyasztas_kalkulator_kepernyo.dart
import 'package:flutter/material.dart';

// Az osztály nevét a fájlnévhez igazítottam
class FogyasztasKalkulatorKepernyo extends StatefulWidget {
  const FogyasztasKalkulatorKepernyo({super.key});

  @override
  State<FogyasztasKalkulatorKepernyo> createState() =>
      _FogyasztasKalkulatorKepernyoState();
}

class _FogyasztasKalkulatorKepernyoState
    extends State<FogyasztasKalkulatorKepernyo> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _consumptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _result = '';

  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      // A tizedesvesszőt is elfogadjuk
      final distance =
          double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;
      final consumption =
          double.tryParse(_consumptionController.text.replaceAll(',', '.')) ??
              0;
      final price =
          double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

      if (distance > 0 && consumption > 0 && price > 0) {
        final totalFuel = (distance / 100) * consumption;
        final totalCost = totalFuel * price;

        setState(() {
          _result =
          'Az út teljes költsége: ${totalCost.toStringAsFixed(0)} Ft\n'
              'Szükséges üzemanyag: ${totalFuel.toStringAsFixed(2)} liter';
        });
        // A billentyűzetet elrejtjük a számítás után
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _consumptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Fogyasztás kalkulátor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextFormField(
              controller: _distanceController,
              labelText: 'Megteendő távolság (km)',
              icon: Icons.edit_road,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _consumptionController,
              labelText: 'Átlagfogyasztás (l/100km)',
              icon: Icons.local_gas_station,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _priceController,
              labelText: 'Üzemanyagár (Ft/l)',
              icon: Icons.price_change,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _calculateCost,
              child: const Text('Számítás'),
            ),
            const SizedBox(height: 32),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Text(
                  _result,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
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