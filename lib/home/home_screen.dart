import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/penjualan.dart';

import 'package:mandiri_test/sign_in/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalPemasukan = 0;
  int totalOrder = 0;

  @override
  void initState() {
    super.initState();
    fetchDataChart();
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    final now = DateTime.now();
    final bulanIni = DateFormat('yyyy-MM').format(now); // contoh: 2025-04

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('penjualan').get();

      final List<Penjualan> semuaData =
          snapshot.docs.map((doc) {
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

      final dataBulanIni =
          semuaData.where((e) => e.tanggal.startsWith(bulanIni)).toList();

      totalPemasukan = dataBulanIni.fold(0, (sum, item) => sum + item.total);
      totalOrder = dataBulanIni.length;

      setState(() {});
    } catch (e) {
      print("Gagal memuat data dari Firestore: $e");
    }
  }

  Map<int, double> dataHarian = {};
  String selectedBulan = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> bulanList = [];

  Future<void> fetchDataChart() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('penjualan')
            .where('tanggal', isGreaterThanOrEqualTo: '$selectedBulan-01')
            .where('tanggal', isLessThanOrEqualTo: '$selectedBulan-31')
            .get();

    Map<int, double> mapData = {};
    for (var doc in snapshot.docs) {
      final tanggal = doc['tanggal'];
      final total = (doc['total'] ?? 0).toDouble();
      final hari = int.parse(tanggal.split('-')[2]);
      mapData.update(hari, (value) => value + total, ifAbsent: () => total);
    }

    setState(() {
      dataHarian = mapData;
    });
  }

  // class HomeScreen extends StatelessWidget {
  //   const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Homepage",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      // Arahkan kembali ke halaman login
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    // onPressed: () async {
                    //   Navigator.of(context).pushReplacement(
                    //     MaterialPageRoute(builder: (context) => LoginScreen()),
                    //   );
                    // },
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Card Hi, Lakuna
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 96, 96, 96),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 24, backgroundColor: Colors.grey),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi,", style: TextStyle(fontSize: 16)),
                        Text(
                          "Lakuna ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Total Pemasukan dan Jumlah Order
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Pemasukan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Rp. ${NumberFormat("#,###").format(totalPemasukan)},-",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Jumlah Order",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Total: $totalOrder",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 26),
              Row(
                children: [
                  Text("Pilih Bulan:"),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedBulan,
                    items: List.generate(12, (index) {
                      final date = DateTime(DateTime.now().year, index + 1);
                      final label = DateFormat('yyyy-MM').format(date);
                      return DropdownMenuItem(
                        value: label,
                        child: Text(
                          DateFormat('MMMM yyyy', 'id_ID').format(date),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedBulan = value;
                        });
                        fetchDataChart();
                      }
                    },
                  ),
                ],
              ),

              // Grafik Penjualan
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ), // 👉 beri jarak kiri-kanan
                  child: LineChart(
                    LineChartData(
                      // minY: 0,
                      maxY: 500000, // optional, bisa dihitung dari data
                      minX: 1,
                      maxX: 30,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                // axisSide: meta.axisSide,
                                space: 6,
                                meta: meta,
                                child: Transform.rotate(
                                  angle:
                                      -0.9, // lebih miring agar lebih hemat ruang
                                  child: Text(
                                    "${value.toInt()}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${NumberFormat.compact().format(value)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w800,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      // ✅ Tambahkan padding/space agar tidak nubruk
                      lineTouchData: LineTouchData(enabled: false),
                      clipData: FlClipData.none(),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: true),
                      // 👉 Ini penting untuk beri spasi kiri-kanan
                      extraLinesData: ExtraLinesData(),
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(30, (i) {
                            final day = i + 1;
                            return FlSpot(day.toDouble(), dataHarian[day] ?? 0);
                          }),
                          isCurved:
                              false, // ⬅️ Ini yang bikin garis jadi lurus, bukan lengkung ekstrem
                          dotData: FlDotData(show: false),
                          barWidth: 2,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // SizedBox(height: 24),

              // Menu Data Penjualan
              // Text(
              //   "Menu Data Penjualan",
              //   style: TextStyle(fontWeight: FontWeight.bold),
              // ),
              // SizedBox(height: 12),
              // Wrap(
              //   spacing: 10,
              //   runSpacing: 12,
              //   children: [
              //     menuButton("Data\nHarian", width: 82, height: 83),
              //     menuButton("Data\nMingguan", width: 82, height: 83),
              //     menuButton("Data\nBulanan", width: 82, height: 83),
              //     menuButton("Data\nTahunan", width: 82, height: 83),
              //   ],
              // ),
              SizedBox(height: 24),

              // Menu Admin
              Text("Menu Admin", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  menuButton1("Daftar Barang", () {
                    Navigator.pushNamed(
                      context,
                      '/daftar-harga',
                    ); // misalnya ini screen daftar harga
                  }),
                  menuButton1("Input Penjualan", () {
                    Navigator.pushNamed(context, '/input-penjualan');
                  }),
                  menuButton1("Riwayat Penjualan", () {
                    Navigator.pushNamed(
                      context,
                      '/riwayat-penjualan',
                    ); // ganti kalau punya screen khusus
                  }),
                  menuButton1("Laporan Penjualan", () {
                    Navigator.pushNamed(context, '/laporan-penjualan');
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget menuButton(String title, {double width = 150, double height = 60}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget menuButton1(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(2),
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
