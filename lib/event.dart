import 'package:admin_er/event_model.dart'; // Ensure this is the correct path
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class EventManagement extends StatefulWidget {
  const EventManagement({super.key});

  @override
  State<EventManagement> createState() => _EventManagementState();
}

class _EventManagementState extends State<EventManagement> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;
  List<String> _mediaUrls = [];
  List<String> _mediaNames = []; // List to store media file names
  bool _isLoading = false;
  String? _currentEventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Management')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('events').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data!.docs.map((doc) {
                  final event = Event.fromFirestore(
                      doc.data() as Map<String, dynamic>, doc.id);
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editEvent(event);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(doc.id);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList();

                return ListView(children: events);
              },
            ),
          ),
          _buildAddEventButton(),
          if (_isLoading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildAddEventButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: 80,
        height: 80,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          onPressed: _showEventForm,
          child: const Icon(Icons.add, size: 40),
        ),
      ),
    );
  }

  void _showEventForm() {
    _titleController.clear();
    _descriptionController.clear();
    _dateController.clear();
    setState(() {
      _selectedDate = null;
      _mediaUrls.clear();
      _mediaNames.clear(); // Clear media names
      _currentEventId = null;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: _eventForm(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _submitEvent,
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _eventForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Event Title'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Event Description'),
          ),
          TextField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Event Date'),
            onTap: _selectDate,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickMedia,
            child: const Text('Add Media (Images & Documents)'),
          ),
          const SizedBox(height: 10),
          _mediaUrls.isNotEmpty
              ? Wrap(
                  spacing: 8.0,
                  children: _mediaUrls.map((url) {
                    final fileName = _mediaNames[_mediaUrls.indexOf(url)];
                    if (url.endsWith('.jpg') || url.endsWith('.png')) {
                      // Display image preview
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator();
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fileName,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  _mediaUrls.remove(url);
                                  _mediaNames.remove(fileName);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Display icon with cross mark for non-image files
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Icon(Icons.insert_drive_file, size: 40),
                              const SizedBox(height: 4),
                              Text(
                                fileName,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 10,
                            child: IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                setState(() {
                                  _mediaUrls.remove(url);
                                  _mediaNames.remove(fileName);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _pickMedia() async {
    setState(() {
      _isLoading = true;
    });

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any, // Allow any file type
    );
    if (result != null) {
      setState(() {
        _mediaUrls.addAll(
            result.paths.where((path) => path != null).map((path) => path!));
        _mediaNames.addAll(result.names as Iterable<String>);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media added')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _submitEvent() async {
    if (_titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _dateController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      Event event;
      if (_currentEventId != null) {
        event = Event(
          id: _currentEventId!,
          title: _titleController.text,
          description: _descriptionController.text,
          date: DateTime.parse(_dateController.text),
          mediaUrls: _mediaUrls,
        );

        await FirebaseFirestore.instance
            .collection('events')
            .doc(_currentEventId)
            .update(event.toMap());
      } else {
        event = Event(
          id: '', // Will be set when added to Firestore
          title: _titleController.text,
          description: _descriptionController.text,
          date: DateTime.parse(_dateController.text),
          mediaUrls: _mediaUrls,
        );

        await FirebaseFirestore.instance
            .collection('events')
            .add(event.toMap());
      }

      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  }

  void _editEvent(Event event) {
    // Populate the controllers with the current event data
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _dateController.text = DateFormat('yyyy-MM-dd')
        .format(event.date); // Format the date for display
    _mediaUrls = event.mediaUrls; // Load existing media URLs
    _mediaNames = event.mediaUrls
        .map((url) => url.split('/').last)
        .toList(); // Extract file names from URLs
    _currentEventId = event.id; // Store the current event ID

    // Show the event form dialog
    _showEventForm();
  }

  void _showDeleteConfirmationDialog(String eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('events')
                    .doc(eventId)
                    .delete();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        // Format the date as needed, for example:
        _dateController.text = DateFormat('yyyy-MM-dd')
            .format(_selectedDate!); // Use intl package for formatting
      });
    }
  }
}
