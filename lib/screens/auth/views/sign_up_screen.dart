import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../components/my_text_field.dart';
import '../blocs/sign_up_bloc/sign_up_bloc.dart' as signUp;
// import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import '../blocs/sign_in_bloc/sign_in_bloc.dart' as signIn;

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

  bool containsUpperCase = false;
  bool containsLowerCase = false;
  bool containsNumber = false;
  bool containsSpecialChar = false;
  bool contains8Length = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<signUp.SignUpBloc, signUp.SignUpState>(
      listener: (context, state) {
        if (state is signUp.SignUpProcess) {
          setState(() {
            signUpRequired = true;
          });
        } else if (state is signUp.SignUpFailure) {
          setState(() {
            signUpRequired = false; // Matikan loading!
          });
          // Tampilkan pesan error lewat Snackbar biar user tahu kenapa gagal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message ?? 'An error ocurred'),
                backgroundColor: Colors.red),
          );
        } else if (state is signUp.SignUpSuccess) {
          setState(() {
            signUpRequired = false;
          });
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
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
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Daftar untuk mulai monitoring',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
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

                        /// == Sign Up == ///
                        // Button
                        !signUpRequired
                            ? Center(
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        MyUser myUser = MyUser.empty;
                                        myUser.email = emailController.text;
                                        myUser.name = nameController.text;

                                        setState(() {
                                          context.read<signUp.SignUpBloc>().add(
                                                signUp.SignUpRequired(
                                                  myUser,
                                                  passwordController.text,
                                                ),
                                              );
                                        });
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 25, vertical: 5),
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const CircularProgressIndicator(),

                        const SizedBox(height: 12),
                        Center(
                          child: Text('Atau'),
                        ),

                        const SizedBox(height: 12),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Sudah punya akun? '),
                              TextButton(
                                onPressed: () {
                                  widget.onSignInTap?.call();
                                },
                                child: const Text(
                                  'Login di sini',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
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
