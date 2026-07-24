import 'package:flutter_drawing_board/subgallery/subtree_gallery_page.dart';

class TreeNode {
  final String path;
  final Map<String, dynamic>? drawing;
  final List<TreeNode> children;

  TreeNode({required this.path, this.drawing, required this.children});

  factory TreeNode.fromJson(Map<String, dynamic> json) {
    return TreeNode(
      path: json['path'],
      drawing: json['drawing'] as Map<String, dynamic>?,
      children: (json['children'] as List<dynamic>)
          .map((childJson) => TreeNode.fromJson(childJson as Map<String, dynamic>))
          .toList(),
    );
  }
}

Future<String?> findImagePathInTree(Map<String, dynamic> treeJson, String imageName) async {
  try {
    final TreeNode root = TreeNode.fromJson(treeJson);

    String? searchTree(TreeNode node, String targetName) {
      final nodeName = node.path.split('/').last;

      if (nodeName == targetName) {
        print('Found image: $targetName at path: ${node.path}');
        return node.path;
      }

      for (final child in node.children) {
        final result = searchTree(child, targetName);
        if (result != null) {
          return result;
        }
      }

      return null;
    }

    return searchTree(root, imageName);
  } catch (e) {
    print('Error searching for image in tree: $e');
    return null;
  }
}
