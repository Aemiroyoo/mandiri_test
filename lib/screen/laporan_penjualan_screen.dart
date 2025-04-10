import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/models/penjualan_detail.dart';
import '../models/penjualan.dart';

class LaporanPenjualanScreen extends StatefulWidget {
  @override
  State<LaporanPenjualanScreen> createState() => _LaporanPenjualanScreenState();
}

class _LaporanPenjualanScreenState extends State<LaporanPenjualanScreen> {
  int limit = 10;
  int totalIncome = 0;
  int totalFiltered = 0;

  List<Penjualan> semuaData = [];
  List<Penjualan> dataTampil = [];

  String selectedFilter = 'Hari ini';
  final filterOptions = ['Semua', 'Hari ini', 'Minggu ini', 'Bulan ini'];

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('penjualan')
            .orderBy('tanggal', descending: true)
            .get();

    semuaData = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final detailSnapshot = await doc.reference.collection('detail').get();

      final detailList =
          detailSnapshot.docs.map((d) {
            final dataDetail = d.data();
            return PenjualanDetail(
              id: d.id,
              penjualanId: doc.id,
              layananId: dataDetail['layanan_id'],
              namaLayanan: dataDetail['nama_layanan'],
              hargaSatuan: dataDetail['harga_satuan'],
              satuan: dataDetail['satuan'],
              jumlah: dataDetail['jumlah'],
              total: dataDetail['total'],
            );
          }).toList();

      // ✅ Pindahkan ke dalam setState agar update UI langsung saat selesai load
      _filterData();

      semuaData.add(
        Penjualan(
          id: doc.id,
          namaPelanggan: data['nama_pelanggan'],
          tanggal: data['tanggal'],
          total: data['total'],
          detail: detailList,
        ),
      );
    }
  }

  void _filterData() {
    final now = DateTime.now();
    List<Penjualan> filtered = [];

    if (selectedFilter == 'Hari ini') {
      String today = DateFormat('yyyy-MM-dd').format(now);
      filtered = semuaData.where((e) => e.tanggal == today).toList();
    } else if (selectedFilter == 'Minggu ini') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      filtered =
          semuaData.where((e) {
            DateTime date = DateTime.parse(e.tanggal);
            return date.isAfter(startOfWeek.subtract(Duration(days: 1)));
          }).toList();
    } else if (selectedFilter == 'Bulan ini') {
      String bulanIni = DateFormat('yyyy-MM').format(now);
      filtered =
          semuaData.where((e) => e.tanggal.startsWith(bulanIni)).toList();
    } else {
      filtered = semuaData;
    }

    totalFiltered = filtered.length;
    totalIncome = filtered.fold(0, (sum, item) => sum + item.total);
    dataTampil = filtered.take(limit).toList();
    setState(() {});
  }

  List<Penjualan> _filteredList() {
    final now = DateTime.now();
    if (selectedFilter == 'Hari ini') {
      String today = DateFormat('yyyy-MM-dd').format(now);
      return semuaData.where((e) => e.tanggal == today).toList();
    } else if (selectedFilter == 'Minggu ini') {
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return semuaData.where((e) {
        DateTime date = DateTime.parse(e.tanggal);
        return date.isAfter(startOfWeek.subtract(Duration(days: 1)));
      }).toList();
    } else if (selectedFilter == 'Bulan ini') {
      String bulanIni = DateFormat('yyyy-MM').format(now);
      return semuaData.where((e) => e.tanggal.startsWith(bulanIni)).toList();
    } else {
      return semuaData;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.decimalPattern('id');
    return Scaffold(
      appBar: AppBar(
        title: Text("Laporan Penjualan", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Dropdown
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Filter Data Penjualan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 40),
                  DropdownButton<String>(
                    value: selectedFilter,
                    items:
                        filterOptions.map((f) {
                          return DropdownMenuItem(value: f, child: Text(f));
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFilter = value!;
                        _filterData();
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Card Income
            Container(
              padding: EdgeInsets.all(20),
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
                  Icon(Icons.account_balance_wallet, size: 45),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Tombol Export
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

            // List Data Tampil
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Total Data: $totalFiltered",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        dataTampil.isEmpty
                            ? Center(child: Text("Tidak ada data."))
                            : ListView.builder(
                              itemCount: dataTampil.length,
                              itemBuilder: (context, index) {
                                final item = dataTampil[index];
                                return ListTile(
                                  title: Text(
                                    item.namaPelanggan,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.detail
                                        .map(
                                          (d) =>
                                              "${d.namaLayanan} - ${d.jumlah} ${d.satuan}",
                                        )
                                        .join('\n'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Text(
                                    "Rp. ${currencyFormat.format(item.total)},-",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),

                  if (dataTampil.length < semuaData.length &&
                      dataTampil.length < _filteredList().length)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          limit += 10;
                          _filterData();
                        });
                      },
                      child: Text("Load More"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
