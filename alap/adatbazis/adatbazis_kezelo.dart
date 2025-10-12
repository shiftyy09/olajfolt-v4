// lib/alap/adatbazis/adatbazis_kezelo.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AdatbazisKezelo {
  AdatbazisKezelo._privateConstructor();

  static final AdatbazisKezelo instance = AdatbazisKezelo._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'car_maintenance.db');
    return await openDatabase(
      path,
      version: 2, // Verziószám növelve az új tábla miatt
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Hozzáadva az upgrade logika
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        licensePlate TEXT NOT NULL UNIQUE,
        vin TEXT,
        mileage INTEGER NOT NULL,
        vezerlesTipusa TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        serviceType TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        description TEXT,
        cost REAL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
    // ÚJ TÁBLA az intervallumoknak
    await db.execute('''
      CREATE TABLE service_intervals(
          serviceType TEXT PRIMARY KEY,
          interval INTEGER NOT NULL
      )
    ''');
  }

  // ÚJ: Upgrade logika, ha a verzió változik
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE service_intervals(
            serviceType TEXT PRIMARY KEY,
            interval INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<List<Map<String, dynamic>>> getVehicles() async {
    Database db = await instance.database;
    return await db.query('vehicles', orderBy: 'make, model');
  }

  Future<List<Map<String, dynamic>>> getMaintenanceForVehicle(
      int vehicleId) async {
    Database db = await instance.database;
    return await db.query('maintenance', where: 'vehicleId = ?',
        whereArgs: [vehicleId],
        orderBy: 'date DESC');
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ---- Új, specifikus metódusok ----

  // Intervallum beszúrása vagy frissítése
  Future<void> upsertInterval(String serviceType, int interval) async {
    final db = await instance.database;
    await db.insert(
      'service_intervals',
      {'serviceType': serviceType, 'interval': interval},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Összes intervallum lekérdezése
  Future<Map<String, int>> getAllIntervals() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('service_intervals');
    return Map.fromIterable(maps,
        key: (e) => e['serviceType'], value: (e) => e['interval']);
  }

  // JAVÍTVA: EZ A METÓDUS HIÁNYZOTT
  // Törli az összes karbantartási bejegyzést egy adott járműazonosító alapján
  Future<void> deleteMaintenanceForVehicle(int vehicleId) async {
    final db = await instance.database;
    await db.delete(
      'maintenance',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
    );
  }
}