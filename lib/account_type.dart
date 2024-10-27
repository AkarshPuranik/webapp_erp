import 'package:admin_er/event.dart';
import 'package:admin_er/event_screen.dart';
import 'package:admin_er/fee_dues.dart';
import 'package:admin_er/signup_screen.dart';
import 'package:admin_er/teacher_create_account.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class AccountType extends StatefulWidget {
  const AccountType({super.key});

  @override
  State<AccountType> createState() => _AccountTypeState();
}

class _AccountTypeState extends State<AccountType> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Type'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: Duration(seconds: 2),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                        height: 200,
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/download.png'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '-----or-----',
                    style: TextStyle(color: Colors.black, fontSize: 40),
                  ),
                  const SizedBox(height: 10),
                  ZoomIn(
                    duration: Duration(seconds: 2),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TeacherCreateAccount()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 3,
                          ),
                        ),
                        height: 200,
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/8065183.png'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInRight(
                    duration: Duration(seconds: 2),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventCreationPage()),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      label: const Text(
                        'Post events',
                        style: TextStyle(color: Colors.black),
                      ),
                      icon: const Icon(
                        Icons.event,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInLeft(
                    duration: Duration(seconds: 2),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SendFeeScreen()),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red),
                      ),
                      label: const Text(
                        'Fee Receipt',
                        style: TextStyle(color: Colors.black),
                      ),
                      icon: const Icon(
                        Icons.credit_score,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
