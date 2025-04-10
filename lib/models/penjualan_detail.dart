class PenjualanDetail {
  final String? id;
  final String penjualanId;
  final String layananId;
  final String namaLayanan;
  final int hargaSatuan;
  final String satuan;
  final int jumlah;
  final int total;

  PenjualanDetail({
    this.id,
    required this.penjualanId,
    required this.layananId,
    required this.namaLayanan,
    required this.hargaSatuan,
    required this.satuan,
    required this.jumlah,
    required this.total,
  });

  PenjualanDetail copyWith({
    String? id,
    String? penjualanId, // ✅ tambahkan ini
    String? layananId,
    String? namaLayanan,
    int? hargaSatuan,
    String? satuan,
    int? jumlah,
    int? total,
  }) {
    return PenjualanDetail(
      id: id ?? this.id,
      penjualanId: penjualanId ?? this.penjualanId, // ✅ tambahkan ini
      layananId: layananId ?? this.layananId,
      namaLayanan: namaLayanan ?? this.namaLayanan,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      satuan: satuan ?? this.satuan,
      jumlah: jumlah ?? this.jumlah,
      total: total ?? this.total, // ✅ pastikan juga total dibawa
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'penjualan_id': penjualanId,
      'layanan_id': layananId,
      'nama_layanan': namaLayanan,
      'harga_satuan': hargaSatuan,
      'satuan': satuan,
      'jumlah': jumlah,
      'total': total,
    };
  }

  factory PenjualanDetail.fromMap(String id, Map<String, dynamic> map) {
    return PenjualanDetail(
      id: id,
      penjualanId: map['penjualan_id'],
      layananId: map['layanan_id'],
      namaLayanan: map['nama_layanan'],
      hargaSatuan: map['harga_satuan'],
      satuan: map['satuan'],
      jumlah: map['jumlah'],
      total: map['total'],
    );
  }
}
