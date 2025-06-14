import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, String>> fetchImagesFromRoot(String rootPath) async {
  final String url = 'http://localhost:8080/getImagesFromRoot?rootPath=$rootPath';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      return jsonResponse.map((key, value) => MapEntry(key, value.toString()));
    } else {
      throw Exception('Failed to load images for root: $rootPath');
    }
  } catch (e) {
    print('Error fetching images from root: $e');
    return {};
  }
}

