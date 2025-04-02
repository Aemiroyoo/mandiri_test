import 'package:mandiri_test/models/penjualan.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/layanan_laundry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DBHelper {
  static Database? _database;
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

  // ==== FIREBASE UNTUK LAYANAN LAUNDRY ====
  Future<void> insertLayanan(LayananLaundry layanan) async {
    await FirebaseFirestore.instance.collection('layanan_laundry').add({
      'namaLayanan': layanan.namaLayanan,
      'kategori': layanan.kategori,
      'harga': layanan.harga,
      'satuan': layanan.satuan,
    });
  }

  Future<List<LayananLaundry>> getAllLayanan() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('layanan_laundry').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LayananLaundry(
        id: doc.id,
        namaLayanan: data['namaLayanan'],
        kategori: data['kategori'],
        harga: data['harga'],
        satuan: data['satuan'],
      );
    }).toList();
  }

  Future<void> updateLayanan(LayananLaundry layanan) async {
    await FirebaseFirestore.instance
        .collection('layanan_laundry')
        .doc(layanan.id)
        .update({
          'namaLayanan': layanan.namaLayanan,
          'kategori': layanan.kategori,
          'harga': layanan.harga,
          'satuan': layanan.satuan,
        });
  }

  Future<void> deleteLayanan(String id) async {
    await FirebaseFirestore.instance
        .collection('layanan_laundry')
        .doc(id)
        .delete();
  }

  // ==== SQLITE UNTUK PENJUALAN ====
  static Future<int> insertPenjualan(Penjualan penjualan) async {
    final db = await initDb();
    return await db.insert('penjualan', penjualan.toMap());
  }

  static Future<List<Penjualan>> getAllPenjualan() async {
    final db = await initDb();
    final data = await db.query('penjualan', orderBy: 'tanggal DESC');
    return data.map((e) => Penjualan.fromMap(e)).toList();
  }

  static Future<int> clearPenjualan() async {
    final db = await initDb();
    return await db.delete('penjualan');
  }

  static Future<void> deletePenjualanOlderThan(int days) async {
    final db = await initDb();
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    await db.delete('penjualan', where: 'tanggal < ?', whereArgs: [cutoffDate]);
  }

  static Future<int> updatePenjualan(Penjualan data) async {
    final db = await initDb();
    return await db.update(
      'penjualan',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // static Future<int> deletePenjualanById(int id) async {
  //   final db = await initDb();
  //   return await db.delete('penjualan', where: 'id = ?', whereArgs: [id]);
  // }

  /// tambah penjualan ke Firestore
  static Future<void> tambahPenjualan(Penjualan data) async {
    await FirebaseFirestore.instance.collection('penjualan').add({
      'layanan_id': data.layananId,
      'nama_layanan': data.namaLayanan,
      'harga_satuan': data.hargaSatuan,
      'satuan': data.satuan,
      'jumlah': data.jumlah,
      'total': data.total,
      'tanggal': data.tanggal,
      'nama_pelanggan': data.namaPelanggan,
    });
  }

  static Future<void> deletePenjualanById(String id) async {
    await FirebaseFirestore.instance.collection('penjualan').doc(id).delete();
  }
}
