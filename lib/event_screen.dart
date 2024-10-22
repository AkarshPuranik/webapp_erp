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

  // Function to send event to students and teachers
  Future<void> _sendEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'eventDate': _selectedDate,
        'fileUrl': _fileUrl,
        'fileType': _fileType,
      };

      // Store event data under the selected user type
      await firestore
          .collection(
              _selectedUserType) // Save under the selected user type collection
          .doc('events')
          .collection('eventList')
          .add(eventData);

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

  // Function to delete event
  Future<void> _deleteEvent(String eventId) async {
    try {
      await firestore
          .collection(
              _selectedUserType) // Access the correct user type collection
          .doc('events')
          .collection('eventList')
          .doc(eventId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
  }

  Widget _buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection(
              _selectedUserType) // Access the correct user type collection
          .doc('events')
          .collection('eventList')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var events = snapshot.data!.docs;

        if (events.isEmpty) {
          return Text('No events found.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
          itemCount: events.length,
          itemBuilder: (context, index) {
            var event = events[index];
            return ListTile(
              title: Text(event['title']),
              subtitle:
                  Text('Date: ${(event['eventDate'] as Timestamp).toDate()}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Delete'),
                    value: 'delete',
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteEvent(event.id);
                  }
                },
              ),
            );
          },
        );
      },
    );
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
                      decoration:
                          InputDecoration(labelText: 'Event Description'),
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
                    _buildFilePreview(), // Display the preview of the selected file
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedUserType = 'students';
                              });
                            },
                            child: Text('Students'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                _selectedUserType == 'students'
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedUserType = 'teachers';
                              });
                            },
                            child: Text('Teachers'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                _selectedUserType == 'teachers'
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _sendEvent,
                      child: Text('Send Event'),
                    ),
                    SizedBox(height: 20),
                    Text('Posted Events:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      height: 200, // Set a fixed height for the event list
                      child: _buildEventList(), // List all posted events
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
