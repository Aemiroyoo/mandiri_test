class Penjualan {
  int? id;
  int layananId;
  String namaLayanan;
  int hargaSatuan;
  String satuan;
  int jumlah;
  int total;
  String tanggal;
  String namaPelanggan; // 🆕 Tambahan

  Penjualan({
    this.id,
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
      'id': id,
      'layanan_id': layananId,
      'nama_layanan': namaLayanan,
      'harga_satuan': hargaSatuan,
      'satuan': satuan,
      'jumlah': jumlah,
      'total': total,
      'tanggal': tanggal,
      'nama_pelanggan': namaPelanggan, // 🆕 Tambahan
    };
  }

  factory Penjualan.fromMap(Map<String, dynamic> map) {
    return Penjualan(
      id: map['id'],
      layananId: map['layanan_id'],
      namaLayanan: map['nama_layanan'],
      hargaSatuan: map['harga_satuan'],
      satuan: map['satuan'],
      jumlah: map['jumlah'],
      total: map['total'],
      tanggal: map['tanggal'],
      namaPelanggan: map['nama_pelanggan'], // 🆕 Tambahan
    );
  }
}
