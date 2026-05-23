import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/my_text_field.dart';
import '../blocs/sign_in_bloc/sign_in_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool signInRequired = false;
  IconData iconPassword = CupertinoIcons.eye_fill;
  bool obscurePassword = true;
  String? _errorMsg;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state is SignInProcess) {
          setState(() => signInRequired = true);
        } else {
          setState(() => signInRequired = false);

          if (state is SignInFailure) {
            setState(() => _errorMsg = 'Email atau password salah. Coba lagi.');
          } else if (state is SignInSuccess) {
            setState(() => _errorMsg = null);
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Email field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(CupertinoIcons.mail_solid),
                  // FIX: tidak lagi pass errorMsg ke field individual
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Mohon isi field ini';
                    }
                    // FIX: tambah validasi format email
                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(val)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Password field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  prefixIcon: const Icon(CupertinoIcons.lock_fill),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Mohon isi field ini';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                        iconPassword = obscurePassword
                            ? CupertinoIcons.eye_fill
                            : CupertinoIcons.eye_slash_fill;
                      });
                    },
                    icon: Icon(iconPassword),
                  ),
                ),
              ),

              // FIX: Error message satu baris di bawah kedua field
              if (_errorMsg != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // FIX: Tombol Sign In dan Google dinonaktifkan saat loading
              if (!signInRequired) ...[
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<SignInBloc>().add(SignInRequired(
                            emailController.text, passwordController.text));
                      }
                    },
                    style: TextButton.styleFrom(
                      elevation: 3.0,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60)),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                      child: Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // // Tombol Google — hanya muncul ketika tidak loading
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<SignInBloc>().add(GoogleSignInRequired());
                    },
                    icon: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        'images/google-icon-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    label: const Text(
                      'Sign In with Google',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      elevation: 3.0,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ] else
                const CircularProgressIndicator(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
