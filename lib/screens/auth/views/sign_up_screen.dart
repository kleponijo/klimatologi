import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

import '../../../components/my_text_field.dart';
import '../blocs/sign_up_bloc/sign_up_bloc.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onSignInTap;
  const SignUpScreen({super.key, this.onSignInTap});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IconData iconPassword = CupertinoIcons.eye_fill;
  bool obscurePassword = true;
  bool signUpRequired = false;
  // FIX: Hapus 5 variabel password strength yang tidak dipakai

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state is SignUpProcess) {
          setState(() => signUpRequired = true);
        } else if (state is SignUpFailure) {
          setState(() => signUpRequired = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is SignUpSuccess) {
          setState(() => signUpRequired = false);
        }
      },
      // FIX: Hapus Scaffold — WelcomeScreen sudah punya Scaffold
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Buat Akun',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Daftar untuk mulai monitoring',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),

              // Nama
              MyTextField(
                controller: nameController,
                hintText: 'Masukkan nama lengkap',
                obscureText: false,
                keyboardType: TextInputType.name,
                prefixIcon: const Icon(CupertinoIcons.person_fill),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Mohon isi field ini';
                  }
                  if (val.length > 50) return 'Nama terlalu panjang';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Email
              MyTextField(
                controller: emailController,
                hintText: 'nama@email.com',
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(CupertinoIcons.mail_solid),
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
              const SizedBox(height: 10),

              // Password
              MyTextField(
                controller: passwordController,
                hintText: 'Minimal 6 karakter',
                obscureText: obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                prefixIcon: const Icon(CupertinoIcons.lock_fill),
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
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Mohon isi field ini';
                  }
                  // FIX: tambah validasi panjang minimum
                  if (val.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Confirm Password
              MyTextField(
                controller: confirmPasswordController,
                hintText: 'Ulangi password',
                obscureText: obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                prefixIcon: const Icon(CupertinoIcons.lock_fill),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Mohon isi field ini';
                  }
                  if (val != passwordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Tombol Sign Up
              Center(
                child: !signUpRequired
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // FIX: buat MyUser langsung, jangan mutasi MyUser.empty
                              final myUser = MyUser(
                                userId: '',
                                email: emailController.text.trim(),
                                name: nameController.text.trim(),
                                hasActiveCart: false,
                              );

                              // FIX: add() dipanggil di luar setState
                              context.read<SignUpBloc>().add(
                                    SignUpRequired(
                                        myUser, passwordController.text),
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(60),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 5),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? '),
                  TextButton(
                    onPressed: widget.onSignInTap,
                    child: const Text(
                      'Login di sini',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
