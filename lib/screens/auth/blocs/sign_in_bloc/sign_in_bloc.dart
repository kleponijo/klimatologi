import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:user_repository/user_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final UserRepository _userRepository;

  SignInBloc(this._userRepository) : super(SignInInitial()) {
    on<SignInRequired>((event, emit) async {
      emit(SignInProcess());
      try {
        await _userRepository.signIn(event.email, event.password);
        emit(SignInSuccess());
      } catch (e) {
        emit(SignInFailure());
      }
    });

    on<GoogleSignInRequired>((event, emit) async {
      emit(SignInProcess());
      try {
        final didSignIn = await _userRepository.signInWithGoogle();
        if (didSignIn) {
          emit(SignInSuccess());
        } else {
          emit(SignInInitial());
        }
      } catch (e) {
        emit(SignInFailure());
      }
    });
  }
}
