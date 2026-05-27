// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Web: langsung trigger download lewat browser
Future<void> saveAndShareExcel(Uint8List bytes, String fileName) async {
  final blob = html.Blob(
    [bytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create a hidden anchor, set download attr and append to document
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  // Append to DOM so some browsers respect the download attribute
  html.document.body?.append(anchor);

  // Dispatch click — this should trigger a single download with correct name
  anchor.click();

  // Clean up: remove anchor and revoke URL after a short delay to ensure download starts
  anchor.remove();
  await Future.delayed(const Duration(milliseconds: 500));
  html.Url.revokeObjectUrl(url);
}
