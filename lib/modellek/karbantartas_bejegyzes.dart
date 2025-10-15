// lib/modellek/karbantartas_bejegyzes.dart

class Szerviz {
  final int? id;
  final int vehicleId;
  final String description;
  final DateTime date;
  final int cost;
  final int mileage;

  Szerviz({
    this.id,
    required this.vehicleId,
    required this.description,
    required this.date,
    required this.cost,
    required this.mileage,
  });

  // ===================================
  //  ÚJ FÜGGVÉNY A HIBA JAVÍTÁSÁHOZ
  // ===================================
  Szerviz copyWith({
    int? id,
    int? vehicleId,
    String? description,
    DateTime? date,
    int? cost,
    int? mileage,
  }) {
    return Szerviz(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      description: description ?? this.description,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
    );
  }

  factory Szerviz.fromMap(Map<String, dynamic> map) {
    return Szerviz(
      id: map['id'],
      vehicleId: map['vehicleId'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      cost: map['cost'],
      mileage: map['mileage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'description': description,
      'date': date.toIso8601String(),
      'cost': cost,
      'mileage': mileage,
    };
  }
}