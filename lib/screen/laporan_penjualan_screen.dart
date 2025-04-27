import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiri_test/models/penjualan_detail.dart';
import '../models/penjualan.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  String selectedFilter = 'Bulan ini';
  final filterOptions = ['Semua', 'Hari ini', 'Minggu ini', 'Bulan ini'];

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('penjualan')
              .orderBy('tanggal', descending: true)
              .get();

      semuaData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Periksa apakah field yang diperlukan ada dan tidak null
        if (data['nama_pelanggan'] == null ||
            data['tanggal'] == null ||
            data['total'] == null) {
          print("Data tidak lengkap untuk dokumen ${doc.id}, melewati...");
          continue; // Lewati dokumen yang tidak lengkap
        }

        try {
          final detailSnapshot = await doc.reference.collection('detail').get();

          final detailList =
              detailSnapshot.docs.map((d) {
                final dataDetail = d.data();
                return PenjualanDetail(
                  id: d.id,
                  penjualanId: doc.id,
                  layananId: dataDetail['layanan_id'] ?? '',
                  namaLayanan: dataDetail['nama_layanan'] ?? 'Tanpa Nama',
                  hargaSatuan: dataDetail['harga_satuan'] ?? 0,
                  satuan: dataDetail['satuan'] ?? 'pcs',
                  jumlah: dataDetail['jumlah'] ?? 0,
                  total: dataDetail['total'] ?? 0,
                );
              }).toList();

          semuaData.add(
            Penjualan(
              id: doc.id,
              namaPelanggan: data['nama_pelanggan'] ?? 'Tanpa Nama',
              tanggal:
                  data['tanggal'] ??
                  DateFormat('yyyy-MM-dd').format(DateTime.now()),
              total: data['total'] ?? 0,
              detail: detailList,
            ),
          );
        } catch (e) {
          print("Error saat memproses detail untuk ${doc.id}: $e");
        }
      }

      // Filter data setelah semua data di-load
      if (mounted) {
        _filterData();
      }
    } catch (e) {
      print("Error saat memuat data: $e");
      if (mounted) {
        setState(() {
          // Set state untuk menampilkan UI error jika diperlukan
        });
      }
    }
  }

  void _filterData() {
    if (semuaData.isEmpty) {
      setState(() {
        totalFiltered = 0;
        totalIncome = 0;
        dataTampil = [];
      });
      return;
    }

    final now = DateTime.now();
    List<Penjualan> filtered = [];

    try {
      if (selectedFilter == 'Hari ini') {
        String today = DateFormat('yyyy-MM-dd').format(now);
        filtered = semuaData.where((e) => e.tanggal == today).toList();
      } else if (selectedFilter == 'Minggu ini') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filtered =
            semuaData.where((e) {
              try {
                DateTime date = DateTime.parse(e.tanggal);
                return date.isAfter(startOfWeek.subtract(Duration(days: 1)));
              } catch (e) {
                print("Error parsing date: ${(e as Penjualan).tanggal}");
                return false;
              }
            }).toList();
      } else if (selectedFilter == 'Bulan ini') {
        String bulanIni = DateFormat('yyyy-MM').format(now);
        filtered =
            semuaData.where((e) => e.tanggal.startsWith(bulanIni)).toList();
      } else {
        filtered = semuaData;
      }

      setState(() {
        totalFiltered = filtered.length;
        totalIncome = filtered.fold(0, (sum, item) => sum + item.total);
        dataTampil = filtered.take(limit).toList();
      });
    } catch (e) {
      print("Error saat memfilter data: $e");
      setState(() {
        totalFiltered = 0;
        totalIncome = 0;
        dataTampil = [];
      });
    }
  }

  String capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
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

  Future<void> exportToPdf() async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.decimalPattern('id');
    final now = DateTime.now();
    final bulanIni = DateFormat('MMMM yyyy', 'id_ID').format(now);

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Penjualan',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Bulan: $bulanIni',
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Total Transaksi: $totalFiltered',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Total Income: Rp. ${currencyFormat.format(totalIncome)},-',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    border: null,
                    cellAlignment: pw.Alignment.centerLeft,
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                    cellStyle: pw.TextStyle(
                      fontSize: 11, // ini untuk isi datanya
                    ),
                    headers: [
                      'No',
                      'Tanggal',
                      'Pelanggan',
                      'Layanan',
                      'Qty',
                      'Harga',
                      'Total',
                    ],
                    data: _generateTableData(currencyFormat),
                  ),
                ],
              ),
            ],
      ),
    );

    final status = await Permission.storage.request();
    if (status.isGranted) {
      final bytes = await pdf.save();
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      final file = File('${downloadsDirectory.path}/laporan_penjualan.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF berhasil disimpan di Download!')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Izin penyimpanan ditolak')));
    }
  }

  List<List<String>> _generateTableData(NumberFormat currencyFormat) {
    List<List<String>> rows = [];
    int no = 1;

    for (var penjualan in _filteredList()) {
      for (var detail in penjualan.detail) {
        rows.add([
          no.toString(),
          penjualan.tanggal,
          capitalizeWords(penjualan.namaPelanggan),
          capitalizeWords(detail.namaLayanan),
          '${detail.jumlah} ${detail.satuan}',
          'Rp ${currencyFormat.format(detail.hargaSatuan)}',
          'Rp ${currencyFormat.format(detail.total)}',
        ]);
        no++;
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.decimalPattern('id');
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Laporan Penjualan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          // Header with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.blue.shade800],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withOpacity(0.3),
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 24),
            child: Column(
              children: [
                // Income Card
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pemasukan",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "IDR. ${NumberFormat("#,###").format(totalIncome)}",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Filter Row with nice dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Filter Penjualan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          value: selectedFilter,
                          isDense: true,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.blue.shade900,
                          ),
                          items:
                              filterOptions.map((f) {
                                return DropdownMenuItem(
                                  value: f,
                                  child: Text(f),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFilter = value!;
                              _filterData();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Export Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.file_copy, size: 18),
                        label: Text(
                          "Export to Excel",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: exportToPdf,
                        icon: Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(
                          "Export to PDF",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Data Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Data: $totalFiltered",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  "Riwayat Transaksi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // List of Transactions
          Expanded(
            child:
                dataTampil.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tidak ada data transaksi",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: dataTampil.length,
                      itemBuilder: (context, index) {
                        final item = dataTampil[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            capitalizeWords(
                                              item.namaPelanggan,
                                            )[0],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          capitalizeWords(item.namaPelanggan),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Rp. ${currencyFormat.format(item.total)},-",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Divider(height: 1, color: Colors.grey.shade200),
                                SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      item.detail.map((d) {
                                        return Padding(
                                          padding: EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 8,
                                                    color: Colors.blue.shade900,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    d.namaLayanan,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "${d.jumlah} ${d.satuan}",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Load More Button
          if (dataTampil.length < semuaData.length &&
              dataTampil.length < _filteredList().length)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    limit += 10;
                    _filterData();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Muat Lebih Banyak",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
