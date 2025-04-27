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
  String? emailUser;
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
      getEmailData();
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

  void getEmailData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        emailUser = user.email;
      });
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
      endDrawer: Drawer(
        width: 280,
        child: Column(
          children: [
            // Header dengan gradient dan efek bayangan
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade900, Colors.blue.shade800],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern (subtle dots)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.network(
                        'https://www.transparenttextures.com/patterns/cubes.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // User info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              namaUser?.isNotEmpty == true
                                  ? namaUser![0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          namaUser ?? 'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 6),
                            Text(
                              emailUser ?? '',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
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

            // Divider with gradient
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Profile Menu Item
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(context); // Tutup drawer
                            final result = await Navigator.pushNamed(
                              context,
                              '/profile',
                            );
                            if (result == true) {
                              // Kalau kembali dari Profile dengan perubahan, refresh nama user
                              getUserData(); // panggil fungsi load ulang nama user
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.blue.shade900,
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(height: 1, color: Colors.grey.shade200),
                      ),

                      // Logout Menu Item
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            // Show confirmation dialog
                            bool confirm = await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Logout'),
                                    content: Text(
                                      'Apakah Anda yakin ingin keluar dari aplikasi?',
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text('Logout'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacementNamed(context, '/login');
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red.shade600,
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // App version at bottom
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              color: Colors.grey.shade50,
              child: Center(
                child: Text(
                  'App Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),

      // backgroundColor: const Color(0xFFF5F7FA),
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     color: Colors.white,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withOpacity(0.05),
      //         spreadRadius: 1,
      //         blurRadius: 10,
      //       ),
      //     ],
      //   ),
      //   child: BottomNavigationBar(
      //     currentIndex: _selectedIndex,
      //     onTap: (index) {
      //       setState(() => _selectedIndex = index);
      //       // handle navigation if needed
      //     },
      //     backgroundColor: Colors.white,
      //     selectedItemColor: const Color(0xFF3B82F6),
      //     unselectedItemColor: Colors.grey.shade400,
      //     showSelectedLabels: true,
      //     showUnselectedLabels: true,
      //     type: BottomNavigationBarType.fixed,
      //     elevation: 0,
      //     items: const [
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.home_outlined),
      //         activeIcon: Icon(Icons.home),
      //         label: 'Home',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.settings_outlined),
      //         activeIcon: Icon(Icons.settings),
      //         label: 'Settings',
      //       ),
      //       BottomNavigationBarItem(
      //         icon: Icon(Icons.person_outline),
      //         activeIcon: Icon(Icons.person),
      //         label: 'Profile',
      //       ),
      //     ],
      //   ),
      // ),
      body: Builder(
        builder:
            (contextDrawer) => SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _buildHeader(
                    contextDrawer,
                  ), // ✅ kirim contextDrawer ke _buildHeader
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  _buildAdminMenu(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeader(BuildContext contextDrawer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Scaffold.of(
                    contextDrawer,
                  ).openEndDrawer(); // ✅ pakai contextDrawer
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      namaUser?.isNotEmpty == true
                          ? namaUser![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello,",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
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
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.red.shade700, size: 22),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(contextDrawer, '/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                "Total Pemasukan",
                "Rp. ${NumberFormat("#,###").format(totalPemasukan)},-",
                Icons.trending_up,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                "Jumlah Order",
                "$totalOrder transaksi",
                Icons.list_alt,
                const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Grafik Pemasukan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildDropdownBulan(),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 100000,
                  verticalInterval: 5,
                  getDrawingHorizontalLine:
                      (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  getDrawingVerticalLine:
                      (value) =>
                          FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 == 0) {
                          return SideTitleWidget(
                            meta: meta, // ✅ ini
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200000,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta, // ✅ ini
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
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
                borderData: FlBorderData(show: false),
                maxY: 600000,
                minX: 1,
                maxX: 30,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      30,
                      (i) => FlSpot((i + 1).toDouble(), dataHarian[i + 1] ?? 0),
                    ),
                    isCurved: true,
                    barWidth: 3,
                    color: const Color(0xFF3B82F6),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter:
                          (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF3B82F6),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Menu Admin",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildMenuButton(
                "Daftar Barang",
                Icons.inventory,
                const Color(0xFF3B82F6),
                () => Navigator.pushNamed(context, '/daftar-harga'),
              ),
              _buildMenuButton(
                "Input Penjualan",
                Icons.point_of_sale,
                const Color(0xFF10B981),
                () {
                  Navigator.pushNamed(context, '/input-penjualan').then((_) {
                    fetchDataChart();
                    loadMonthlyData();
                  });
                },
              ),
              _buildMenuButton(
                "Riwayat Penjualan",
                Icons.history,
                const Color(0xFFF59E0B),
                () => Navigator.pushNamed(context, '/riwayat-penjualan'),
              ),
              _buildMenuButton(
                "Laporan Penjualan",
                Icons.bar_chart,
                const Color(0xFFEF4444),
                () => Navigator.pushNamed(context, '/laporan-penjualan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownBulan() {
    final currentMonth = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateFormat('yyyy-MM').parse(selectedBulan));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBulan,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3B82F6)),
          borderRadius: BorderRadius.circular(12),
          items: List.generate(12, (index) {
            final date = DateTime(DateTime.now().year, index + 1);
            final label = DateFormat('yyyy-MM').format(date);
            return DropdownMenuItem(
              value: label,
              child: Text(
                DateFormat('MMMM yyyy', 'id_ID').format(date),
                style: const TextStyle(fontSize: 14),
              ),
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
    );
  }

  Widget _buildMenuButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
