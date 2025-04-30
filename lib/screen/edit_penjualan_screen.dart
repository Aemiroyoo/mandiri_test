import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/layanan_laundry.dart';
import '../models/penjualan.dart';
import '../models/penjualan_detail.dart';
import '../db/db_helper.dart';

class EditPenjualanScreen extends StatefulWidget {
  final Penjualan data;

  const EditPenjualanScreen({super.key, required this.data});

  @override
  State<EditPenjualanScreen> createState() => _EditPenjualanScreenState();
}

String capitalizeEachWord(String text) {
  return text
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class _EditPenjualanScreenState extends State<EditPenjualanScreen> {
  final namaController = TextEditingController();
  List<PenjualanDetail> listDetail = [];
  List<LayananLaundry> semuaLayanan = [];
  bool isLoading = true;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    namaController.text = widget.data.namaPelanggan;
    ambilOwnerId().then((_) {
      loadData();
    });
  }

  Future<void> ambilOwnerId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = userDoc.data();
    ownerId = data?['owner_id'] ?? uid;
    print('📌 owner_id aktif: $ownerId');
  }

  Future<void> loadData() async {
    if (ownerId == null) return;

    final layananSnapshot =
        await FirebaseFirestore.instance
            .collection('layanan_laundry')
            .where('owner_id', isEqualTo: ownerId)
            .get();

    semuaLayanan =
        layananSnapshot.docs.map((doc) {
          final d = doc.data();
          return LayananLaundry(
            id: doc.id,
            namaLayanan: d['namaLayanan'],
            kategori: d['kategori'],
            harga: d['harga'],
            satuan: d['satuan'],
          );
        }).toList();

    final detailSnapshot =
        await FirebaseFirestore.instance
            .collection('penjualan')
            .doc(widget.data.id)
            .collection('detail')
            .get();

    listDetail =
        detailSnapshot.docs.map((d) {
          final data = d.data();
          return PenjualanDetail(
            id: d.id,
            penjualanId: widget.data.id!,
            layananId: data['layanan_id'],
            namaLayanan: data['nama_layanan'],
            hargaSatuan: data['harga_satuan'],
            satuan: data['satuan'],
            jumlah: data['jumlah'],
            total: data['total'],
          );
        }).toList();

    setState(() {
      isLoading = false;
    });
  }

  void tambahDetailKosong() {
    final layanan = semuaLayanan.isNotEmpty ? semuaLayanan.first : null;
    if (layanan != null) {
      setState(() {
        listDetail.add(
          PenjualanDetail(
            id: null,
            penjualanId: widget.data.id!,
            layananId: layanan.id!,
            namaLayanan: layanan.namaLayanan,
            hargaSatuan: layanan.harga,
            satuan: layanan.satuan,
            jumlah: 1,
            total: layanan.harga,
          ),
        );
      });
    }
  }

  void hitungUlangTotal(int index) {
    final d = listDetail[index];
    final total = d.hargaSatuan * d.jumlah;
    setState(() {
      listDetail[index] = d.copyWith(total: total);
    });
  }

  Future<void> simpanPerubahan() async {
    final id = widget.data.id!;
    final totalBaru = listDetail.fold(0, (sum, item) => sum + item.total);

    final penjualanRef = FirebaseFirestore.instance
        .collection('penjualan')
        .doc(id);

    await penjualanRef.update({
      'nama_pelanggan': capitalizeEachWord(namaController.text.trim()),
      'total': totalBaru,
    });

    final detailRef = penjualanRef.collection('detail');

    // Hapus semua layanan lama
    final snapshot = await detailRef.get();
    for (var d in snapshot.docs) {
      await d.reference.delete();
    }

    // Tambahkan layanan baru
    for (var item in listDetail) {
      await detailRef.add({
        'penjualan_id': id,
        'layanan_id': item.layananId,
        'nama_layanan': capitalizeEachWord(item.namaLayanan),
        'harga_satuan': item.hargaSatuan,
        'satuan': item.satuan,
        'jumlah': item.jumlah,
        'total': item.total,
      });
    }

    Navigator.pop(context, true); // kembali ke riwayat
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
        title: Text("Edit Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            onPressed: simpanPerubahan,
            icon: Icon(Icons.save, color: Colors.white),
            tooltip: "Simpan Perubahan",
          ),
        ],
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: Colors.blue.shade900),
              )
              : ListView(
                padding: EdgeInsets.all(20),
                children: [
                  // Nama Pelanggan Field dengan styling yang lebih baik
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nama Pelanggan",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: namaController,
                          style: TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Masukkan nama pelanggan",
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 0,
                            ),
                            isDense: true,
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Header untuk detail layanan
                  if (listDetail.isNotEmpty)
                    Text(
                      "Detail Layanan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),

                  SizedBox(height: 12),

                  // Generate list detail layanan
                  ...List.generate(listDetail.length, (i) {
                    final d = listDetail[i];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Layanan ${i + 1}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      listDetail.removeAt(i);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red.shade700,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  tooltip: "Hapus Layanan",
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            // Dropdown dengan styling yang lebih baik
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonFormField<LayananLaundry>(
                                value: semuaLayanan.firstWhere(
                                  (e) => e.id == d.layananId,
                                  orElse: () => semuaLayanan.first,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Pilih Layanan",
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                ),
                                items:
                                    semuaLayanan.map((layanan) {
                                      return DropdownMenuItem(
                                        value: layanan,
                                        child: Text(
                                          layanan.namaLayanan,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      listDetail[i] = listDetail[i].copyWith(
                                        layananId: value.id!,
                                        namaLayanan: value.namaLayanan,
                                        hargaSatuan: value.harga,
                                        satuan: value.satuan,
                                        total:
                                            value.harga * listDetail[i].jumlah,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),

                            SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Field jumlah dengan styling yang lebih baik
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: TextFormField(
                                      initialValue: d.jumlah.toString(),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(fontSize: 15),
                                      decoration: InputDecoration(
                                        labelText: "Jumlah",
                                        labelStyle: TextStyle(fontSize: 14),
                                        suffixText: d.satuan,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) {
                                        final j = int.tryParse(val) ?? 1;
                                        setState(() {
                                          listDetail[i] = listDetail[i]
                                              .copyWith(jumlah: j);
                                          hitungUlangTotal(i);
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(width: 16),

                                // Total dengan styling yang lebih baik
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Text(
                                    currency.format(d.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  SizedBox(height: 8),

                  // Tombol tambah layanan dengan styling yang lebih baik
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: tambahDetailKosong,
                      icon: Icon(Icons.add),
                      label: Text(
                        "Tambah Layanan",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade900,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.blue.shade900),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Tombol simpan perubahan yang terlihat di bagian bawah
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: simpanPerubahan,
                      child: Text(
                        "SIMPAN PERUBAHAN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
