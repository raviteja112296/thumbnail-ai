import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'result_screen.dart';

class GenerateScreen extends StatefulWidget {
  final String? initialPrompt;   // ← add this
  const GenerateScreen({super.key, this.initialPrompt});
  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _promptCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _api = ApiService();
  final _firestore = FirestoreService();

  File? _faceImage;           // first image — face/main subject
  List<File> _referenceImages = []; // extra images — product, logo, etc

  bool _loading = false;
  int _loadingStep = 0;
  Timer? _loadingTimer;

  final List<String> _loadingMessages = [
    'Connecting to server...',
    'Analysing your images...',
    'Generating background with AI...',
    'Removing background from your photo...',
    'Compositing layers together...',
    'Adding text and finishing touches...',
    'Almost ready...',
  ];

  // ── Image pickers ──────────────────────────────────────────
@override
void initState() {
  super.initState();
  // Pre-fill prompt if coming from history
  if (widget.initialPrompt != null) {
    _promptCtrl.text = widget.initialPrompt!;
  }
}
  Future<void> _pickFaceImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _faceImage = File(picked.path));
    }
  }

  Future<void> _pickReferenceImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _referenceImages = picked.map((x) => File(x.path)).toList();
      });
    }
  }

  void _removeFace() => setState(() => _faceImage = null);

  void _removeReference(int index) {
    setState(() => _referenceImages.removeAt(index));
  }

  // ── Loading messages ───────────────────────────────────────

  void _startLoadingMessages() {
    _loadingStep = 0;
    _loadingTimer = Timer.periodic(const Duration(seconds: 20), (t) {
      if (mounted && _loadingStep < _loadingMessages.length - 1) {
        setState(() => _loadingStep++);
      }
    });
  }

  void _stopLoadingMessages() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  // ── Generate ───────────────────────────────────────────────

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a prompt');
      return;
    }
    if (_faceImage == null) {
      _showSnack('Please add your face/main photo');
      return;
    }

    setState(() => _loading = true);
    _startLoadingMessages();

    // Build full image list: face first, then references
    final allImages = [_faceImage!, ..._referenceImages];

    final userId = context.read<AuthService>().userId;
    final result = await _api.generateThumbnail(
      prompt: _promptCtrl.text.trim(),
      userId: userId,
      images: allImages,
    );

    _stopLoadingMessages();
    setState(() => _loading = false);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      final description = data['description'] as String;
      final imageBase64 = data['image_base64'] as String?;

      await _firestore.saveGeneration(
        userId: userId,
        prompt: _promptCtrl.text.trim(),
        description: description,
        imageBase64: imageBase64,
      );

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResultScreen(
          prompt: _promptCtrl.text.trim(),
          description: description,
          hasImage: data['has_image'] ?? false,
          imageBase64: data['image_base64'],
          message: data['message'],
        )));
    } else {
      _showSnack(result['error'] ?? 'Something went wrong');
    print(result['error']);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg),
          behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _promptCtrl.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Thumbnail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Prompt ──
            _sectionLabel('Describe your thumbnail', required: true),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                  'e.g. Java OOP tutorial for beginners, professional style,\n'
                  'title: Master Java, dark tech background with code screen',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Face image ──
            _sectionLabel('Your face / main subject', required: true),
            const Text(
              'This photo will be cut out and placed on the thumbnail',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),

            _faceImage == null
                ? _addButton(
                    icon: Icons.person_add_alt_1,
                    label: 'Add face photo',
                    onTap: _pickFaceImage,
                    color: const Color(0xFF6C63FF),
                  )
                : _facePreview(),

            const SizedBox(height: 24),

            // ── Reference images ──
            _sectionLabel('Reference images', required: false),
            const Text(
              'Optional — product, logo, style reference, extra content',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),

            if (_referenceImages.isEmpty)
              _addButton(
                icon: Icons.add_photo_alternate_outlined,
                label: 'Add reference images (optional)',
                onTap: _pickReferenceImages,
                color: const Color(0xFF00BFA5),
              )
            else
              _referenceGrid(),

            const SizedBox(height: 32),

            // ── Generate button or loading ──
            if (_loading)
              _loadingWidget()
            else
              ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text('Generate Thumbnail',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6C63FF)),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────

  Widget _sectionLabel(String text, {required bool required}) {
    return Row(children: [
      Text(text,
        style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold)),
      if (required) ...[
        const SizedBox(width: 4),
        const Text('*', style: TextStyle(color: Colors.red, fontSize: 16)),
      ]
    ]);
  }

  Widget _addButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(label,
              style: TextStyle(color: color,
                fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _facePreview() {
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _faceImage!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      // Change button
      Positioned(
        bottom: 10, left: 10,
        child: ElevatedButton.icon(
          onPressed: _pickFaceImage,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Change'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6)),
        ),
      ),
      // Remove button
      Positioned(
        top: 8, right: 8,
        child: GestureDetector(
          onTap: _removeFace,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle),
            child: const Icon(Icons.close,
              color: Colors.white, size: 18),
          ),
        ),
      ),
      // Label badge
      Positioned(
        top: 8, left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            borderRadius: BorderRadius.circular(6)),
          child: const Text('FACE PHOTO',
            style: TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }

  Widget _referenceGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _referenceImages.length + 1,
            itemBuilder: (_, i) {
              // Last item = add more button
              if (i == _referenceImages.length) {
                return GestureDetector(
                  onTap: _pickReferenceImages,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00BFA5).withOpacity(0.5),
                        width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFF00BFA5).withOpacity(0.05)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add,
                          color: Color(0xFF00BFA5), size: 28),
                        SizedBox(height: 4),
                        Text('Add more',
                          style: TextStyle(
                            color: Color(0xFF00BFA5), fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }

              // Reference image tile
              return Stack(children: [
                Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _referenceImages[i],
                      fit: BoxFit.cover,
                      height: 110,
                      width: 100,
                    ),
                  ),
                ),
                Positioned(
                  top: 4, right: 12,
                  child: GestureDetector(
                    onTap: () => _removeReference(i),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4)),
                    child: Text('REF ${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                  ),
                ),
              ]);
            },
          ),
        ),
      ],
    );
  }

  Widget _loadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3))),
      child: Column(children: [
        const SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF6C63FF))),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _loadingMessages[_loadingStep],
            key: ValueKey(_loadingStep),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15, color: Colors.white70))),
        const SizedBox(height: 8),
        const Text(
          'Takes 60–120 seconds on first run',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }
}