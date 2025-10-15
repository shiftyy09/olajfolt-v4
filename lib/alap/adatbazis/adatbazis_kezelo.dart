import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AdatbazisKezelo {
  static final AdatbazisKezelo instance = AdatbazisKezelo._init();
  static Database? _database;

  AdatbazisKezelo._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Verziószám növelése 5-re, hogy az onUpgrade biztosan lefusson
    return await openDatabase(path,
        version: 5, onCreate: _createAllTables, onUpgrade: _onUpgrade);
  }

  // Létrehozza az összes táblát a helyes sémával
  Future<void> _createAllTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        licensePlate TEXT NOT NULL UNIQUE,
        vin TEXT,
        mileage INTEGER NOT NULL,
        vezerlesTipusa TEXT NOT NULL,
        imagePath TEXT  -- Itt van a hiányzó oszlop, TEXT típussal
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        cost REAL NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  // Egyszerűsített onUpgrade: Eldobja a régi táblákat és újra létrehozza őket
  // Ez biztosítja, hogy tiszta telepítéskor is a legfrissebb séma jöjjön létre.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS services');
    await db.execute('DROP TABLE IF EXISTS vehicles');
    await _createAllTables(db, newVersion);
  }

  // === CRUD Műveletek ===

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // === Specifikus lekérdezések ===

  Future<List<Map<String, dynamic>>> getVehicles() async {
    final db = await instance.database;
    return await db.query('vehicles', orderBy: 'make, model');
  }

  Future<List<Map<String, dynamic>>> getServicesForVehicle(
      int vehicleId) async {
    final db = await instance.database;
    return await db.query('services',
        where: 'vehicleId = ?',
        whereArgs: [vehicleId],
        orderBy: 'date DESC, mileage DESC');
  }

  Future<int> deleteServicesForVehicle(int vehicleId) async {
    final db = await instance.database;
    return await db
        .delete('services', where: 'vehicleId = ?', whereArgs: [vehicleId]);
  }
}