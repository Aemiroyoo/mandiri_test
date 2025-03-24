import 'package:flutter/material.dart';
import 'package:mandiri_test/models/layanan_laundry.dart';
import 'package:mandiri_test/screen/input_penjualan_screen.dart';
import '../db/db_helper.dart';
import '../models/penjualan.dart';

class RiwayatPenjualanScreen extends StatefulWidget {
  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  List<Penjualan> dataPenjualan = [];
  List<LayananLaundry> semuaLayanan = [];
  List<String> listKategori = [];

  @override
  void initState() {
    super.initState();
    fetchPenjualan();
    loadLayanan(); // tambahkan ini
  }

  Future<void> loadLayanan() async {
    semuaLayanan = await DBHelper.getAllLayanan();
    listKategori = semuaLayanan.map((e) => e.kategori).toSet().toList();
    setState(() {});
  }

  Future<void> fetchPenjualan() async {
    dataPenjualan = await DBHelper.getAllPenjualan();
    setState(() {});
  }

  void showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Hapus Transaksi"),
            content: Text("Yakin ingin menghapus transaksi ini?"),
            actions: [
              TextButton(
                child: Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text("Hapus"),
                onPressed: () async {
                  await DBHelper.deletePenjualanById(id);
                  Navigator.pop(context);
                  fetchPenjualan(); // refresh
                },
              ),
            ],
          ),
    );
  }

  void showEditDialog(Penjualan data) {
    final namaController = TextEditingController(text: data.namaPelanggan);
    final jumlahController = TextEditingController(
      text: data.jumlah.toString(),
    );

    // Simpan kategori dan layanan terpilih dalam variabel state dialog
    String? kategoriTerpilih;
    LayananLaundry? layananTerpilih;
    List<LayananLaundry> layananFiltered = [];

    // Ambil semua data layanan dan kategori terlebih dahulu
    DBHelper.getAllLayanan().then((layananList) {
      // Ambil kategori dari semua layanan
      List<String> listKategori =
          layananList.map((e) => e.kategori).toSet().toList();

      // Cari layanan yang sesuai dengan data penjualan
      LayananLaundry? currentLayanan;
      try {
        currentLayanan = layananList.firstWhere(
          (item) => item.id == data.layananId,
        );
        kategoriTerpilih = currentLayanan.kategori;
        layananTerpilih = currentLayanan;
        // Filter layanan berdasarkan kategori yang dipilih
        layananFiltered =
            layananList.where((e) => e.kategori == kategoriTerpilih).toList();
      } catch (e) {
        print("Layanan dengan ID ${data.layananId} tidak ditemukan: $e");
      }

      // Gunakan StatefulBuilder untuk dialog agar setState bekerja dengan baik
      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder:
                  (context, setDialogState) => AlertDialog(
                    title: Text("Edit Transaksi"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: namaController,
                          decoration: InputDecoration(
                            labelText: "Nama Pelanggan",
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Jumlah (${data.satuan})",
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: kategoriTerpilih,
                          hint: Text("Pilih Kategori"),
                          onChanged: (val) {
                            setDialogState(() {
                              kategoriTerpilih = val;
                              // Filter layanan berdasarkan kategori yang dipilih
                              layananFiltered =
                                  layananList
                                      .where(
                                        (e) => e.kategori == kategoriTerpilih,
                                      )
                                      .toList();
                              // Reset layanan terpilih saat kategori berubah
                              layananTerpilih =
                                  layananFiltered.isNotEmpty
                                      ? layananFiltered[0]
                                      : null;
                            });
                          },
                          items:
                              listKategori.map((kategori) {
                                return DropdownMenuItem(
                                  value: kategori,
                                  child: Text(kategori),
                                );
                              }).toList(),
                          decoration: InputDecoration(labelText: "Kategori"),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<LayananLaundry>(
                          value: layananTerpilih,
                          onChanged: (LayananLaundry? value) {
                            setState(() {
                              layananTerpilih = value;
                            });
                          },
                          items:
                              layananFiltered.map((e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Container(
                                    width:
                                        230, // atur lebar tetap agar wrap aktif (boleh sesuaikan)
                                    child: Text(
                                      "${e.namaLayanan} - Rp ${e.harga}/${e.satuan}",
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // potong rapi dengan titik-titik
                                      softWrap: false,
                                    ),
                                  ),
                                );
                              }).toList(),
                          decoration: InputDecoration(labelText: "Layanan"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text("Batal"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        child: Text("Simpan"),
                        onPressed: () async {
                          if (layananTerpilih == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Pilih layanan terlebih dahulu"),
                              ),
                            );
                            return;
                          }

                          final updated = Penjualan(
                            id: data.id,
                            layananId: layananTerpilih!.id!,
                            namaLayanan: layananTerpilih!.namaLayanan,
                            hargaSatuan: layananTerpilih!.harga,
                            satuan: layananTerpilih!.satuan,
                            jumlah:
                                int.tryParse(jumlahController.text) ??
                                data.jumlah,
                            total:
                                (int.tryParse(jumlahController.text) ??
                                    data.jumlah) *
                                layananTerpilih!.harga,
                            tanggal: data.tanggal,
                            namaPelanggan: namaController.text,
                          );

                          await DBHelper.updatePenjualan(updated);
                          Navigator.pop(context);
                          fetchPenjualan();
                        },
                      ),
                    ],
                  ),
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Penjualan"),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InputPenjualanScreen()),
              );
            },
          ),
        ],
      ),

      body:
          dataPenjualan.isEmpty
              ? Center(child: Text("Belum ada data penjualan."))
              : ListView.builder(
                itemCount: dataPenjualan.length,
                itemBuilder: (context, index) {
                  final item = dataPenjualan[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bagian kiri (nama, layanan, tanggal)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaPelanggan,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "${item.namaLayanan} - ${item.jumlah} ${item.satuan}",
                                ),
                                Text("Tanggal: ${item.tanggal}"),
                              ],
                            ),
                          ),

                          // Bagian kanan (total + edit/hapus)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rp. ${item.total},- ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () => showEditDialog(item),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed:
                                        () => showDeleteConfirmation(item.id!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
