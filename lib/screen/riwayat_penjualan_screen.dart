import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/screen/edit_penjualan_screen.dart';
import '../models/penjualan.dart';
import '../models/penjualan_detail.dart';
import 'input_penjualan_screen.dart';

class RiwayatPenjualanScreen extends StatefulWidget {
  const RiwayatPenjualanScreen({super.key});

  @override
  State<RiwayatPenjualanScreen> createState() => _RiwayatPenjualanScreenState();
}

String capitalizeEachWord(String text) {
  return text
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class _RiwayatPenjualanScreenState extends State<RiwayatPenjualanScreen> {
  String? ownerId;
  List<Penjualan> dataPenjualan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    ambilOwnerId().then((_) {
      fetchPenjualan();
    });
  }

  Future<void> ambilOwnerId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = userDoc.data();
    ownerId = data?['owner_id'] ?? uid;
    print("📌 owner_id aktif: $ownerId");
  }

  Future<void> fetchPenjualan() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (ownerId == null) {
        print("❌ ownerId masih null");
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('penjualan')
              .where('owner_id', isEqualTo: ownerId) // ✅ FIXED: pakai ownerId!
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
        isLoading = false;
      });

      print("✅ Total transaksi: ${list.length}");
    } catch (e) {
      print("❌ Gagal ambil data penjualan: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _deletePenjualan(String id) async {
    try {
      final ref = FirebaseFirestore.instance.collection('penjualan').doc(id);
      final detailSnapshot = await ref.collection('detail').get();
      for (var d in detailSnapshot.docs) {
        await d.reference.delete();
      }
      await ref.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      fetchPenjualan();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus transaksi: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (e) {}
    return date;
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
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Riwayat Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.add, color: Colors.white),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (_) => InputPenjualanScreen()),
        //       ).then((_) => fetchPenjualan());
        //     },
        //   ),
        // ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : dataPenjualan.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 70, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Belum ada data penjualan",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text("Tambah Penjualan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InputPenjualanScreen(),
                            ),
                          ).then((_) => fetchPenjualan()),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: fetchPenjualan,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: dataPenjualan.length,
                  itemBuilder: (context, index) {
                    final item = dataPenjualan[index];

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      elevation: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.blue.shade50],
                            stops: [0.85, 1.0],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      capitalizeEachWord(item.namaPelanggan),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDate(item.tanggal),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Details
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: item.detail.length,
                                    itemBuilder: (context, detailIndex) {
                                      final layanan = item.detail[detailIndex];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: Colors.blue.shade800,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: capitalizeEachWord(
                                                        layanan.namaLayanan,
                                                      ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          " (${layanan.jumlah} ${layanan.satuan})",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "${currency.format(layanan.total)}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  Divider(height: 24),

                                  // Total
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total:",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${currency.format(item.total)}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.edit, size: 18),
                                    label: Text("Edit"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => EditPenjualanScreen(
                                                data: item,
                                              ),
                                        ),
                                      ).then((_) {
                                        fetchPenjualan();
                                      });
                                    },
                                  ),
                                  TextButton.icon(
                                    icon: Icon(Icons.delete, size: 18),
                                    label: Text("Hapus"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
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
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton:
          dataPenjualan.isNotEmpty
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InputPenjualanScreen()),
                  ).then((_) => fetchPenjualan());
                },
                backgroundColor: Colors.blue.shade900,
                child: Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }
}
