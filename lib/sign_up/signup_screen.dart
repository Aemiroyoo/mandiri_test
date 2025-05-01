import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandiri_test/sign_in/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _capitalizeEachWord(String text) {
    return text
        .toLowerCase()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  Future<void> _handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final nama = namaController.text.trim();
    final telp = noTelpController.text.trim();

    if (nama.isEmpty || nama.replaceAll(' ', '').isEmpty) {
      _showSnackbar("Nama wajib diisi");
      return;
    }

    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackbar("Format email tidak valid");
      return;
    }

    if (telp.isEmpty ||
        telp.length < 10 ||
        !RegExp(r'^[0-9]+$').hasMatch(telp)) {
      _showSnackbar("Nomor telepon harus berupa angka minimal 10 digit");
      return;
    }

    if (password.length < 6) {
      _showSnackbar("Password minimal 6 karakter");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'nama': _capitalizeEachWord(nama),
        'no_telp': telp,
        'role': 'master',
        'owner_id': uid,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registrasi berhasil!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = '';
      if (e.code == 'email-already-in-use') {
        msg = 'Email sudah digunakan';
      } else if (e.code == 'weak-password') {
        msg = 'Password terlalu lemah';
      } else {
        msg = 'Terjadi kesalahan: ${e.message}';
      }

      _showSnackbar(msg);
    } catch (e) {
      _showSnackbar("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFF00224F),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Create your account to get started",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    SizedBox(height: 40),
                    _buildInputField(
                      controller: namaController,
                      hintText: "Nama Lengkap",
                      icon: Icons.person_outline,
                      capitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: noTelpController,
                      hintText: "Nomor Telepon",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 20),
                    _buildInputField(
                      controller: emailController,
                      hintText: "Email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(color: Colors.white60),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.white70,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF00224F),
                          elevation: 2,
                          shadowColor: Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF00224F),
                                    ),
                                  ),
                                )
                                : Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
