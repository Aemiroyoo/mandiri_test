import 'package:mandiri_test/models/penjualan.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/layanan_laundry.dart';

class DBHelper {
  static Database? _database;

  // Nama tabel & field
  static const _tableName = 'layanan_laundry';

  static Future<Database> initDb() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'laundry.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
    CREATE TABLE $_tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama_layanan TEXT,
      kategori TEXT,
      harga INTEGER,
      satuan TEXT
    )
  ''');

        await db.execute('''
  CREATE TABLE penjualan (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    layanan_id INTEGER,
    nama_layanan TEXT,
    harga_satuan INTEGER,
    satuan TEXT,
    jumlah INTEGER,
    total INTEGER,
    tanggal TEXT,
    nama_pelanggan TEXT
  )
''');
      },
    );

    return _database!;
  }

  // Insert data
  static Future<int> insertLayanan(LayananLaundry layanan) async {
    final db = await initDb();
    return await db.insert(_tableName, layanan.toMap());
  }

  // Get all data
  static Future<List<LayananLaundry>> getAllLayanan() async {
    final db = await initDb();
    final data = await db.query(_tableName);
    print("ISI DATABASE:");
    print(data); // menampilkan list of map
    return data.map((e) => LayananLaundry.fromMap(e)).toList();
  }

  // Update data
  static Future<int> updateLayanan(LayananLaundry layanan) async {
    final db = await initDb();
    return await db.update(
      _tableName,
      layanan.toMap(),
      where: 'id = ?',
      whereArgs: [layanan.id],
    );
  }

  // Delete data
  static Future<int> deleteLayanan(int id) async {
    final db = await initDb();
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Insert penjualan
  static Future<int> insertPenjualan(Penjualan penjualan) async {
    final db = await initDb();
    return await db.insert('penjualan', penjualan.toMap());
  }

  // Get semua penjualan
  static Future<List<Penjualan>> getAllPenjualan() async {
    final db = await initDb();
    final data = await db.query('penjualan', orderBy: 'tanggal DESC');
    return data.map((e) => Penjualan.fromMap(e)).toList();
  }

  // Delete semua penjualan (opsional untuk clear)
  static Future<int> clearPenjualan() async {
    final db = await initDb();
    return await db.delete('penjualan');
  }

  // Delete penjualan lebih dari X hari (opsional)
  static Future<void> deletePenjualanOlderThan(int days) async {
    final db = await initDb();
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    await db.delete('penjualan', where: 'tanggal < ?', whereArgs: [cutoffDate]);
  }
}
