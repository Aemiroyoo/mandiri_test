import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TambahKaryawanScreen extends StatefulWidget {
  const TambahKaryawanScreen({super.key});

  @override
  State<TambahKaryawanScreen> createState() => _TambahKaryawanScreenState();
}

String capitalizeEachWord(String text) {
  return text
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

class _TambahKaryawanScreenState extends State<TambahKaryawanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _daftarkanKaryawan() async {
    if (_namaController.text.trim().isEmpty ||
        _namaController.text.trim().replaceAll(' ', '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nama tidak boleh hanya spasi"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;

      // Simpan UID pemilik
      final ownerId = auth.currentUser?.uid;
      if (ownerId == null) throw Exception('User tidak ditemukan');

      // Buat akun baru
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Simpan ke koleksi "users"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': _emailController.text.trim(),
            'nama': capitalizeEachWord(_namaController.text.trim()),
            'role': 'admin_karyawan',
            'owner_id': ownerId,
            'created_at': DateTime.now().toIso8601String(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karyawan berhasil didaftarkan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan';
      if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Tambah Karyawan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              const Color.fromARGB(255, 251, 253, 255),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(
                              Icons.person_add_alt_1,
                              size: 40,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Informasi Karyawan",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Karyawan',
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Color(0xFF1976D2),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Nama wajib diisi'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Karyawan',
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Color(0xFF1976D2),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email wajib diisi';
                            final emailRegex = RegExp(
                              r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value))
                              return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Color(0xFF1976D2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blue.shade700,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          obscureText: _obscurePassword,
                          validator:
                              (value) =>
                                  value == null || value.length < 6
                                      ? 'Minimal 6 karakter'
                                      : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _daftarkanKaryawan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add),
                                        SizedBox(width: 10),
                                        Text(
                                          "Daftarkan Karyawan",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
