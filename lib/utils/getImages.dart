import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchImagesWithCount() async {
  const String url = "http://localhost:8080/getAllImages";

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Decode the JSON response into a Map
      Map<String, String> images = Map<String, String>.from(json.decode(response.body));
      int imageCount = images.length;

      return {
        'images': images,
        'count': imageCount,
      };
    } else {
      throw Exception('Failed to load images. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching images: $e');
  }
}

