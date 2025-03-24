import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/penjualan.dart';

class LaporanPenjualanScreen extends StatefulWidget {
  @override
  State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
}

class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
  int totalIncome = 0;
  List<Penjualan> penjualanBulanIni = [];

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM');
    final bulanIni = formatter.format(now); // ex: 2025-03

    List<Penjualan> semuaData = await DBHelper.getAllPenjualan();
    penjualanBulanIni =
        semuaData.where((e) => e.tanggal.startsWith(bulanIni)).toList();

    totalIncome = penjualanBulanIni.fold(0, (sum, item) => sum + item.total);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Laporan Penjualan"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Card Income
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "IDR. ${NumberFormat("#,###").format(totalIncome)}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Income"),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet, size: 30),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Tombol export (dummy dulu)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.file_copy),
                  label: Text("Export to Excel"),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Export to PDF"),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Dummy tabel laporan
            Expanded(
              child: ListView.builder(
                itemCount: penjualanBulanIni.length,
                itemBuilder: (context, index) {
                  final item = penjualanBulanIni[index];
                  return ListTile(
                    title: Text(item.namaPelanggan),
                    subtitle: Text(
                      "${item.namaLayanan} - ${item.jumlah} ${item.satuan}",
                    ),
                    trailing: Text("Rp. ${item.total},-"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
