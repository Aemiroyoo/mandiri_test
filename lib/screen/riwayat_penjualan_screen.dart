import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/screen/edit_penjualan_screen.dart';
import '../models/penjualan.dart';
import '../models/penjualan_detail.dart';
import 'input_penjualan_screen.dart';

class RiwayatPenjualanScreen extends StatefulWidget {
  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  List<Penjualan> dataPenjualan = [];

  @override
  void initState() {
    super.initState();
    fetchPenjualan();
  }

  Future<void> fetchPenjualan() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('penjualan')
              .orderBy('tanggal', descending: true)
              .get();

      final List<Penjualan> list = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<PenjualanDetail> detailList = [];

        try {
          final detailSnapshot = await doc.reference.collection('detail').get();
          for (var d in detailSnapshot.docs) {
            detailList.add(PenjualanDetail.fromMap(d.id, d.data()));
          }
        } catch (e) {
          print("Gagal ambil detail untuk ${doc.id}: $e");
        }

        list.add(
          Penjualan(
            id: doc.id,
            namaPelanggan: data['nama_pelanggan'] ?? "-",
            tanggal: data['tanggal'] ?? "-",
            total: data['total'] ?? 0,
            detail: detailList,
          ),
        );
      }

      setState(() {
        dataPenjualan = list;
      });

      print("Total transaksi: ${list.length}");
      for (var p in list) {
        print("Pelanggan: ${p.namaPelanggan}, layanan: ${p.detail.length}");
      }
    } catch (e) {
      print("Gagal ambil data penjualan: $e");
    }
  }

  Future<void> _deletePenjualan(String id) async {
    final ref = FirebaseFirestore.instance.collection('penjualan').doc(id);
    final detailSnapshot = await ref.collection('detail').get();
    for (var d in detailSnapshot.docs) {
      await d.reference.delete();
    }
    await ref.delete();
    fetchPenjualan();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InputPenjualanScreen()),
              ).then((_) => fetchPenjualan());
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
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.namaPelanggan,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          ...item.detail.map((layanan) {
                            return Text(
                              "${layanan.namaLayanan} - ${layanan.jumlah} ${layanan.satuan} x ${currency.format(layanan.hargaSatuan)} = ${currency.format(layanan.total)}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14),
                            );
                          }),
                          SizedBox(height: 6),
                          Text(
                            "Tanggal: ${item.tanggal}",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Total: ${currency.format(item.total)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              EditPenjualanScreen(data: item),
                                    ),
                                  ).then((_) {
                                    fetchPenjualan(); // refresh data setelah edit
                                  });
                                },
                              ),

                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: Text("Hapus Transaksi"),
                                          content: Text(
                                            "Yakin ingin menghapus transaksi ini?",
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text("Batal"),
                                              onPressed:
                                                  () => Navigator.pop(context),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: Text("Hapus"),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await _deletePenjualan(
                                                  item.id!,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                  );
                                },
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
