import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFF00224F),
      body: SafeArea(
        child: Stack(
          children: [
            // Back button
            // Positioned(
            //   top: 16,
            //   left: 16,
            //   child: InkWell(
            //     onTap: () {
            //       Navigator.pushReplacement(
            //         context,
            //         MaterialPageRoute(builder: (_) => LoginScreen()),
            //       );
            //     },
            //     child: Container(
            //       padding: EdgeInsets.all(8),
            //       decoration: BoxDecoration(
            //         color: Colors.white.withOpacity(0.1),
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(Icons.arrow_back, color: Colors.white, size: 20),
            //           SizedBox(width: 4),
            //           Text(
            //             "Back",
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontWeight: FontWeight.w500,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            // Form content
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80),

                    // Title
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

                    // Subtitle
                    Text(
                      "Create your account to get started",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),

                    SizedBox(height: 40),

                    // Input fields
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

                    // Password field with toggle visibility
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

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    final credential = await FirebaseAuth
                                        .instance
                                        .createUserWithEmailAndPassword(
                                          email: emailController.text.trim(),
                                          password:
                                              passwordController.text.trim(),
                                        );

                                    final uid = credential.user!.uid;

                                    // Simpan data user ke Firestore
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .set({
                                          'uid': uid,
                                          'email': credential.user!.email,
                                          'nama': namaController.text.trim(),
                                          'no_telp':
                                              noTelpController.text.trim(),
                                          'role': 'master', // ✅ pemilik laundry
                                          'owner_id':
                                              uid, // ✅ menunjuk dirinya sendiri
                                          'created_at':
                                              DateTime.now().toIso8601String(),
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
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(),
                                      ),
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

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                },

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

                    // Already have account text
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
}
