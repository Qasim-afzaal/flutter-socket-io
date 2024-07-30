import 'dart:convert';
import 'package:flutter/material.dart';
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
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _connect();
  }

  // Function to initialize and connect to the Socket.IO server
  void _connect() {
    socket = IO.io('http://18.190.30.218:3004', <String, dynamic>{
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
    if (socket != null) {
      socket.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  // Function to send a custom event with text data to the server
  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String message = _controller.text;

      // Create the message body
      Map<String, dynamic> messageBody = {
        'userId': 'c44ecc2f-8155-483c-bb18-857745ceb925',
        'conversation_id': 'a62ca7ba-783c-4b10-809f-d63528ec9c3c',
        'content': message,
      };

      _logger.i('Sending custom_event: ${jsonEncode(messageBody)}');
      socket.emit('sendMessage', messageBody);
      _controller.clear();
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
