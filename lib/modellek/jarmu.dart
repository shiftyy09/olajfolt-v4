// lib/modellek/jarmu.dart

class Jarmu {
  final int? id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String? vin;
  final int mileage;
  final String? vezerlesTipusa;

  Jarmu({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.vin,
    required this.mileage,
    this.vezerlesTipusa,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'mileage': mileage,
      'vezerlesTipusa': vezerlesTipusa,
    };
  }

  factory Jarmu.fromMap(Map<String, dynamic> map) {
    return Jarmu(
      id: map['id'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      licensePlate: map['licensePlate'],
      vin: map['vin'],
      mileage: map['mileage'],
      vezerlesTipusa: map['vezerlesTipusa'],
    );
  }

  // === EZT A BLOKKOT ADTAD HOZZÁ ===
  Jarmu copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    int? mileage,
    String? vezerlesTipusa,
  }) {
    return Jarmu(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
      vezerlesTipusa: vezerlesTipusa ?? this.vezerlesTipusa,
    );
  }
// === A BLOKK VÉGE ===
}