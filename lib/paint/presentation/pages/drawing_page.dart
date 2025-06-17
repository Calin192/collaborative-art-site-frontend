import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/drawing_canvas_options.dart';
import '../../domain/models/drawing_tool.dart';
import '../../domain/models/stroke.dart';
import '../../domain/models/undo_redo_stack.dart';
import '../notifiers/current_stroke_value_notifier.dart';
import '../theme/app_theme.dart';
import '../widgets/canvas_side_bar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/hot_key_listener.dart';





class DrawingPage extends StatefulWidget {
  final String? parentPath;
  final String? tempPath;
  final String username;

  const DrawingPage({super.key, required this.parentPath, required this.tempPath, required this.username});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.black);
  final ValueNotifier<double> strokeSize = ValueNotifier(10.0);
  final ValueNotifier<double> eraserSize = ValueNotifier(30.0);
  final ValueNotifier<DrawingTool> drawingTool =
  ValueNotifier(DrawingTool.pencil);
  final GlobalKey canvasGlobalKey = GlobalKey();
  final ValueNotifier<bool> filled = ValueNotifier(false);
  final ValueNotifier<int> polygonSides = ValueNotifier(3);
  final ValueNotifier<ui.Image?> backgroundImage = ValueNotifier(null);
  final CurrentStrokeValueNotifier currentStroke = CurrentStrokeValueNotifier();
  final ValueNotifier<List<Stroke>> allStrokes = ValueNotifier([]);
  late final UndoRedoStack undoRedoStack;
  final ValueNotifier<bool> showGrid = ValueNotifier(false);

  String? parentPath;  // variabila pentru path-ul parintelui
  String? tempPath;  // variabila pentru path-ul parintelui

  @override
  void initState() {
    super.initState();
    print("$parentPath");
    parentPath = widget.parentPath;
    tempPath = widget.tempPath;

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    undoRedoStack = UndoRedoStack(
      currentStrokeNotifier: currentStroke,
      strokesNotifier: allStrokes,
    );

    if (tempPath != null && tempPath!.isNotEmpty) {
      _loadBackgroundFromParentPath(tempPath!);
    }
  }

  Future<void> _loadBackgroundFromParentPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('File does not exist at $path');
        return;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      backgroundImage.value = frame.image;
    } catch (e) {
      debugPrint('Failed to load background image from $path: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvasColor,
      appBar: AppBar(
        title: Text(parentPath == null
            ? 'New Root Painting'
            : 'New Painting from $parentPath'),
      ),
      body: HotkeyListener(
        onRedo: undoRedoStack.redo,
        onUndo: undoRedoStack.undo,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                currentStroke,
                allStrokes,
                selectedColor,
                strokeSize,
                eraserSize,
                drawingTool,
                filled,
                polygonSides,
                backgroundImage,
                showGrid,
              ]),
              builder: (context, _) {
                return DrawingCanvas(
                  options: DrawingCanvasOptions(
                    currentTool: drawingTool.value,
                    size: strokeSize.value,
                    strokeColor: selectedColor.value,
                    backgroundColor: kCanvasColor,
                    polygonSides: polygonSides.value,
                    showGrid: showGrid.value,
                    fillShape: filled.value,
                  ),
                  canvasKey: canvasGlobalKey,
                  currentStrokeListenable: currentStroke,
                  strokesListenable: allStrokes,
                  backgroundImageListenable: backgroundImage,
                );
              },
            ),
            Positioned(
              top: kToolbarHeight + 10,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(animationController),
                child: CanvasSideBar(
                  drawingTool: drawingTool,
                  selectedColor: selectedColor,
                  strokeSize: strokeSize,
                  eraserSize: eraserSize,
                  currentSketch: currentStroke,
                  allSketches: allStrokes,
                  canvasGlobalKey: canvasGlobalKey,
                  filled: filled,
                  polygonSides: polygonSides,
                  backgroundImage: backgroundImage,
                  undoRedoStack: undoRedoStack,
                  showGrid: showGrid,
                  parentPath: parentPath,
                  username: widget.username,
                ),
              ),
            ),
            _CustomAppBar(animationController: animationController),
          ],
        ),
      ),
    );
  }
}



class _CustomAppBar extends StatelessWidget {
  final AnimationController animationController;

  const _CustomAppBar({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                if (animationController.value == 0) {
                  animationController.forward();
                } else {
                  animationController.reverse();
                }
              },
              icon: const Icon(Icons.menu),
            ),
            /*RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
                children: const [
                  TextSpan(
                    text: 'Paint',
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Hub',
                    style: TextStyle(
                      color: Colors.black,
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),*/
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
