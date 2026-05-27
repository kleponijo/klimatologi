import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile (Android/iOS): simpan ke temp dir lalu buka share sheet
Future<void> saveAndShareExcel(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  // Wait a short moment to ensure filesystem has flushed and other apps can access file
  await Future.delayed(const Duration(milliseconds: 150));

  // Provide the name to XFile so receiving apps can preserve the filename
  await Share.shareXFiles(
    [
      XFile(
        file.path,
        name: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
    ],
    subject: fileName,
  );
}
