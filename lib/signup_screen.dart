import 'package:admin_er/account_type.dart';
import 'package:admin_er/plain_background.dart';
import 'package:admin_er/textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController enrollmentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Add Firestore instance
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // ... (keep existing validation checks)

      // Perform signup
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save enrollment number and email in Firestore
      String enrollmentNumber = enrollmentController.text.trim();
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'enrollment_number': enrollmentNumber,
        'email': emailController.text.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Show success message and navigate to fresh signup screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student registered successfully")),
      );

      // Clear the text fields
      emailController.clear();
      passwordController.clear();
      enrollmentController.clear();

      // Navigate to fresh signup screen (same screen, but cleared)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignupScreen()),
      );
    } catch (e) {
      // Handle signup error
      if (e is FirebaseAuthException) {
        // ... (keep existing error handling)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
      // Show "Try again" message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration failed. Please try again.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration"),
      ),
      backgroundColor: const Color(0xFF5D83C6),
      body: SafeArea(
        child: Stack(
          children: [
            const PlainBackground(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container with white background for the image
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white, // White background
                      borderRadius:
                          BorderRadius.circular(20), // Rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/matbuck.jpg', // Ensure correct path
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Enrollment Number field
                  CommonTextField(
                    controller: enrollmentController,
                    hintText: "Enrollment Number",
                    textStyle: const TextStyle(color: Colors.white),
                    hintTextStyle: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  CommonTextField(
                    controller: emailController,
                    hintText: "Email",
                    textStyle: const TextStyle(color: Colors.white),
                    hintTextStyle: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  CommonTextField(
                    controller: passwordController,
                    isPassword: true,
                    hintText: "Password",
                    obscureText: true,
                    textStyle: const TextStyle(color: Colors.white),
                    hintTextStyle: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _signup,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text("Sign Up"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountType()));
                    },
                    child: Text(
                      'Back to accout type?',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
