import 'package:fanikisha_app/screens/authetication/forget_password/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// this the screen for resetting password using email after user has selected reset
// password option using email
class ForgetPasswordMailScreen extends StatelessWidget {
  const ForgetPasswordMailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 180.0,
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.email_outlined,
                    size: 100.0,
                  ),
                ),
                const Text(
                  "RESET PASSWORD",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15.0),
                const Text(
                  "Enter Your Registered E-mail to reset Your Password",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28.0),
                Form(
                  child: Column(
                    children: [
                      //   email text field
                      const TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 28.0),

                      //   next button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                          //   go to otp screen to enter sent codes
                            Get.to(()=> OTPScreen() );
                          },
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
