import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/models/penjualan.dart';
import 'package:mandiri_test/screen/riwayat_penjualan_screen.dart';
import 'package:mandiri_test/services/firestore_service.dart';
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
  final formatCurrency = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    loadDataLayanan();
    jumlahController.addListener(hitungTotal);
  }

  Future<void> loadDataLayanan() async {
    semuaLayanan = await DBHelper().getAllLayanan();
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
    if (namaPelangganController.text.isEmpty ||
        layananTerpilih == null ||
        jumlahController.text.isEmpty ||
        int.tryParse(jumlahController.text) == null ||
        int.tryParse(jumlahController.text)! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Isi jumlah minimal 1 dan pastikan semua data terisi."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String _capitalizeEachWord(String text) {
      return text
          .toLowerCase()
          .split(' ')
          .map(
            (word) =>
                word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '',
          )
          .join(' ');
    }

    final penjualan = Penjualan(
      layananId: layananTerpilih!.id!,
      namaLayanan: layananTerpilih!.namaLayanan,
      hargaSatuan: layananTerpilih!.harga,
      satuan: layananTerpilih!.satuan,
      jumlah: int.parse(jumlahController.text),
      total: totalHarga,
      tanggal: DateTime.now().toIso8601String().substring(0, 10),
      namaPelanggan: _capitalizeEachWord(namaPelangganController.text),
    );

    // await DBHelper.insertPenjualan(penjualan);
    await FirestoreService.tambahPenjualan(penjualan);

    namaPelangganController.clear();
    jumlahController.clear();
    layananTerpilih = null;
    kategoriTerpilih = null;
    totalHarga = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Data penjualan berhasil disimpan"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RiwayatPenjualanScreen()),
    );
  }

  @override
  void dispose() {
    namaPelangganController.dispose();
    jumlahController.dispose();
    super.dispose();
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
            TextField(
              controller: namaPelangganController,
              decoration: InputDecoration(labelText: "Nama Pelanggan"),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value:
                  listKategori.contains(kategoriTerpilih)
                      ? kategoriTerpilih
                      : null,
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
                  layananFiltered =
                      semuaLayanan
                          .where((e) => e.kategori == kategoriTerpilih)
                          .toList();
                  layananTerpilih = null;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<LayananLaundry>(
              value: layananTerpilih,
              hint: Text("Pilih Layanan"),
              items:
                  layananFiltered.map((layanan) {
                    return DropdownMenuItem(
                      value: layanan,
                      child: Text(
                        "${layanan.namaLayanan} - Rp ${formatCurrency.format(layanan.harga)}/${layanan.satuan}",
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
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah (${layananTerpilih?.satuan ?? '-'})",
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Total Harga: Rp ${formatCurrency.format(totalHarga)},-",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
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
