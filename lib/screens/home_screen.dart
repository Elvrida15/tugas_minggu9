import 'package:flutter/material.dart';

import '../models/note.dart';
import 'add_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // List untuk menyimpan hasil catatan
  final List<Note> _notes = [];

  // Fungsi pindah ke halaman tambah catatan
  void _addNote() async {
    final newNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (context) => const AddNoteScreen()),
    );

    // Jika ada catatan baru yang dikembalikan, tambahkan ke list
    if (newNote != null) {
      setState(() {
        _notes.add(newNote);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Catatan keseharian Elvrida')),
      body: _notes.isEmpty
          ? const Center(
              child: Text('Belum ada catatan. Tekan + untuk menambah.'),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          note.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      // Tampilkan gambar jika ada
                      if (note.imagePath != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                          child: Image.network(
                            note.imagePath!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
