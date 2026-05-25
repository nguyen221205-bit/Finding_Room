import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalImageService {
  static Future<String> copyToAppStorage({
    required String sourcePath,
    required String folderName,
  }) async {
    final File sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return sourcePath;
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory imageDir = Directory('${appDir.path}/$folderName');
    if (!imageDir.existsSync()) {
      imageDir.createSync(recursive: true);
    }

    final String extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final String fileName =
        'img_${DateTime.now().microsecondsSinceEpoch}$extension';
    final File savedFile = await sourceFile.copy('${imageDir.path}/$fileName');
    return savedFile.path;
  }
}
