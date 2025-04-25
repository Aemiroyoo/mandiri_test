import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/penjualan.dart';

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
  int _selectedIndex = 0;
  Map<int, double> dataHarian = {};
  String selectedBulan = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userRole =
          ModalRoute.of(context)?.settings.arguments as String? ??
          'admin_karyawan';
      fetchDataChart();
      loadMonthlyData();
      getUserData();
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

  Future<void> loadMonthlyData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('penjualan')
              .where('tanggal', isGreaterThanOrEqualTo: '$selectedBulan-01')
              .where('tanggal', isLessThanOrEqualTo: '$selectedBulan-31')
              .get();

      final semuaData =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Penjualan(
              id: doc.id,
              total: data['total'] ?? 0,
              tanggal: data['tanggal'] ?? '',
              namaPelanggan: data['nama_pelanggan'] ?? '',
              detail: [],
            );
          }).toList();

      totalPemasukan = semuaData.fold(0, (sum, item) => sum + item.total);
      totalOrder = semuaData.length;
      setState(() {});
    } catch (e) {
      print("Gagal memuat data: $e");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          // handle navigation if needed
        },
        backgroundColor: const Color(0xFFF9FAFB),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hello,", style: TextStyle(fontSize: 16)),
                          Text(
                            namaUser ?? '-',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
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
              const SizedBox(height: 24),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInfoCard(
                      "Total Pemasukan",
                      "Rp. ${NumberFormat("#,###").format(totalPemasukan)},-",
                      Icons.trending_up,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCard(
                      "Jumlah Order",
                      "$totalOrder transaksi",
                      Icons.list_alt,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildDropdownBulan(),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    maxY: 600000,
                    minX: 1,
                    maxX: 30,
                    minY: 0,
                    titlesData: FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          30,
                          (i) => FlSpot(
                            (i + 1).toDouble(),
                            dataHarian[i + 1] ?? 0,
                          ),
                        ),
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.blue,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Menu Admin",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  menuButton1(
                    "Daftar Barang",
                    () => Navigator.pushNamed(context, '/daftar-harga'),
                  ),
                  menuButton1("Input Penjualan", () {
                    Navigator.pushNamed(context, '/input-penjualan').then((_) {
                      fetchDataChart();
                      loadMonthlyData();
                    });
                  }),
                  menuButton1(
                    "Riwayat Penjualan",
                    () => Navigator.pushNamed(context, '/riwayat-penjualan'),
                  ),
                  menuButton1(
                    "Laporan Penjualan",
                    () => Navigator.pushNamed(context, '/laporan-penjualan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 1)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBulan() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Pilih Bulan Pemasukan:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBulan,
              items: List.generate(12, (index) {
                final date = DateTime(DateTime.now().year, index + 1);
                final label = DateFormat('yyyy-MM').format(date);
                return DropdownMenuItem(
                  value: label,
                  child: Text(DateFormat('MMMM yyyy', 'id_ID').format(date)),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedBulan = value);
                  fetchDataChart();
                  loadMonthlyData();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget menuButton1(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
