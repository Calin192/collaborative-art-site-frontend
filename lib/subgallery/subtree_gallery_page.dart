import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/subgallery/findImagePathInTree.dart';
import 'package:flutter_drawing_board/subgallery/requestAccess.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_drawing_board/subgallery/saveBytes.dart';
import 'package:path_provider/path_provider.dart';

import '../paint/presentation/pages/drawing_page.dart';

class TreeNode {
  final String path;
  final List<TreeNode> children;

  TreeNode({required this.path, required this.children});

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      path: json['path'],
      children: (json['children'] as List<dynamic>)
          .map((childJson) => TreeNode.fromJson(childJson))
          .toList(),
    );
  }
}

class SubtreeGalleryPage extends StatefulWidget {
  final String rootPath;
  final String username;
  const SubtreeGalleryPage({super.key, required this.rootPath, required this.username});

  @override
  State<SubtreeGalleryPage> createState() => _SubtreeGalleryPageState();
}

class _SubtreeGalleryPageState extends State<SubtreeGalleryPage> {
  Map<String, String> images = {};
  TreeNode? rootTree;
  bool isLoading = true;
  late Map<String, dynamic> treeJson;

  late String treeUrl;

  @override
  void initState() {
    super.initState();
    _loadImagesAndTree();
  }

  Future<void> _loadImagesAndTree() async {
    final String imagesUrl = 'http://localhost:8080/getImagesFromRoot?rootPath=${widget.rootPath}';
    treeUrl = 'http://localhost:8080/getTreeStructure?rootPath=${widget.rootPath}';

    try {
      final imagesResponse = await http.get(Uri.parse(imagesUrl));
      final treeResponse = await http.get(Uri.parse(treeUrl));

      if (imagesResponse.statusCode == 200 && treeResponse.statusCode == 200) {
        final Map<String, dynamic> imagesJson = json.decode(imagesResponse.body);
        final Map<String, String> imagesStringMap = imagesJson.map((key, value) => MapEntry(key, value.toString()));

        treeJson = json.decode(treeResponse.body);

        // Adaugă un print pentru a verifica structura JSON-ului
        print('Tree JSON: ${json.encode(treeJson)}');

        final TreeNode tree = TreeNode.fromJson(treeJson);
        setState(() {
          images = imagesStringMap;
          rootTree = tree;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images or tree');
      }
    } catch (e) {
      print('Error fetching images or tree: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subtree Images')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rootTree == null
          ? const Center(child: Text('No tree found.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: _TreeNodeWidget(
          node: rootTree!,
          images: images,
          treeJson: treeJson,
          username: widget.username,
          onRefresh: _loadImagesAndTree,
        ),
      ),
    );
  }
}

class _TreeNodeWidget extends StatefulWidget {
  final TreeNode node;
  final Map<String, String> images;
  final Map<String, dynamic> treeJson;
  final String username;
  final Future<void> Function()? onRefresh; // Add callback for refresh

  const _TreeNodeWidget({
    Key? key,
    required this.node,
    required this.images,
    required this.treeJson,
    required this.username,
    this.onRefresh, // Initialize callback
  }) : super(key: key);

  @override
  State<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<_TreeNodeWidget> {
  final GlobalKey parentKey = GlobalKey();
  final List<GlobalKey> childrenKeys = [];


  @override
  void didUpdateWidget(covariant _TreeNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.children.length != childrenKeys.length) {
      childrenKeys.clear();
      childrenKeys.addAll(List.generate(widget.node.children.length, (_) => GlobalKey()));
    }
  }


  Map<String, dynamic>? _findRawNodeByPath(Map<String, dynamic> node, String targetPath) {
    if (node['path'] == targetPath) return node;
    if (node['children'] == null) return null;

    for (var child in node['children']) {
      final result = _findRawNodeByPath(child, targetPath);
      if (result != null) return result;
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final imageData = widget.images[widget.node.path];
    Uint8List? bytes;
    if (imageData != null) {
      try {
        bytes = base64Decode(imageData);
      } catch (e) {
        print('Error decoding image for ${widget.node.path}: $e');
      }
    }

    String imageName = widget.node.path.split('/').last;

    // Get participants for this node
    List<String> usernamesList = [];
    try {
      final nodeRawJson = _findRawNodeByPath(widget.treeJson, widget.node.path);
      if (nodeRawJson != null &&
          nodeRawJson['drawing'] != null &&
          nodeRawJson['drawing']['username'] != null) {
        usernamesList = List<String>.from(nodeRawJson['drawing']['username']);
      }
    } catch (_) {}

    String usernames = usernamesList.isNotEmpty ? usernamesList.join(', ') : 'unknown';

    final childrenWidgets = <Widget>[];
    for (int i = 0; i < widget.node.children.length; i++) {
      final key = (i < childrenKeys.length) ? childrenKeys[i] : GlobalKey();

      childrenWidgets.add(_TreeNodeWidget(
        node: widget.node.children[i],
        images: widget.images,
        key: key,
        treeJson: widget.treeJson,
        username: widget.username,
      ));
    }


    return Container(
      margin: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LinesPainter(
                    parentKey: parentKey,
                    childrenKeys: childrenKeys,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        String? resolvedPath = await findImagePathInTree(widget.treeJson, imageName);
                        if (resolvedPath != null && bytes != null) {
                          List<String> allowedUsers = [];
                          try {
                            final rootNode = _findRawNodeByPath(widget.treeJson, widget.treeJson['path']);
                            if (rootNode != null &&
                                rootNode['drawing'] != null &&
                                rootNode['drawing']['username'] != null) {
                              allowedUsers = List<String>.from(rootNode['drawing']['username']);
                            }
                          } catch (_) {}

                          if (!allowedUsers.contains(widget.username)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You are not allowed to access this image.')),
                            );
                            return;
                          }

                          final tempFilePath = await saveImageTemporarily(bytes, imageName);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DrawingPage(
                                tempPath: tempFilePath,
                                parentPath: resolvedPath,
                                username: widget.username,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not resolve image path or image data is null')),
                          );
                        }
                      },
                      child: Container(
                        key: parentKey,
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            if (bytes != null)
                              Image.memory(bytes, width: 80, height: 80, fit: BoxFit.contain),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$imageName by $usernames',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Buttons for request access and refresh
                    if (widget.node.path == widget.treeJson['path'])
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  print('Sending access request for ${widget.node.path} by ${widget.username}');
                                  await sendAccessRequestMultipart(
                                    drawingPath: widget.node.path,
                                    username: widget.username,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Request sent')),
                                  );
                                } catch (e) {
                                  if (e.toString().contains('already_participant')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You are already a participant.')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error sending request')),
                                    );
                                  }
                                }
                              },
                              child: const Text("Request Access"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (widget.onRefresh != null) {
                                  try {
                                    await widget.onRefresh!(); // Call the refresh method
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Images refreshed')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error refreshing images')),
                                    );
                                  }
                                }
                              },
                              child: const Text("Refresh"),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (childrenWidgets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: childrenWidgets,
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _LinesPainter extends CustomPainter {
  final GlobalKey parentKey;
  final List<GlobalKey> childrenKeys;

  _LinesPainter({required this.parentKey, required this.childrenKeys});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    final RenderBox? parentBox = parentKey.currentContext?.findRenderObject() as RenderBox?;
    if (parentBox == null) return;

    final parentSize = parentBox.size;

    final parentTopLeftGlobal = parentBox.localToGlobal(Offset.zero);

    final parentOffsetInCanvas = parentBox.globalToLocal(parentTopLeftGlobal);

    if (childrenKeys.isEmpty) return;

    List<Offset> childrenPositionsInCanvas = [];
    for (var key in childrenKeys) {
      final RenderBox? childBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (childBox == null) continue;

      final childTopLeftGlobal = childBox.localToGlobal(Offset.zero);
      final childOffsetInCanvas = parentBox.globalToLocal(childTopLeftGlobal);
      childrenPositionsInCanvas.add(childOffsetInCanvas);
    }

    if (childrenPositionsInCanvas.isEmpty) return;


    double x = parentOffsetInCanvas.dx;
    double topY = parentOffsetInCanvas.dy + parentSize.height;
    double bottomY = childrenPositionsInCanvas.map((e) => e.dy).reduce((a, b) => a < b ? a : b);


    canvas.drawLine(Offset(x, topY), Offset(x, bottomY), paint);


    for (var childPos in childrenPositionsInCanvas) {
      double childX = childPos.dx;
      double childY = childPos.dy + 20;
      canvas.drawLine(Offset(x, childY), Offset(childX, childY), paint);
    }
  }


  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return oldDelegate.parentKey != parentKey || oldDelegate.childrenKeys != childrenKeys;
  }
}
