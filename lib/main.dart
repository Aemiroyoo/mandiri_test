import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mandiri_test/screen/daftar_harga_screen.dart';
import 'package:mandiri_test/screen/input_penjualan_screen.dart';
import 'package:mandiri_test/screen/laporan_penjualan_screen.dart';
import 'package:mandiri_test/screen/riwayat_penjualan_screen.dart';
import 'package:mandiri_test/sign_in/login_screen.dart';
import 'package:mandiri_test/home/home_screen.dart'; // tambahkan ini kalau belum

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Cek user yang sedang login
  final currentUser = FirebaseAuth.instance.currentUser;

  runApp(MyApp(isLoggedIn: currentUser != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,

      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/daftar-harga': (context) => DaftarHargaScreen(),
        '/input-penjualan': (context) => InputPenjualanScreen(),
        '/riwayat-penjualan': (context) => RiwayatPenjualanScreen(),
        '/laporan-penjualan': (context) => LaporanPenjualanScreen(),
      },

      // Cek apakah user sudah login
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
    );
  }
}
