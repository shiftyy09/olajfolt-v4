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
  final String? imagePath; // <-- ÚJ MEZŐ

  Jarmu({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    this.vin,
    required this.mileage,
    this.vezerlesTipusa,
    this.imagePath, // <-- ÚJ PARAMÉTER
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
      'imagePath': imagePath, // <-- ÚJ
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
      imagePath: map['imagePath'], // <-- ÚJ
    );
  }

  Jarmu copyWith({
    int? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    int? mileage,
    String? vezerlesTipusa,
    String? imagePath, // <-- ÚJ
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
      imagePath: imagePath ?? this.imagePath, // <-- ÚJ
    );
  }
}