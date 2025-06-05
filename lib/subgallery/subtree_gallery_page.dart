import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _loadImagesAndTree();
  }

  Future<void> _loadImagesAndTree() async {
    final String imagesUrl = 'http://localhost:8080/getImagesFromRoot?rootPath=${widget.rootPath}';
    final String treeUrl = 'http://localhost:8080/getTreeStructure?rootPath=${widget.rootPath}';

    try {
      final imagesResponse = await http.get(Uri.parse(imagesUrl));
      final treeResponse = await http.get(Uri.parse(treeUrl));

      if (imagesResponse.statusCode == 200 && treeResponse.statusCode == 200) {
        final Map<String, dynamic> imagesJson = json.decode(imagesResponse.body);
        final Map<String, String> imagesStringMap = imagesJson.map((key, value) => MapEntry(key, value.toString()));

        final Map<String, dynamic> treeJson = json.decode(treeResponse.body);
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
        child: _TreeNodeWidget(node: rootTree!, images: images),
      ),
    );
  }
}

class _TreeNodeWidget extends StatefulWidget {
  final TreeNode node;
  final Map<String, String> images;

  const _TreeNodeWidget({Key? key, required this.node, required this.images}) : super(key: key);

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
      childrenWidgets.add(_TreeNodeWidget(node: widget.node.children[i], images: widget.images, key: childrenKeys[i]));
    }

    return Container(
      margin: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nodul părinte cu key
                Row(
                  key: parentKey,
                  children: [
                    if (bytes != null)
                      Image.memory(bytes, width: 80, height: 80, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.node.path, style: const TextStyle(fontWeight: FontWeight.bold))),
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

            // Desenăm liniile după ce calculăm pozițiile
            Positioned.fill(
              child: CustomPaint(
                painter: _LinesPainter(
                  parentKey: parentKey,
                  childrenKeys: childrenKeys,
                ),
              ),
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
