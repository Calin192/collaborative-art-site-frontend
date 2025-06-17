import 'dart:convert';
import 'package:http/http.dart' as http;

class Request {
  final String username;
  final String drawingPath;

  Request({required this.username, required this.drawingPath});

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      username: json['fromUser'] ?? 'unknown',
      drawingPath: json['drawingName'] ?? 'unknown',
    );
  }

}



Future<List<Request>> fetchRequests(String username) async {
  final uri = Uri.parse('http://localhost:8080/requests?username=$username');

  final response = await http.get(uri);
  print("Response body: ${response.body}");

  if (response.statusCode == 200) {
    List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Request.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load requests');
  }
}

