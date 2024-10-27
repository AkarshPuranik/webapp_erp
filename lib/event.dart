import 'package:admin_er/notice_display.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';


class EventCreationPage extends StatefulWidget {
  @override
  _EventCreationPageState createState() => _EventCreationPageState();
}

class _EventCreationPageState extends State<EventCreationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDate;
  String? _imageUrl;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Event Description'),
                maxLines: 3,
              ),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Event Date'),
                onTap: _selectDate,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickAndUploadImage,
                child: const Text('Add Image'),
              ),
              const SizedBox(height: 10),
              if (_imageUrl != null)
                Image.network(
                  _imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitEvent,
                child: const Text('Submit Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isLoading = true);

    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final ref = storage.ref().child('events/$fileName');

      try {
        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();

        setState(() {
          _imageUrl = url;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null ||
        _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await firestore.collection('events').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'date': Timestamp.fromDate(_selectedDate!),
      'imageUrl': _imageUrl,
    });

    setState(() {
      _isLoading = false;
      _titleController.clear();
      _descriptionController.clear();
      _dateController.clear();
      _imageUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event added successfully')),
    );

    // Navigate to EventDisplayPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventDisplayPage()),
    );
  }
}
