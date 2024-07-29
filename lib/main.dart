import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

void main() {
  runApp(const MaterialApp(
    home: SocketIOExample(),
  ));
}

class SocketIOExample extends StatefulWidget {
  const SocketIOExample({super.key});

  @override
  _SocketIOExampleState createState() => _SocketIOExampleState();
}

class _SocketIOExampleState extends State<SocketIOExample> {
  late IO.Socket socket;
  late TextEditingController _controller;
  List<String> messages = [];
  File? _selectedImage;
  final picker = ImagePicker();
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  // Function to request permissions
  Future<void> _requestPermissions() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      _logger.e('Permission denied');
    }
  }

  // Function to initialize and connect to the Socket.IO server
  void _connect() {
    socket = IO.io('add link', <String, dynamic>{
      'transports': ['websocket'],
    });

    // Listen for the 'connect' event
    socket.on('connect', (_) {
      _logger.i('Connected');
    });

    // Listen for custom events from the server
    socket.on('message', (data) {
      _logger.i('Received: $data');
      setState(() {
        messages.add(data.toString());
      });
    });

    // Handle connection errors
    socket.on('connect_error', (error) {
      _logger.e('Connect Error: $error');
    });

    // Handle disconnection events
    socket.on('disconnect', (_) {
      _logger.i('Disconnected');
    });
  }

  @override
  void dispose() {
    // Clean up resources
    _logger.i('Closing Socket.IO connection');
    socket.dispose();
      _controller.dispose();
    super.dispose();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    // Request permissions before picking an image
    await _requestPermissions();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        print('Selected image: ${_selectedImage!.path}');
      });
    }
  }

  // Function to convert file to Uint8List buffer
  Future<Uint8List> _convertImageToBuffer(File image) async {
    return await image.readAsBytes();
  }

  // Function to send a custom event with image data to the server
  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty || _selectedImage != null) {
      String message = _controller.text;

      // Convert image to buffer if selected
      Uint8List imageBuffer = Uint8List(0);
      if (_selectedImage != null) {
        imageBuffer = await _convertImageToBuffer(_selectedImage!);
      }

      // Create the message body
      Map<String, dynamic> messageBody = {
        'userId': 'c44ecc2f-8155-483c-bb18-857745ceb925',
        'conversation_id': 'a62ca7ba-783c-4b10-809f-d63528ec9c3c',
        'content': message,
        'file_data': 
        {
          'buffer': base64Encode(imageBuffer),
          'encoding': '7bit',
          'mimetype': 'image/png',
          'fieldname': 'file',
          'size': imageBuffer.length
        }
      };

      _logger.i('Sending base64 buffer: ${base64Encode(imageBuffer)}');

      _logger.i('Sending custom_event: ${jsonEncode(messageBody["buffer"])}');
      socket.emit('sendMessage', messageBody); 
      // _controller.clear();
      _controller.text=base64Encode(imageBuffer);
      setState(() {
        _selectedImage = null;
      });
    }
  }

  // Function to disconnect from the Socket.IO server
  void _disconnect() {
    _logger.i('Disconnecting');
    socket.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Send a message',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 8),
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _connect,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _disconnect,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(messages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
