import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/paint/presentation/pages/drawing_page.dart';
import 'package:flutter_drawing_board/requests.dart';
import 'package:flutter_drawing_board/subgallery/getImages.dart';
import 'package:flutter_drawing_board/subgallery/respondRequest.dart';
import 'package:flutter_drawing_board/subgallery/subtree_gallery_page.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.username});
  final String username;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> images = [];
  bool isLoading = false;

  List<Request> requests = [];
  bool isLoadingRequests = false;

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

  Future<void> fetchUserRequests() async {
    setState(() {
      isLoadingRequests = true;
    });
    try {
      print('Fetching requests for user: ${widget.username}');
      final fetchedRequests = await fetchRequests(widget.username);
      setState(() {
        requests = fetchedRequests;
        isLoadingRequests = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRequests = false;
      });
      print('Error fetching requests: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImages();
    fetchUserRequests();
  }

  void _showDecisionDialog(Request request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Access'),
        content: Text('User "${request.username}" requests access to drawing: "${request.drawingPath}". Accept?'),
        actions: [
          TextButton(
            onPressed: () async {

              try {
                await respondToAccessRequestMultipart(
                drawingName: request.drawingPath,
                fromUser: request.username,
                accept: true,
                );
                print('Request accepted!');
              } catch (e) {
                print('Error: $e');
              }

              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: API call to deny request
              try {
                await respondToAccessRequestMultipart(
                  drawingName: request.drawingPath,
                  fromUser: request.username,
                accept: false,
                );
                print('Request accepted!');
              } catch (e) {
                print('Error: $e');
              }

              Navigator.of(context).pop();
            },
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}'),
      ),
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
                      MaterialPageRoute(builder: (context) => DrawingPage(parentPath: null, tempPath: null, username: widget.username)),
                    );
                  },
                  child: const Text('New Painting'),
                ),
                ElevatedButton(
                  onPressed: fetchImages,
                  child: const Text('Get Images'),
                ),
                const Divider(),

                // Aici am adăugat ROW-ul cu titlu Requests și buton refresh
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Requests',
                        onPressed: fetchUserRequests,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoadingRequests
                      ? const Center(child: CircularProgressIndicator())
                      : requests.isEmpty
                      ? const Center(child: Text('No requests'))
                      : ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return ListTile(
                        title: Text(req.drawingPath),
                        subtitle: Text('From user: ${req.username}'),
                        onTap: () => _showDecisionDialog(req),
                      );
                    },
                  ),
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
                  : RefreshIndicator(
                onRefresh: fetchImages,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
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
                                        builder: (_) => SubtreeGalleryPage(
                                          rootPath: selectedPath,
                                          username: widget.username,
                                        ),
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
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
