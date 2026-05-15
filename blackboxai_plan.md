# Edit plan (approved before edits)

## Information gathered
- `flutter analyze` reports many issues, but the compile-stopping ones are:
  1) `packages/monitoring_repository/lib/src/models/evaporasi.dart` contains unresolved git merge conflict markers (`<<<<<<< HEAD`, `=======`, `>>>>>>> ...`) and thus causes syntax errors and incorrect factory return type/assignments.
  2) `packages/user_repository/lib/src/firebase_user_repo.dart` cannot resolve `package:google_sign_in/google_sign_in.dart` and related symbols (`GoogleSignIn`, `GoogleSignInAuthentication`).
- Read `evaporasi.dart`: conflict markers exist inside `Evaporasi.fromJson`, causing broken code.
- Read `firebase_user_repo.dart`: it imports `package:google_sign_in/google_sign_in.dart` and uses `GoogleSignIn`, `GoogleSignInAuthentication`.
- Read `packages/monitoring_repository/pubspec.yaml`: no `google_sign_in` dependency there (likely only in user_repository).
- Read `packages/user_repository/pubspec.yaml`: `google_sign_in: ^6.3.0` is present.
- `search_files` for conflict markers returned none (likely because pattern needs exact marker search or repo search mismatch), but reading the file shows markers are present.

## Plan
### Step A — Fix evaporasi.dart merge conflict
- Edit `packages/monitoring_repository/lib/src/models/evaporasi.dart`:
  - Remove all `<<<<<<< HEAD`, `=======`, `>>>>>>> ...` markers.
  - Consolidate timestamp parsing:
    - Keep a robust `parseTimestamp(dynamic raw)` helper.
    - Use one `rawTimestamp` priority order: `json['timestamp'] ?? json['time'] ?? json['datetime']`.
    - Keep legacy fallback from `json['waktu']` (HH:mm:ss) if other timestamp fields are missing.
  - Keep filtering for evaporasi (0..50) and tinggiAir (0..100) and sensor sanity for suhu (-50..100).
  - Ensure `factory Evaporasi.fromJson(...)` always returns an `Evaporasi` with a non-null `timestamp`.

### Step B — Fix google_sign_in missing import/class errors
Because `google_sign_in` is declared but analyzer can't find the Dart library:
- Check whether the dependency actually downloaded/available. The simplest fix path is:
  - Run `flutter pub get` correctly (Windows shell issue is present: `&&` is not valid in the terminal context).
  - Re-run `flutter analyze` to see if the missing import resolves.
- If still failing:
  - Inspect `packages/user_repository/pubspec.lock` / ensure plugin supports current platform (and that the package name/dart import matches).
  - Update `google_sign_in` version to a compatible one if necessary.

### Step C — Re-run analyze
- After Step A and Step B, run `flutter analyze` again and fix any remaining compile errors.

## Dependent files to edit
- `packages/monitoring_repository/lib/src/models/evaporasi.dart`
- Potentially `packages/user_repository/pubspec.yaml` (only if dependency resolution still fails)

## Followup steps
- Run `flutter pub get` (from `c:/flutter/klimatologi`).
- Run `flutter analyze` again.
- If compile succeeds, optionally address warnings (prefer_const_constructors, deprecated withOpacity, Share -> SharePlus, etc.).

<ask_followup_question>
Approve Step A (remove merge conflict and fix timestamp parsing in evaporasi.dart). After that I will proceed to Step B (google_sign_in resolution) based on the next analyze output.
</ask_followup_question>

