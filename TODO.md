# TODO - Fix flutter analyze issues

## Step 1: Fix evaporasi.dart parse conflict
- Remove leftover git conflict markers in packages/monitoring_repository/lib/src/models/evaporasi.dart
- Unify timestamp parsing logic into a single implementation
- Ensure `factory Evaporasi.fromJson` always returns a non-null `Evaporasi`

## Step 2: Fix Google Sign-In import errors
- Investigate why `package:google_sign_in/google_sign_in.dart` is reported missing
- Update user_repository dependency versions if needed
- Run `flutter pub get` (from c:/flutter/klimatologi) and `flutter analyze` again

## Step 3: Re-run analyze and address remaining warnings
- Run `flutter analyze` and fix any remaining compile errors
- Optionally clean up performance/deprecation warnings (const constructors, withOpacity deprecation, Share->SharePlus)

