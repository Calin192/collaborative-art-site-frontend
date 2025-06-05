import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/paint/presentation/pages/drawing_page.dart';
import 'package:flutter_drawing_board/subgallery/getImages.dart';
import 'package:flutter_drawing_board/subgallery/subtree_gallery_page.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> images = [];
  bool isLoading = false;

  Future<void> fetchImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:8080/getAllImages'));
      if (response.statusCode == 200) {
        final Map<String, String> data = Map<String, String>.from(jsonDecode(response.body));
        setState(() {
          images = data.entries
              .map((entry) => {'filename': entry.key, 'imageData': entry.value})
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load images');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.grey[200],
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DrawingPage()),
                    );
                  },
                  child: const Text('New Painting'),
                ),
                ElevatedButton(
                  onPressed: fetchImages,
                  child: const Text('Get Images'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : images.isEmpty
                  ? const Center(child: Text('No images to display'))
                  : GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of columns
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  final Uint8List imageBytes = base64Decode(image['imageData']);
                  return GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black54,
                      title: Text(
                        image['filename'],
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final selectedPath = image['filename'];
                        final subtreeImages = await fetchImagesFromRoot(selectedPath);
                        if (subtreeImages.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SubtreeGalleryPage(rootPath: selectedPath),
                            ),
                          );
                        }
                      },

                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    ),

                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}