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
  //  A copyWith függvény (ez már jó volt)
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

  // ===================================
  //  A JAVÍTOTT fromMap FÜGGVÉNY
  // ===================================
  factory Szerviz.fromMap(Map<String, dynamic> map) {
    return Szerviz(
      id: map['id'],
      vehicleId: map['vehicleId'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      // JAVÍTÁS: A 'cost' értéket, ami 'double' is lehet, 'int'-té alakítjuk.
      // A '(map['cost'] as num)' biztosítja, hogy int és double esetén is helyesen működjön.
      cost: (map['cost'] as num).toInt(),
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