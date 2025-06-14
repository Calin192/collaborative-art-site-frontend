import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveImageTemporarily(Uint8List bytes, String fileName) async {
  // Obține directorul temporar
  final tempDir = await getTemporaryDirectory();

  // Creează calea completă
  final filePath = '${tempDir.path}/$fileName';

  // Scrie fișierul în directorul temporar
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);

  return filePath; // Returnează calea unde s-a salvat temporar
}
