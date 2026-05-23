import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:user_repository/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  final UserRepository _userRepository;

  SignUpBloc(this._userRepository) : super(SignUpInitial()) {
    on<SignUpRequired>((event, emit) async {
      emit(SignUpProcess());
      try {
        await _userRepository.signUp(event.user, event.password);
        emit(SignUpSuccess());
      } catch (e) {
        String message = 'Terjadi kesalahan. Coba lagi.';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              message = 'Email sudah terdaftar.';
              break;
            case 'weak-password':
              message = 'Password terlalu lemah.';
              break;
            case 'invalid-email':
              message = 'Format email tidak valid.';
              break;
          }
        }
        emit(SignUpFailure(message));
      }
    });
  }
}

// 2 / 5
