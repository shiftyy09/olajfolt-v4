class KarbantartasBejegyzes {
  final int? id;
  final int vehicleId;
  final String date;
  final int mileage;
  final String servicePlace;
  final String description;
  final double laborCost;
  final double partsCost;
  final double totalCost;
  final String? notes;

  KarbantartasBejegyzes({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.servicePlace,
    required this.description,
    required this.laborCost,
    required this.partsCost,
    required this.totalCost,
    this.notes,
  });

  factory KarbantartasBejegyzes.fromMap(Map<String, dynamic> map) {
    return KarbantartasBejegyzes(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: map['date'],
      mileage: map['mileage'],
      servicePlace: map['servicePlace'],
      description: map['description'],
      laborCost: map['laborCost'],
      partsCost: map['partsCost'],
      totalCost: map['totalCost'],
      notes: map['notes'],
    );
  }
}