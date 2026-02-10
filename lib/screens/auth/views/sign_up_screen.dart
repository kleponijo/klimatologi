import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../components/my_text_field.dart';
import '../blocs/sign_up_bloc/sign_up_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            setState(() {
              signUpRequired = false;
            });
          } else if (state is SignUpProcess) {
            setState(() {
              signUpRequired = true;
            });
          } else if (state is SignUpFailure) {
            return;
          }
        },
        child: Form(
          key: _formKey,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.92,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
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
                          const SizedBox(height: 14),

                          // Name
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: MyTextField(
                              controller: nameController,
                              hintText: 'Masukkan nama lengkap',
                              obscureText: false,
                              keyboardType: TextInputType.name,
                              prefixIcon: const Icon(CupertinoIcons.person_fill),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please fill in this field';
                                } else if (val.length > 50) {
                                  return 'Name too long';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Email
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: MyTextField(
                              controller: emailController,
                              hintText: 'nama@email.com',
                              obscureText: false,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(CupertinoIcons.mail_solid),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please fill in this field';
                                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Password
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: MyTextField(
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
                                  return 'Please fill in this field';
                                } else if (val.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Confirm Password
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: MyTextField(
                              controller: confirmPasswordController,
                              hintText: 'Ulangi password',
                              obscureText: obscurePassword,
                              keyboardType: TextInputType.visiblePassword,
                              prefixIcon: const Icon(CupertinoIcons.lock_fill),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please fill in this field';
                                } else if (val != passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Button
                          !signUpRequired
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.92,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        MyUser myUser = MyUser.empty;
                                        myUser.email = emailController.text;
                                        myUser.name = nameController.text;

                                        setState(() {
                                          context.read<SignUpBloc>().add(
                                                SignUpRequired(
                                                  myUser,
                                                  passwordController.text,
                                                ),
                                              );
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Daftar',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                              : const CircularProgressIndicator(),

                          const SizedBox(height: 12),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Sudah punya akun? '),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Login di sini'),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}