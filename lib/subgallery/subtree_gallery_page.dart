import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/subgallery/findImagePathInTree.dart';
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

  const SubtreeGalleryPage({super.key, required this.rootPath});

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
    this.treeUrl = 'http://localhost:8080/getTreeStructure?rootPath=${widget.rootPath}';

    try {
      final imagesResponse = await http.get(Uri.parse(imagesUrl));
      final treeResponse = await http.get(Uri.parse(this.treeUrl));

      if (imagesResponse.statusCode == 200 && treeResponse.statusCode == 200) {
        final Map<String, dynamic> imagesJson = json.decode(imagesResponse.body);
        final Map<String, String> imagesStringMap = imagesJson.map((key, value) => MapEntry(key, value.toString()));

        this.treeJson = json.decode(treeResponse.body);
        final TreeNode tree = TreeNode.fromJson(treeJson);
        //print("Tree loaded: ${treeJson}");
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
        child: _TreeNodeWidget(node: rootTree!, images: images, treeJson: this.treeJson),
      ),
    );
  }
}

class _TreeNodeWidget extends StatefulWidget {
  final TreeNode node;
  final Map<String, String> images;
  final Map<String, dynamic> treeJson;

  const _TreeNodeWidget({Key? key, required this.node, required this.images, required this.treeJson}) : super(key: key);

  @override
  State<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<_TreeNodeWidget> {
  final GlobalKey parentKey = GlobalKey();
  final List<GlobalKey> childrenKeys = [];


  @override
  void initState() {
    super.initState();
    childrenKeys.addAll(List.generate(widget.node.children.length, (_) => GlobalKey()));
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

    final childrenWidgets = <Widget>[];
    for (int i = 0; i < widget.node.children.length; i++) {
      childrenWidgets.add(_TreeNodeWidget(node: widget.node.children[i], images: widget.images, key: childrenKeys[i], treeJson: widget.treeJson));
    }

    return Container(
      margin: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔥 Linia trebuie să fie dedesubt și să ignore gesturile
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

            // 🔥 Widgetul tău interactiv cu GestureDetector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    String imageName = widget.node.path.split('/').last;
                    String? resolvedPath = await findImagePathInTree(widget.treeJson, imageName);
                    print("Resolved path:---------------------- $resolvedPath");
                    if (resolvedPath != null && bytes != null) {
                      // Salvează temporar imaginea în directorul temporar
                      final tempFilePath = await saveImageTemporarily(bytes, imageName);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DrawingPage(tempPath: tempFilePath, parentPath: resolvedPath), // trimiți calea temporară
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
                    //color: Colors.red.withOpacity(0.3),
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        if (bytes != null)
                          Image.memory(bytes, width: 80, height: 80, fit: BoxFit.contain),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.node.path, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
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
    // Folosim poziția din stânga sus (nu centru)
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

    // Linie verticală de la partea stângă jos a părintelui până la partea stângă sus a celui mai jos copil
    double x = parentOffsetInCanvas.dx; // linia verticală la marginea stângă a părintelui
    double topY = parentOffsetInCanvas.dy + parentSize.height;
    double bottomY = childrenPositionsInCanvas.map((e) => e.dy).reduce((a, b) => a < b ? a : b);

    // Linie verticală principală
    canvas.drawLine(Offset(x, topY), Offset(x, bottomY), paint);

    // Linii orizontale către fiecare copil
    for (var childPos in childrenPositionsInCanvas) {
      double childX = childPos.dx;
      double childY = childPos.dy + 20; // un pic mai jos pentru aliniere mai naturală
      canvas.drawLine(Offset(x, childY), Offset(childX, childY), paint);
    }
  }


  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) {
    return oldDelegate.parentKey != parentKey || oldDelegate.childrenKeys != childrenKeys;
  }
}
