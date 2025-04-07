import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/services/firestore_service.dart';
import '../db/db_helper.dart';
import '../models/layanan_laundry.dart';
import '../models/penjualan.dart';
import 'input_penjualan_screen.dart';

class RiwayatPenjualanScreen extends StatefulWidget {
  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  final _formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  List<Penjualan> dataPenjualan = [];
  List<LayananLaundry> semuaLayanan = [];
  List<String> listKategori = [];
  DocumentSnapshot? lastDocument;
  bool hasMore = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPenjualan();
    loadLayanan();
  }

  Future<void> loadLayanan() async {
    semuaLayanan = await DBHelper().getAllLayanan();
    listKategori = semuaLayanan.map((e) => e.kategori).toSet().toList();
    setState(() {});
  }

  Future<void> fetchPenjualan() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final query = FirebaseFirestore.instance
        .collection('penjualan')
        .orderBy('tanggal', descending: true)
        .limit(10);

    final snapshot =
        lastDocument != null
            ? await query.startAfterDocument(lastDocument!).get()
            : await query.get();

    final docs = snapshot.docs;

    if (docs.isNotEmpty) {
      lastDocument = docs.last;
      final items =
          docs.map((doc) {
            final data = doc.data();
            return Penjualan(
              id: doc.id,
              layananId: data['layananId'],
              namaLayanan: data['namaLayanan'],
              hargaSatuan: data['hargaSatuan'],
              satuan: data['satuan'],
              jumlah: data['jumlah'],
              total: data['total'],
              tanggal: data['tanggal'],
              namaPelanggan: data['namaPelanggan'],
            );
          }).toList();

      setState(() {
        dataPenjualan.addAll(items);
        if (items.length < 10) hasMore = false;
      });
    } else {
      setState(() => hasMore = false);
    }

    setState(() => isLoading = false);
  }

  void showDeleteConfirmation(String id) {
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
                  Navigator.pop(context);
                  await DBHelper.deletePenjualanById(id);
                  // await FirestoreService.deletePenjualan(id);

                  fetchPenjualan();
                },
              ),
            ],
          ),
    );
  }

  void showEditDialog(Penjualan data) async {
    final namaController = TextEditingController(text: data.namaPelanggan);
    final jumlahController = TextEditingController(
      text: data.jumlah.toString(),
    );

    String? kategoriTerpilih;
    LayananLaundry? layananTerpilih;
    List<LayananLaundry> layananFiltered = [];

    final dbHelper = DBHelper();
    final semuaLayanan = await dbHelper.getAllLayanan();

    final listKategori = semuaLayanan.map((e) => e.kategori).toSet().toList();

    try {
      final currentLayanan = semuaLayanan.firstWhere(
        (e) => e.id == data.layananId,
      );
      kategoriTerpilih = currentLayanan.kategori;
      layananTerpilih = currentLayanan;
      layananFiltered =
          semuaLayanan.where((e) => e.kategori == kategoriTerpilih).toList();
    } catch (e) {
      print("Layanan tidak ditemukan: $e");
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text("Edit Transaksi"),
                content: SingleChildScrollView(
                  child: Column(
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
                          labelText:
                              "Jumlah (${layananTerpilih?.satuan ?? '-'})",
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: kategoriTerpilih,
                        decoration: InputDecoration(labelText: "Kategori"),
                        items:
                            listKategori.map((kategori) {
                              return DropdownMenuItem(
                                value: kategori,
                                child: Text(kategori),
                              );
                            }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            kategoriTerpilih = val;
                            layananFiltered =
                                semuaLayanan
                                    .where((e) => e.kategori == val)
                                    .toList();
                            layananTerpilih =
                                layananFiltered.isNotEmpty
                                    ? layananFiltered[0]
                                    : null;
                          });
                        },
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<LayananLaundry>(
                        value: layananTerpilih,
                        decoration: InputDecoration(labelText: "Layanan"),
                        items:
                            layananFiltered.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Container(
                                  width:
                                      220, // ⬅️ atur lebar sesuai kebutuhan layout kamu
                                  child: Text(
                                    "${e.namaLayanan} - Rp ${e.harga}/${e.satuan}",
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // ⬅️ potong jadi ...
                                    softWrap: false,
                                    maxLines: 1, // ⬅️ biar lebih aman
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (val) =>
                                setDialogState(() => layananTerpilih = val),
                      ),
                    ],
                  ),
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

                      final updatedData = {
                        'layananId': layananTerpilih!.id,
                        'namaLayanan': layananTerpilih!.namaLayanan,
                        'hargaSatuan': layananTerpilih!.harga,
                        'satuan': layananTerpilih!.satuan,
                        'jumlah':
                            int.tryParse(jumlahController.text) ?? data.jumlah,
                        'total':
                            (int.tryParse(jumlahController.text) ??
                                data.jumlah) *
                            layananTerpilih!.harga,
                        'namaPelanggan': namaController.text,
                        'tanggal': data.tanggal, // tetap gunakan tanggal lama
                      };

                      await FirebaseFirestore.instance
                          .collection('penjualan')
                          .doc(data.id) // ← ID dokumen
                          .update(updatedData);

                      Navigator.pop(context);
                      fetchPenjualan();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Data berhasil diperbarui"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
    );
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
                MaterialPageRoute(builder: (_) => InputPenjualanScreen()),
              );
            },
          ),
        ],
      ),
      body:
          dataPenjualan.isEmpty && !isLoading
              ? Center(child: Text("Belum ada data penjualan."))
              : ListView.builder(
                itemCount: dataPenjualan.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < dataPenjualan.length) {
                    final item = dataPenjualan[index];
                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCurrency.format(item.total),
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
                                          () =>
                                              showDeleteConfirmation(item.id!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Tombol Muat Lebih Banyak
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: fetchPenjualan,
                          child: Text("Muat Lebih Banyak"),
                        ),
                      ),
                    );
                  }
                },
              ),
    );
  }
}
