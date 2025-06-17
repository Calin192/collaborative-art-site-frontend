import 'package:http/http.dart' as http;

Future<void> sendAccessRequestMultipart({required String drawingPath, required String username}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8080/requestAccess'),
  );

  request.fields['drawingPath'] = drawingPath;
  request.fields['fromUser'] = username;

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Access request sent successfully.');
  } else if (response.statusCode == 409) {
    throw Exception('already_participant');
  } else {
    throw Exception('request_failed with status: ${response.statusCode}');
  }
}
