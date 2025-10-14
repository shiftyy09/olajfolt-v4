// lib/modellek/karbantartas_bejegyzes.dart

// Átnevezzük az osztályt Szerviz-re a logikai tisztaság kedvéért
class Szerviz {
  final int? id;
  final int vehicleId;
  final String description; // Leírás
  final DateTime date; // Dátum
  final int cost; // Költség
  final int mileage; // Km állás

  Szerviz({
    this.id,
    required this.vehicleId,
    required this.description,
    required this.date,
    required this.cost,
    required this.mileage,
  });

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