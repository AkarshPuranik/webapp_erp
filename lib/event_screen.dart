import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EventScreen extends StatefulWidget {
  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _fileUrl;
  String? _fileType;
  bool _isLoading = false;
  String _selectedUserType = 'students'; // Default selection

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Function to pick and upload file
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      try {
        setState(() {
          _isLoading = true;
          _fileType = result.files.single.extension; // Get the file extension
        });
        final ref = storage.ref().child('event_files/$fileName');
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();

        setState(() {
          _fileUrl = downloadURL;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded successfully!')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File upload failed: $e')),
        );
      }
    }
  }

  // Function to send event to Firestore
  Future<void> _sendEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null ||
        _fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Add event data to Firestore
      DocumentReference docRef = await firestore
          .collection(_selectedUserType)
          .doc('events')
          .collection('eventList')
          .add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'eventDate': Timestamp.fromDate(_selectedDate!),
        'mediaUrls': [_fileUrl],
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event sent successfully!')),
      );

      // Clear fields after sending
      _titleController.clear();
      _descriptionController.clear();
      _selectedDate = null;
      _fileUrl = null;
      _fileType = null;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send event: $e')),
      );
    }
  }

  // Function to pick a date for the event
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Preview for file (image, video, document)
  Widget _buildFilePreview() {
    if (_fileUrl == null) {
      return Text('No file selected');
    }

    if (_fileType == 'jpg' || _fileType == 'png') {
      return Image.network(_fileUrl!, height: 150, width: 150);
    } else if (_fileType == 'mp4') {
      return Text('Video file selected');
    } else {
      return Text('Document file selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Event to All'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Event Title'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Event Description'),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _pickDate,
                child: Text(_selectedDate == null
                    ? 'Select Event Date'
                    : 'Event Date: ${_selectedDate!.toLocal()}'
                    .split(' ')[0]),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickAndUploadFile,
                child: Text('Pick File to Attach'),
              ),
              SizedBox(height: 10),
              _buildFilePreview(),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendEvent,
                child: Text('Send Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
