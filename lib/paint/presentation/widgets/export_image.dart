import 'dart:typed_data';
import 'package:http/http.dart' as http;


Future<void> uploadImage(Uint8List imageBytes,String parentPath,String name, String usernames, String description) async {

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:8080/upload'),
  );
  //numele la fisier e si path :P
  request.files.add(http.MultipartFile.fromBytes(
    'image',
    imageBytes,
    filename: '$name.png',
  ));


  request.fields['parentPath'] = parentPath;

  request.fields['imageName'] = name;

  List<String> usernamesList = usernames.split(',');

  request.fields['usernames'] = usernamesList.join(',');

  request.fields['description'] = description;

  print("in upload image $parentPath");

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Image uploaded successfully');
  } else {
    print('Upload failed with status: ${response.statusCode}');
  }
}