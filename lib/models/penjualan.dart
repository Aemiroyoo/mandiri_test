// class Penjualan {
//   final String? id;
//   final String namaLayanan;
//   final int hargaSatuan;
//   final String satuan;
//   final int jumlah;
//   final int total;
//   final String tanggal;
//   final String namaPelanggan;
//   final String layananId;

//   Penjualan({
//     this.id,
//     required this.layananId,
//     required this.namaLayanan,
//     required this.hargaSatuan,
//     required this.satuan,
//     required this.jumlah,
//     required this.total,
//     required this.tanggal,
//     required this.namaPelanggan,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'layanan_id': layananId,
//       'nama_layanan': namaLayanan,
//       'harga_satuan': hargaSatuan,
//       'satuan': satuan,
//       'jumlah': jumlah,
//       'total': total,
//       'tanggal': tanggal,
//       'nama_pelanggan': namaPelanggan,
//     };
//   }

//   factory Penjualan.fromMap(Map<String, dynamic> map) {
//     return Penjualan(
//       id: map['id'],
//       layananId: map['layanan_id'],
//       namaLayanan: map['nama_layanan'],
//       hargaSatuan: map['harga_satuan'],
//       satuan: map['satuan'],
//       jumlah: map['jumlah'],
//       total: map['total'],
//       tanggal: map['tanggal'],
//       namaPelanggan: map['nama_pelanggan'],
//     );
//   }
// }

import 'package:mandiri_test/models/penjualan_detail.dart';

class Penjualan {
  final String? id;
  final String namaPelanggan;
  final String tanggal;
  final int total;
  final List<PenjualanDetail> detail;

  Penjualan({
    this.id,
    required this.namaPelanggan,
    required this.tanggal,
    required this.total,
    this.detail = const [], // Default kosong agar aman saat parsing
  });

  Map<String, dynamic> toMap() {
    return {
      'nama_pelanggan': namaPelanggan,
      'tanggal': tanggal,
      'total': total,
    };
  }

  factory Penjualan.fromMap(String id, Map<String, dynamic> map) {
    return Penjualan(
      id: id,
      namaPelanggan: map['nama_pelanggan'],
      tanggal: map['tanggal'],
      total: map['total'],
      detail: [], // akan diisi manual setelah ambil dari subkoleksi Firestore
    );
  }
}
