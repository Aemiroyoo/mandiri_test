class LayananLaundry {
  int? id;
  String namaLayanan;
  String kategori;
  int harga;
  String satuan;

  LayananLaundry({
    this.id,
    required this.namaLayanan,
    required this.kategori,
    required this.harga,
    required this.satuan,
  });

  // Convert from Map (dari DB) ke Object
  factory LayananLaundry.fromMap(Map<String, dynamic> map) {
    return LayananLaundry(
      id: map['id'],
      namaLayanan: map['nama_layanan'],
      kategori: map['kategori'],
      harga: map['harga'],
      satuan: map['satuan'],
    );
  }

  // Convert dari Object ke Map (untuk ke DB)
  Map<String, dynamic> toMap() {
    return {
      'nama_layanan': namaLayanan,
      'kategori': kategori,
      'harga': harga,
      'satuan': satuan,
    };
  }
}
