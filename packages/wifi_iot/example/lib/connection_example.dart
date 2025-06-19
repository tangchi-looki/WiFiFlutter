import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConnectionExample extends StatefulWidget {
  @override
  _ConnectionExampleState createState() => _ConnectionExampleState();
}

class _ConnectionExampleState extends State<ConnectionExample> {
  String _connectionStatus = 'Not connected';
  String _errorDetails = '';
  bool _isConnecting = false;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Connection with Error Codes'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'SSID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectWithOldMethod,
              child: Text(_isConnecting ? 'Connecting...' : 'Connect (Old Method)'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectWithNewMethod,
              child: Text(_isConnecting ? 'Connecting...' : 'Connect (New Method with Error Codes)'),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_connectionStatus),
                    if (_errorDetails.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Error Details:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _errorDetails,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectWithOldMethod() async {
    if (_ssidController.text.isEmpty) {
      _showError('Please enter SSID');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
      _errorDetails = '';
    });

    try {
      final bool result = await WiFiForIoTPlugin.connect(
        _ssidController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        security: _passwordController.text.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
      );

      setState(() {
        _connectionStatus = result ? 'Connected successfully!' : 'Connection failed (no details available)';
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
        _errorDetails = 'Exception: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectWithNewMethod() async {
    if (_ssidController.text.isEmpty) {
      _showError('Please enter SSID');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
      _errorDetails = '';
    });

    try {
      final WiFiConnectionResult result = await WiFiForIoTPlugin.connectWithResult(
        _ssidController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        security: _passwordController.text.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
      );

      setState(() {
        if (result.success) {
          _connectionStatus = 'Connected successfully!';
          _errorDetails = '';
        } else {
          _connectionStatus = 'Connection failed';
          _errorDetails = _buildErrorDetails(result);
        }
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed';
        _errorDetails = 'Unexpected exception: $e';
        _isConnecting = false;
      });
    }
  }

  String _buildErrorDetails(WiFiConnectionResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Error Code: ${result.errorCode}');
    
    if (result.errorMessage != null) {
      buffer.writeln('Message: ${result.errorMessage}');
    }
    
    if (result.errorDetails != null) {
      buffer.writeln('Details: ${result.errorDetails}');
    }

    // Add user-friendly explanations for common errors
    switch (result.errorCode) {
      case WiFiConnectionError.INVALID_SSID:
        buffer.writeln('\nSuggestion: Check that the SSID is between 1-32 characters.');
        break;
      case WiFiConnectionError.WEP_NOT_SUPPORTED:
        buffer.writeln('\nSuggestion: WEP security is deprecated. Use WPA/WPA2 instead.');
        break;
      case WiFiConnectionError.NETWORK_UNAVAILABLE:
        buffer.writeln('\nSuggestion: Check if the network is in range and try again.');
        break;
      case WiFiConnectionError.AUTHENTICATION_FAILED:
        buffer.writeln('\nSuggestion: Verify the password is correct.');
        break;
      case WiFiConnectionError.PERMISSION_DENIED:
        buffer.writeln('\nSuggestion: Grant location permissions to scan for networks.');
        break;
      case WiFiConnectionError.WIFI_NOT_ENABLED:
        buffer.writeln('\nSuggestion: Enable WiFi in device settings.');
        break;
      case WiFiConnectionError.CONNECTION_TIMEOUT:
        buffer.writeln('\nSuggestion: Network may be slow to respond. Try again.');
        break;
      default:
        buffer.writeln('\nSuggestion: Check network settings and try again.');
        break;
    }

    return buffer.toString();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
