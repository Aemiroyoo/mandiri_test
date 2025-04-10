import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mandiri_test/models/layanan_laundry.dart';
import 'package:mandiri_test/models/penjualan_detail.dart';
import '../db/db_helper.dart';

class InputPenjualanScreen extends StatefulWidget {
  @override
  State<InputPenjualanScreen> createState() => _InputPenjualanScreenState();
}

class _InputPenjualanScreenState extends State<InputPenjualanScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  List<LayananLaundry> semuaLayanan = [];
  List<String> kategoriList = [];
  String? kategoriTerpilih;
  LayananLaundry? layananTerpilih;
  List<LayananLaundry> filteredLayanan = [];

  List<PenjualanDetail> daftarLayanan = [];
  int totalHarga = 0;

  @override
  void initState() {
    super.initState();
    loadLayanan();
  }

  Future<void> loadLayanan() async {
    final dbHelper = DBHelper(); // Buat instance
    semuaLayanan = await dbHelper.getAllLayanan(); // ✅ panggil dari instance
    setState(() {
      kategoriList = semuaLayanan.map((e) => e.kategori).toSet().toList();
    });
  }

  void tambahKeDaftar() {
    if (layananTerpilih != null && jumlahController.text.isNotEmpty) {
      final jumlah = int.tryParse(jumlahController.text) ?? 0;
      if (jumlah == 0) return;

      final total = jumlah * layananTerpilih!.harga;

      final detail = PenjualanDetail(
        penjualanId: '', // kosong dulu, diisi saat simpan
        layananId: layananTerpilih!.id!,
        namaLayanan: layananTerpilih!.namaLayanan,
        hargaSatuan: layananTerpilih!.harga,
        satuan: layananTerpilih!.satuan,
        jumlah: jumlah,
        total: total,
      );

      setState(() {
        daftarLayanan.add(detail);
        totalHarga += total;
        jumlahController.clear();
        layananTerpilih = null;
      });
    }
  }

  void hapusLayanan(int index) {
    setState(() {
      totalHarga -= daftarLayanan[index].total;
      daftarLayanan.removeAt(index);
    });
  }

  Future<void> simpanTransaksi() async {
    if (daftarLayanan.isEmpty || namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon isi nama & tambahkan layanan')),
      );
      return;
    }

    final docRef = await FirebaseFirestore.instance
        .collection('penjualan')
        .add({
          'nama_pelanggan': namaController.text.trim(),
          'tanggal': DateTime.now().toIso8601String().substring(0, 10),
          'total': totalHarga,
        });

    for (var detail in daftarLayanan) {
      final dataDetail = detail.copyWith(penjualanId: docRef.id);
      await FirebaseFirestore.instance
          .collection('penjualan')
          .doc(docRef.id)
          .collection('detail')
          .add(dataDetail.toMap());
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: "Nama Pelanggan"),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: kategoriTerpilih,
              hint: Text("Pilih Kategori"),
              items:
                  kategoriList
                      .map(
                        (kat) => DropdownMenuItem(value: kat, child: Text(kat)),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  kategoriTerpilih = value;
                  filteredLayanan =
                      semuaLayanan.where((e) => e.kategori == value).toList();
                  layananTerpilih = null;
                });
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<LayananLaundry>(
              value: layananTerpilih,
              hint: Text("Pilih Layanan"),
              items:
                  filteredLayanan
                      .map(
                        (layanan) => DropdownMenuItem(
                          value: layanan,
                          child: Text(
                            "${layanan.namaLayanan} - Rp ${layanan.harga}/${layanan.satuan}",
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => layananTerpilih = val),
            ),
            SizedBox(height: 12),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Jumlah"),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: tambahKeDaftar,
              child: Text("Tambah ke Daftar"),
            ),
            Divider(height: 32),
            Text(
              "Daftar Layanan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...daftarLayanan.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(item.namaLayanan),
                subtitle: Text(
                  "${item.jumlah} ${item.satuan} x Rp${item.hargaSatuan}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Rp ${item.total}"),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => hapusLayanan(i),
                    ),
                  ],
                ),
              );
            }),
            Divider(height: 32),
            Text(
              "Total: Rp $totalHarga",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: simpanTransaksi,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
              ),
              child: Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }
}
