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

class _EditPenjualanScreenState extends State<EditPenjualanScreen> {
  final namaController = TextEditingController();

  List<PenjualanDetail> listDetail = [];
  List<LayananLaundry> semuaLayanan = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    namaController.text = widget.data.namaPelanggan;
    loadData();
  }

  Future<void> loadData() async {
    semuaLayanan = await DBHelper().getAllLayanan();

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
      'nama_pelanggan': namaController.text.trim(),
      'total': totalBaru,
    });

    final detailRef = penjualanRef.collection('detail');

    // Hapus semua layanan lama
    final snapshot = await detailRef.get();
    for (var d in snapshot.docs) {
      await d.reference.delete();
    }

    // ⛳️ Tambahkan layanan baru (cukup sekali aja!)
    for (var item in listDetail) {
      await detailRef.add({
        'penjualan_id': id, // ✅ tambahkan ini
        'layanan_id': item.layananId,
        'nama_layanan': item.namaLayanan,
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
        title: Text("Edit Penjualan"),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(onPressed: simpanPerubahan, icon: Icon(Icons.save)),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: namaController,
                    decoration: InputDecoration(labelText: "Nama Pelanggan"),
                  ),
                  SizedBox(height: 16),

                  ...List.generate(listDetail.length, (i) {
                    final d = listDetail[i];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<LayananLaundry>(
                              value: semuaLayanan.firstWhere(
                                (e) => e.id == d.layananId,
                                orElse: () => semuaLayanan.first,
                              ),
                              items:
                                  semuaLayanan.map((layanan) {
                                    return DropdownMenuItem(
                                      value: layanan,
                                      child: Text(layanan.namaLayanan),
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
                                      total: value.harga * listDetail[i].jumlah,
                                    );
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: d.jumlah.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: "Jumlah (${d.satuan})",
                                    ),
                                    onChanged: (val) {
                                      final j = int.tryParse(val) ?? 1;
                                      listDetail[i] = listDetail[i].copyWith(
                                        jumlah: j,
                                      );
                                      hitungUlangTotal(i);
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  currency.format(d.total),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      listDetail.removeAt(i);
                                    });
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  OutlinedButton.icon(
                    onPressed: tambahDetailKosong,
                    icon: Icon(Icons.add),
                    label: Text("Tambah Layanan"),
                  ),
                ],
              ),
    );
  }
}
