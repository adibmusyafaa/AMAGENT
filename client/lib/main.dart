import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(AmagentApp());

class AmagentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMAGENT',
      theme: ThemeData.dark(),
      home: PairingScreen(),
    );
  }
}

class PairingScreen extends StatefulWidget {
  @override
  _PairingScreenState createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _ipController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _connect(String ip, String password) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('http://$ip:8888/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final clientId = data['client_id'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ControlScreen(ip: ip, clientId: clientId, password: password)));
      } else {
        _showError(jsonDecode(res.body)['error']);
      }
    } catch (e) {
      _showError('Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AMAGENT Pairing')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _ipController, decoration: InputDecoration(labelText: 'Laptop IP')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Master Password', obscureText: true)),
            SizedBox(height: 10),
            ElevatedButton(onPressed: () => _connect(_ipController.text, _passwordController.text), child: Text('Pair Device')),
            Divider(),
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => QRScannerScreen()));
                if (result != null) {
                  final parts = result.split('|');
                  if (parts[0] == 'AMAGENT') _connect(parts[1], _passwordController.text);
                }
              },
              label: Text('Scan QR from Laptop'),
            )
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

class ControlScreen extends StatefulWidget {
  final String ip;
  final String clientId;
  final String password;
  ControlScreen({required this.ip, required this.clientId, required this.password});
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Ready for command';

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() => _text = val.recognizedWords);
          if (val.finalResult) _sendCommand(val.recognizedWords);
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendCommand(String cmd) async {
    await http.post(
      Uri.parse('http://${widget.ip}:8888/command'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': widget.password, 'command': cmd, 'client_id': widget.clientId}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AMAGENT Remote')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_text, style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
            SizedBox(height: 30),
            FloatingActionButton(onPressed: _listen, child: Icon(_isListening ? Icons.mic : Icons.mic_none))
          ],
        ),
      ),
    );
  }
}
