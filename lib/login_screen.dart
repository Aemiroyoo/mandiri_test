import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // untuk menghindari error overflow
      backgroundColor: Color(0xFF00224F), // Warna dari Figma
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Teks Selamat Datang
            Text(
              "Hello, Welcome Back",
              style: TextStyle(
                fontSize: 27,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Welcome back, please\nsign in again",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 70),

            // Input Email
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Input Password
            TextField(
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 30),

            // Tombol Login
            ElevatedButton(
              onPressed: () {
                print("Login button pressed");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 17,
                  color: const Color.fromARGB(255, 0, 34, 79),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            SizedBox(height: 60),

            // Garis dan Teks "or"
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: const Color.fromARGB(68, 255, 255, 255),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "or",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: const Color.fromARGB(68, 255, 255, 255),
                    thickness: 1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Tombol Login dengan Facebook
            SocialLoginButton(
              icon: FontAwesomeIcons.facebook,
              text: "Facebook",
              color: Colors.blue.shade800,
              onPressed: () {
                print("Login with Facebook");
              },
            ),

            SizedBox(height: 10),

            // Tombol Login dengan Gmail
            SocialLoginButton(
              icon: FontAwesomeIcons.google,
              text: "Gmail",
              color: Colors.red.shade700,
              onPressed: () {
                print("Login with Google");
              },
            ),

            SizedBox(height: 10),

            // Teks "Already have an account? Sign In"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account?",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                TextButton(
                  onPressed: () {
                    print("Navigate to Sign In screen");
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Tombol Social Login
class SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const SocialLoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: FaIcon(icon, color: Colors.white),
      label: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
