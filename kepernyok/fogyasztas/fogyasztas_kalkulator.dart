import 'package:flutter/material.dart';

// Az osztály neve itt még angolul volt, ezt javítottam
class FogyasztasKalkulator extends StatefulWidget {
  const FogyasztasKalkulator({super.key});

  @override
  State<FogyasztasKalkulator> createState() => _FogyasztasKalkulatorState();
}

class _FogyasztasKalkulatorState extends State<FogyasztasKalkulator> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _consumptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _result = '';

  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      final distance = double.tryParse(_distanceController.text) ?? 0;
      final consumption = double.tryParse(_consumptionController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;

      if (distance > 0 && consumption > 0 && price > 0) {
        final totalFuel = (distance / 100) * consumption;
        final totalCost = totalFuel * price;

        setState(() {
          _result =
          'Az út teljes költsége: ${totalCost.toStringAsFixed(0)} Ft\n'
              'Szükséges üzemanyag: ${totalFuel.toStringAsFixed(2)} liter';
        });
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
    const accentOrange = Color.fromARGB(255, 255, 164, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fogyasztás kalkulátor'),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _calculateCost,
                child: const Text('Költség számítása'),
              ),
              const SizedBox(height: 32),
              if (_result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentOrange),
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
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    const border = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.orange),
    );

    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange),
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.orange),
        filled: true,
        fillColor: Colors.grey[900]?.withOpacity(0.5),
        enabledBorder: border,
        focusedBorder: border,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kérjük, töltse ki ezt a mezőt!';
        }
        if (double.tryParse(value) == null) {
          return 'Kérjük, érvényes számot adjon meg!';
        }
        return null;
      },
    );
  }
}