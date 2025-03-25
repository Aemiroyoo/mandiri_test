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
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    final now = DateTime.now();
    final bulanIni = DateFormat('yyyy-MM').format(now); // contoh: 2025-03

    List<Penjualan> semua = await DBHelper.getAllPenjualan();

    final dataBulanIni =
        semua.where((e) => e.tanggal.startsWith(bulanIni)).toList();

    totalPemasukan = dataBulanIni.fold(0, (total, item) => total + item.total);
    totalOrder = dataBulanIni.length;

    setState(() {});
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

              // Grafik Penjualan
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 20),
                              FlSpot(1, 25),
                              FlSpot(2, 30),
                              FlSpot(3, 45),
                              FlSpot(4, 60),
                              FlSpot(5, 50),
                            ],
                            isCurved: true,
                            barWidth: 3,
                            color: Colors.blue,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const months = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'Mei',
                                  'Jun',
                                ];
                                return Text(months[value.toInt()]);
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Grafik Penjualan",
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
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
