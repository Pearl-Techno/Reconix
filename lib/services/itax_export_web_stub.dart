import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

String? downloadFileWeb(dynamic content, String fileName) {
  if (kIsWeb) return null;

  try {
    Directory? docsDir;

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final oneDriveDocs = Directory(p.join(userProfile, 'OneDrive', 'Documents'));
        if (oneDriveDocs.existsSync()) {
          docsDir = Directory(p.join(oneDriveDocs.path, 'Reconix'));
        } else {
          docsDir = Directory(p.join(userProfile, 'Documents', 'Reconix'));
        }
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        docsDir = Directory(p.join(home, 'Documents', 'Reconix'));
      }
    }

    docsDir ??= Directory(p.join(Directory.current.path, 'Documents', 'Reconix'));

    if (!docsDir.existsSync()) {
      docsDir.createSync(recursive: true);
    }

    final filePath = p.join(docsDir.path, fileName);
    final file = File(filePath);

    if (content is String) {
      file.writeAsStringSync(content);
    } else if (content is List<int>) {
      file.writeAsBytesSync(content);
    } else if (content is Uint8List) {
      file.writeAsBytesSync(content);
    }

    debugPrint('Export file successfully saved to: $filePath');
    return filePath;
  } catch (e) {
    debugPrint('Error saving export file to Documents/Reconix: $e');
    return null;
  }
}

void openExternalUrl(String url) {
  // Non-web fallback stub for VM unit tests
}
