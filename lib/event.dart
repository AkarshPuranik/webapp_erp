import 'package:admin_er/event_model.dart'; // Ensure this is the correct path
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class EventManagement extends StatefulWidget {
  const EventManagement({super.key});

  @override
  State<EventManagement> createState() => _EventManagementState();
}

class _EventManagementState extends State<EventManagement> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  List<String> _mediaUrls = [];
  bool _isLoading = false;
  String? _currentEventId; // To store the current event ID for editing

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
    setState(() {
      _selectedDate = null;
      _mediaUrls.clear();
      _currentEventId = null; // Reset event ID when showing form
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate == null
                    ? 'No date chosen'
                    : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
              ),
              TextButton(
                child: const Text('Choose Date'),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickMedia,
            child: const Text('Add Media (Images, Videos, Files)'),
          ),
          const SizedBox(height: 10),
          _mediaUrls.isNotEmpty
              ? Wrap(
                  spacing: 8.0,
                  children: _mediaUrls.map((url) {
                    return Stack(
                      children: [
                        Column(
                          children: [
                            _mediaPreview(url),
                            const SizedBox(height: 4),
                            Text(
                              _shortenFileName(url),
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
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _mediaPreview(String url) {
    if (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png')) {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    } else if (url.endsWith('.mp4')) {
      return VideoPlayerWidget(url: url);
    } else {
      return const Icon(Icons.insert_drive_file, size: 80);
    }
  }

  String _shortenFileName(String filePath) {
    final fileName = filePath.split('/').last;
    return fileName.length > 15 ? '${fileName.substring(0, 15)}...' : fileName;
  }

  Future<void> _pickMedia() async {
    setState(() {
      _isLoading = true;
    });

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _mediaUrls.addAll(
            result.paths.where((path) => path != null).map((path) => path!));
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
        _selectedDate != null) {
      setState(() {
        _isLoading = true;
      });

      Event event;
      if (_currentEventId != null) {
        // Editing an existing event
        event = Event(
          id: _currentEventId!,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate!,
          mediaUrls: _mediaUrls,
        );

        await FirebaseFirestore.instance
            .collection('events')
            .doc(_currentEventId)
            .update(event.toMap());
      } else {
        // Creating a new event
        event = Event(
          id: '', // Will be set when added to Firestore
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate!,
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
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _selectedDate = event.date;
    _mediaUrls = event.mediaUrls;
    _currentEventId = event.id; // Store the event ID for editing

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
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    _controller = VideoPlayerController.network(widget.url);
    await _controller.initialize();
    setState(() {
      _isInitialized = true;
    });
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const CircularProgressIndicator();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
