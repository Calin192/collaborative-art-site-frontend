import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_drawing_board/subgallery/findImagePathInTree.dart';

void main() {
  group('findImagePathInTree', () {
    test('returns the full node path for a matching image name', () async {
      final treeJson = {
        'path': 'root.png',
        'drawing': {'name': 'root', 'username': ['alice']},
        'children': [
          {
            'path': 'folder/child.png',
            'drawing': {'name': 'child', 'username': ['bob']},
            'children': [],
          }
        ],
      };

      final result = await findImagePathInTree(treeJson, 'child.png');

      expect(result, 'folder/child.png');
    });

    test('returns null when the image name does not exist', () async {
      final treeJson = {
        'path': 'root.png',
        'drawing': {'name': 'root', 'username': ['alice']},
        'children': [],
      };

      final result = await findImagePathInTree(treeJson, 'missing.png');

      expect(result, isNull);
    });
  });
}
