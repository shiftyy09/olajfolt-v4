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
      version: 3, // A verziószám maradhat, ha nem változott a struktúra
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAllTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Ez akkor fut le, ha növeled a verziószámot.
    // A jelenlegi struktúrával ez már nem szükséges, de biztonságból itt hagyható.
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS services (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicleId INTEGER NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          cost INTEGER NOT NULL,
          mileage INTEGER NOT NULL,
          FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _createAllTables(Database db) async {
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
    // A régi 'maintenance' és 'service_intervals' táblákra már nincs szükség,
    // de ha nem törlöd őket, az sem okoz problémát.
    // Az egyszerűség kedvéért az új telepítéseknél már nem is hozzuk létre őket.
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        cost INTEGER NOT NULL,
        mileage INTEGER NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- LEKÉRDEZŐ FÜGGVÉNYEK ---

  Future<List<Map<String, dynamic>>> getVehicles() async {
    Database db = await instance.database;
    return await db.query('vehicles', orderBy: 'make, model');
  }

  Future<List<Map<String, dynamic>>> getServicesForVehicle(
      int vehicleId) async {
    final db = await instance.database;
    return await db.query(
      'services',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC, mileage DESC', // Először dátum, aztán km szerint
    );
  }

  // --- MÓDOSÍTÓ FÜGGVÉNYEK ---

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

  // === EZ AZ ÚJ FÜGGVÉNY, AMIT KÉRTÉL ===
  // Törli az összes 'services' bejegyzést, ami egy adott járműhöz tartozik.
  // Ez kell ahhoz, hogy a jármű szerkesztésekor felül tudjuk írni az automatikus bejegyzéseket.
  Future<void> deleteServicesForVehicle(int vehicleId) async {
    final db = await instance.database;
    await db.delete('services', where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }
}