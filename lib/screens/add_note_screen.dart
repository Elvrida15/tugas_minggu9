import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/note.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  bool _isProcessing = false;

  // Wajib dispose controller
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ================= KAMERA (LIVE) =================
  Future<void> _openCamera() async {
    setState(() => _isProcessing = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw 'Kamera tidak ditemukan';

      if (!mounted) return;
      // Buka layar kamera
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(camera: cameras.first),
        ),
      );

      if (result != null && mounted) {
        setState(() => _imagePath = result);
      }
    } on CameraException catch (e) {
      // Penanganan penolakan izin kamera
      if (e.code == 'CameraAccessDenied' || e.code == 'camera_access_denied') {
        _showErrorDialog(
          'Izin Kamera Ditolak',
          'Buka pengaturan browser dan izinkan akses kamera.',
        );
      } else {
        _showErrorDialog('Error Kamera', e.description ?? e.toString());
      }
    } catch (e) {
      _showErrorDialog('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ================= GALERI =================
  Future<void> _pickGallery() async {
    setState(() => _isProcessing = true);
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() => _imagePath = pickedFile.path);
      }
    } catch (e) {
      _showErrorDialog('Gagal', 'Gagal mengambil gambar dari galeri: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ================= SIMPAN CATATAN =================
  void _saveNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan tidak boleh kosong!')),
      );
      return;
    }

    // Buat objek Note baru dan kembalikan ke HomeScreen
    final newNote = Note(content: text, imagePath: _imagePath);
    Navigator.pop(context, newNote);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isProcessing ? null : _saveNote,
            tooltip: 'Simpan Catatan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Tulis catatan di sini...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Memproses...'),
                  ],
                ),
              ),
            if (_imagePath != null && !_isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imagePath!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET KAMERA (DENGAN DISPOSE)
// ==========================================
class CameraView extends StatefulWidget {
  final CameraDescription camera;
  const CameraView({super.key, required this.camera});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose controller kamera
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Foto')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal membuka kamera: ${snapshot.error}'),
            );
          }

          return Column(
            children: [
              Expanded(child: CameraPreview(_controller)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final XFile file = await _controller.takePicture();
                      if (context.mounted) {
                        Navigator.pop(context, file.path);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengambil foto: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.camera),
                  label: const Text('Ambil Foto'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
