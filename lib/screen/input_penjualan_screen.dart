import 'package:flutter/material.dart';
import 'package:mandiri_test/models/penjualan.dart';
import '../db/db_helper.dart';
import '../models/layanan_laundry.dart';

class InputPenjualanScreen extends StatefulWidget {
  @override
  State<InputPenjualanScreen> createState() => _InputPenjualanScreenState();
}

class _InputPenjualanScreenState extends State<InputPenjualanScreen> {
  LayananLaundry? layananTerpilih;
  List<LayananLaundry> semuaLayanan = [];

  String? kategoriTerpilih;
  List<String> listKategori = [];
  List<LayananLaundry> layananFiltered = [];
  final TextEditingController namaPelangganController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  int totalHarga = 0;

  @override
  void initState() {
    super.initState();
    loadDataLayanan();
  }

  Future<void> loadDataLayanan() async {
    semuaLayanan = await DBHelper.getAllLayanan();

    // Ambil kategori unik
    listKategori = semuaLayanan.map((e) => e.kategori).toSet().toList();

    setState(() {});
  }

  void hitungTotal() {
    if (layananTerpilih != null && jumlahController.text.isNotEmpty) {
      final jumlah = int.tryParse(jumlahController.text) ?? 0;
      setState(() {
        totalHarga = jumlah * layananTerpilih!.harga;
      });
    }
  }

  Future<void> simpanPenjualan() async {
    final currentContext = context;

    if (namaPelangganController.text.isEmpty ||
        layananTerpilih == null ||
        jumlahController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lengkapi semua data terlebih dahulu")),
      );
      return;
    }

    final penjualan = Penjualan(
      layananId: layananTerpilih!.id!,
      namaLayanan: layananTerpilih!.namaLayanan,
      hargaSatuan: layananTerpilih!.harga,
      satuan: layananTerpilih!.satuan,
      jumlah: int.parse(jumlahController.text),
      total: totalHarga,
      tanggal: DateTime.now().toIso8601String().substring(0, 10),
      namaPelanggan: namaPelangganController.text, // 🆕
    );

    await DBHelper.insertPenjualan(penjualan);

    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text("Data penjualan berhasil disimpan"),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form
    setState(() {
      jumlahController.clear();
      layananTerpilih = null;
      totalHarga = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input Penjualan"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Nama Pelanggan
            TextField(
              controller: namaPelangganController,
              decoration: InputDecoration(labelText: "Nama Pelanggan"),
            ),
            SizedBox(height: 16),

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              value: kategoriTerpilih,
              hint: Text("Pilih Kategori"),
              items:
                  listKategori.map((kategori) {
                    return DropdownMenuItem(
                      value: kategori,
                      child: Text(kategori),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  kategoriTerpilih = value;
                  // filter layanan berdasarkan kategori
                  layananFiltered =
                      semuaLayanan
                          .where((e) => e.kategori == kategoriTerpilih)
                          .toList();
                  layananTerpilih = null; // reset pilihan layanan
                });
              },
            ),
            SizedBox(height: 16),

            // Dropdown Layanan (Filtered)
            DropdownButtonFormField<LayananLaundry>(
              value: layananTerpilih,
              hint: Text("Pilih Layanan"),
              items:
                  layananFiltered.map((layanan) {
                    return DropdownMenuItem(
                      value: layanan,
                      child: Text(
                        "${layanan.namaLayanan} - Rp ${layanan.harga}/${layanan.satuan}",
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  layananTerpilih = value;
                });
                hitungTotal();
              },
            ),
            SizedBox(height: 16),

            // Input Jumlah
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah (${layananTerpilih?.satuan ?? '-'})",
              ),
              onChanged: (value) => hitungTotal(),
            ),
            SizedBox(height: 16),

            // Total Harga
            Text(
              "Total Harga: Rp $totalHarga,-",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Spacer(),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: simpanPenjualan,
                child: Text("Simpan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
