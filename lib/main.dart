import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Включаем поддержку русского языка на уровне системы (копирование, вставка и т.д.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'), // Русский язык основная локаль
      ],
      home: const HomeScreen(),
    );
  }
}

// Модель данных для заметки
class Note {
  final int id;
  String text;

  Note({required this.id, this.text = ''});

  // Конвертируем заметку в Map для сохранения в JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
    };
  }

  // Создаем заметку обратно из Map при чтении из JSON
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      text: map['text'],
    );
  }
}

// Главный экран приложения
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  int _noteCounter = 1;

  @override
  void initState() {
    super.initState();
    _loadNotes(); // Загружаем сохраненные заметки при старте приложения
  }

  // Метод для загрузки заметок из памяти устройства
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString('saved_notes');
    final int? counter = prefs.getInt('note_counter');

    if (notesJson != null) {
      final List<dynamic> decodedList = jsonDecode(notesJson);
      setState(() {
        _notes = decodedList.map((item) => Note.fromMap(item)).toList();
        _noteCounter = counter ?? (_notes.isEmpty ? 1 : _notes.last.id + 1);
      });
    }
  }

  // Метод для сохранения заметок в память устройства
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    // Переводим список заметок в строку JSON
    final String encodedList = jsonEncode(_notes.map((note) => note.toMap()).toList());
    
    await prefs.setString('saved_notes', encodedList);
    await prefs.setInt('note_counter', _noteCounter);
  }

  // Функция для создания новой заметки
  void _createNewNote() {
    setState(() {
      _notes.add(Note(id: _noteCounter));
      _noteCounter++;
    });
    _saveNotes(); // Сохраняем изменения
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Text(
                'Нажмите на плюс, чтобы создать заметку',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteScreen(note: note),
                      ),
                    );
                    // Когда вернулись с экрана редактирования, сохраняем измененный текст
                    _saveNotes();
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заметка #${note.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.text.isEmpty ? 'Пустая заметка...' : note.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: note.text.isEmpty ? Colors.grey : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        tooltip: 'Добавить заметку',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Экран самой заметки (редактирование текста)
class NoteScreen extends StatefulWidget {
  final Note note;

  const NoteScreen({super.key, required this.note});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заметка #${widget.note.id}'),
        backgroundColor: Colors.amber.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.note.text = _controller.text;
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            hintText: 'Введите текст заметки здесь...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18, height: 1.5),
        ),
      ),
    );
  }
}
