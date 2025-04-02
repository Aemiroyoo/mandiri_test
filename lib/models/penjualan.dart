class Penjualan {
  final String? id; // Ubah jadi String?
  final String namaLayanan;
  final int hargaSatuan;
  final String satuan;
  final int jumlah;
  final int total;
  final String tanggal;
  final String namaPelanggan;
  final String layananId;

  Penjualan({
    this.id, // 🔁
    required this.layananId,
    required this.namaLayanan,
    required this.hargaSatuan,
    required this.satuan,
    required this.jumlah,
    required this.total,
    required this.tanggal,
    required this.namaPelanggan,
  });

  Map<String, dynamic> toMap() {
    return {
      'layanan_id': layananId,
      'nama_layanan': namaLayanan,
      'harga_satuan': hargaSatuan,
      'satuan': satuan,
      'jumlah': jumlah,
      'total': total,
      'tanggal': tanggal,
      'nama_pelanggan': namaPelanggan,
    };
  }

  // kalau kamu masih pakai .fromMap dan toMap, sesuaikan juga:
  factory Penjualan.fromMap(Map<String, dynamic> map) {
    return Penjualan(
      id: map['id'], // ini string kalau dari Firestore
      layananId: map['layanan_id'],
      namaLayanan: map['nama_layanan'],
      hargaSatuan: map['harga_satuan'],
      satuan: map['satuan'],
      jumlah: map['jumlah'],
      total: map['total'],
      tanggal: map['tanggal'],
      namaPelanggan: map['nama_pelanggan'],
    );
  }
}
