import 'package:http/http.dart' as http;

Future<void> respondToAccessRequestMultipart({
  required String drawingName,
  required String fromUser,
  required bool accept,
}) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8080/respondToRequest'),
  );

  request.fields['drawingName'] = drawingName;
  request.fields['fromUser'] = fromUser;
  request.fields['accept'] = accept.toString(); // trimitem boolean ca string

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Response processed successfully.');
  } else if (response.statusCode == 409) {
    throw Exception('Conflict: already processed.');
  } else {
    throw Exception('Request failed with status: ${response.statusCode}');
  }
}
