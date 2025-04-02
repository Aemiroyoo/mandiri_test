import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mandiri_test/models/penjualan.dart';
import '../models/layanan_laundry.dart';

class FirestoreService {
  static final _collection = FirebaseFirestore.instance.collection(
    'layanan_laundry',
  );

  /// Ambil semua data layanan
  static Future<List<LayananLaundry>> getAllLayanan() async {
    final snapshot = await _collection.get();

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

  /// Tambah data baru
  static Future<void> tambahLayanan(LayananLaundry layanan) async {
    await _collection.add({
      'namaLayanan': layanan.namaLayanan,
      'kategori': layanan.kategori,
      'harga': layanan.harga,
      'satuan': layanan.satuan,
    });
  }

  /// Update data layanan
  static Future<void> updateLayanan(LayananLaundry layanan) async {
    await _collection.doc(layanan.id).update({
      'namaLayanan': layanan.namaLayanan,
      'kategori': layanan.kategori,
      'harga': layanan.harga,
      'satuan': layanan.satuan,
    });
  }

  /// Hapus data layanan
  static Future<void> deleteLayanan(String id) async {
    await _collection.doc(id).delete();
  }

  static Future<void> tambahPenjualan(Penjualan penjualan) async {
    await FirebaseFirestore.instance.collection('penjualan').add({
      'layananId': penjualan.layananId,
      'namaLayanan': penjualan.namaLayanan,
      'hargaSatuan': penjualan.hargaSatuan,
      'satuan': penjualan.satuan,
      'jumlah': penjualan.jumlah,
      'total': penjualan.total,
      'tanggal': penjualan.tanggal,
      'namaPelanggan': penjualan.namaPelanggan,
    });
  }
}
