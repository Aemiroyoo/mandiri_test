import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mandiri_test/screen/daftar_harga_screen.dart';
import 'package:mandiri_test/screen/input_penjualan_screen.dart';
import 'package:mandiri_test/screen/laporan_penjualan_screen.dart';
import 'package:mandiri_test/sign_in/login_screen.dart';
import 'package:mandiri_test/home/home_screen.dart'; // tambahkan ini kalau belum

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demos',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,

      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/daftar-harga': (context) => DaftarHargaScreen(),
        '/input-penjualan': (context) => InputPenjualanScreen(),
        '/laporan-penjualan': (context) => LaporanPenjualanScreen(),
      },

      // home: DaftarHargaScreen(),
      // home: InputPenjualanScreen(),
      // home: LaporanPenjualanScreen(),
      home: LoginScreen(),
    );
  }
}
