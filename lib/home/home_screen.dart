import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/penjualan.dart';

import 'package:mandiri_test/sign_in/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, required this.userRole});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? namaUser;
  late final String userRole;
  int totalPemasukan = 0;
  int totalOrder = 0;

  @override
  void initState() {
    super.initState();
    selectedBulan = DateFormat('yyyy-MM').format(DateTime.now());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      userRole = args as String? ?? 'admin_karyawan';
      fetchDataChart();
      loadMonthlyData();
      getUserData();
    });
  }

  Map<int, double> dataHarian = {};
  String selectedBulan = DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> loadMonthlyData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('penjualan').get();

      final List<Penjualan> semuaData =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Penjualan(
              id: doc.id,
              total: data['total'],
              tanggal: data['tanggal'],
              namaPelanggan: data['namaPelanggan'],
              detail: [],
            );
          }).toList();

      final dataBulanIni =
          semuaData.where((e) => e.tanggal.startsWith(selectedBulan)).toList();

      totalPemasukan = dataBulanIni.fold(0, (sum, item) => sum + item.total);
      totalOrder = dataBulanIni.length;

      setState(() {});
    } catch (e) {
      print("Gagal memuat data dari Firestore: $e");
    }
  }

  Future<void> fetchDataChart() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('penjualan')
            .where('tanggal', isGreaterThanOrEqualTo: '$selectedBulan-01')
            .where('tanggal', isLessThanOrEqualTo: '$selectedBulan-31')
            .get();

    print("Fetch data untuk bulan: $selectedBulan");
    print("Total dokumen ditemukan: ${snapshot.docs.length}");

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

  Future<void> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          namaUser = doc.data()?['nama'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Homepage",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 96, 96, 96),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Hallo,", style: TextStyle(fontSize: 16)),
                        Text(
                          namaUser ?? "-",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Pemasukan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Rp. ${NumberFormat("#,###").format(totalPemasukan)},-",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Jumlah Order",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Total: $totalOrder",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Text("Pilih Bulan:"),
                  const SizedBox(width: 10),
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
                        fetchDataChart(); // ✅ grafik update
                        loadMonthlyData(); // ✅ total dan order update
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LineChart(
                    LineChartData(
                      maxY: 600000,
                      minX: 1,
                      maxX: 30,
                      minY: 0,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                space: 6,
                                meta: meta,
                                child: Transform.rotate(
                                  angle: -0.9,
                                  child: Text(
                                    "${value.toInt()}",
                                    style: const TextStyle(
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
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                "${NumberFormat.compact().format(value)}",
                                style: const TextStyle(
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
                      lineTouchData: LineTouchData(enabled: false),
                      clipData: FlClipData.none(),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: true),
                      extraLinesData: ExtraLinesData(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(30, (i) {
                            final day = i + 1;
                            return FlSpot(day.toDouble(), dataHarian[day] ?? 0);
                          }),
                          isCurved: false,
                          dotData: FlDotData(show: false),
                          barWidth: 2,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Menu Admin",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  // if (widget.userRole == 'admin_master')
                  menuButton1(
                    "Daftar Barang",
                    () => Navigator.pushNamed(context, '/daftar-harga'),
                  ),
                  // if (widget.userRole == 'admin_karyawan') ...[
                  menuButton1("Input Penjualan", () {
                    Navigator.pushNamed(context, '/input-penjualan').then((_) {
                      fetchDataChart();
                      loadMonthlyData();
                    });
                  }),
                  menuButton1("Riwayat Penjualan", () {
                    Navigator.pushNamed(context, '/riwayat-penjualan');
                  }),
                  // ],
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
        style: const TextStyle(fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget menuButton1(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
