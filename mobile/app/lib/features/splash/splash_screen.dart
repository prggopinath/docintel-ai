import 'dart:async';

import 'package:flutter/material.dart';

import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(
      const Duration(seconds: 3),
      () {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );

      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff2563EB),

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(

              height: 120,

              width: 120,

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(30),

              ),

              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xff2563EB),
                size: 70,
              ),

            ),

            const SizedBox(height: 40),

            const Text(

              "DocIntel AI",

              style: TextStyle(

                color: Colors.white,

                fontSize: 34,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 15),

            const Text(

              "Turn Documents into Intelligence",

              style: TextStyle(

                color: Colors.white70,

                fontSize: 18,

              ),

            ),

            const SizedBox(height: 50),

            const CircularProgressIndicator(
              color: Colors.white,
            ),

          ],

        ),

      ),

    );
  }
}