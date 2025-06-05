import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../main.dart';

Future<void> uploadImage(Uint8List imageBytes, ) async {
  // Creează cererea HTTP pentru upload
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8080/upload'), // backend URL
  );

  // Adaugă fișierul direct din bytes
  request.files.add(http.MultipartFile.fromBytes(
    'image',
    imageBytes,
    filename: 'image.png',
  ));

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Image uploaded successfully');
  } else {
    print('Upload failed with status: ${response.statusCode}');
  }
}