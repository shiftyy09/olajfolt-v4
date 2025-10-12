// lib/modellek/karbantartas.dart

class Karbantartas {
  final int? id;
  final int vehicleId;
  final String serviceType;
  final String date;
  final int mileage;

  // A 'description' (notes) és 'cost' mezők eltávolítva

  Karbantartas({
    this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.mileage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'date': date,
      'mileage': mileage,
    };
  }

  factory Karbantartas.fromMap(Map<String, dynamic> map) {
    return Karbantartas(
      id: map['id'],
      vehicleId: map['vehicleId'],
      serviceType: map['serviceType'],
      date: map['date'],
      mileage: map['mileage'],
    );
  }
}