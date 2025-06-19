import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io';

class SamsungCompatibilityExample extends StatefulWidget {
  @override
  _SamsungCompatibilityExampleState createState() => _SamsungCompatibilityExampleState();
}

class _SamsungCompatibilityExampleState extends State<SamsungCompatibilityExample> {
  String _connectionStatus = 'Not connected';
  String _forceWifiStatus = 'Not forced';
  String _deviceInfo = '';
  bool _isConnecting = false;
  bool _isForcing = false;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    if (Platform.isAndroid) {
      // Note: You would need to add device_info_plus package to get actual device info
      setState(() {
        _deviceInfo = 'Android Device (检测设备类型需要 device_info_plus 包)';
      });
    } else {
      setState(() {
        _deviceInfo = 'iOS Device';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Samsung 兼容性示例'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设备信息:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(_deviceInfo),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'WiFi SSID',
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
              onPressed: _isConnecting ? null : _connectWithStandardMethod,
              child: Text(_isConnecting ? 'Connecting...' : '标准连接方法'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectWithEnhancedMethod,
              child: Text(_isConnecting ? 'Connecting...' : '增强连接方法 (推荐三星设备)'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isForcing ? null : _forceWifiStandard,
                    child: Text(_isForcing ? 'Forcing...' : '标准强制WiFi'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isForcing ? null : _forceWifiWithRetry,
                    child: Text(_isForcing ? 'Forcing...' : '重试强制WiFi'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _disconnect,
              child: Text('断开连接'),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '连接状态:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(_connectionStatus),
                    SizedBox(height: 12),
                    Text(
                      'WiFi强制状态:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(_forceWifiStatus),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectWithStandardMethod() async {
    if (_ssidController.text.isEmpty) {
      _showError('请输入 SSID');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting with standard method...';
    });

    try {
      final result = await WiFiForIoTPlugin.connectWithResult(
        _ssidController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        security: _passwordController.text.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
      );

      setState(() {
        if (result.success) {
          _connectionStatus = 'Connected successfully!';
        } else {
          _connectionStatus = 'Connection failed: ${result.errorCode}\n${result.errorMessage}';
        }
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Connection failed: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _connectWithEnhancedMethod() async {
    if (_ssidController.text.isEmpty) {
      _showError('请输入 SSID');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting with enhanced method...';
    });

    try {
      // 1. 连接到网络
      final result = await WiFiForIoTPlugin.connectWithResult(
        _ssidController.text,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        security: _passwordController.text.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
      );

      if (!result.success) {
        setState(() {
          _connectionStatus = 'Connection failed: ${result.errorCode}\n${result.errorMessage}';
          _isConnecting = false;
        });
        return;
      }

      setState(() {
        _connectionStatus = 'Connected! Waiting for network to stabilize...';
      });

      // 2. 等待网络稳定
      await Future.delayed(Duration(seconds: 3));

      // 3. 验证连接
      bool isConnected = await WiFiForIoTPlugin.isConnected();
      if (!isConnected) {
        setState(() {
          _connectionStatus = 'Connection verification failed';
          _isConnecting = false;
        });
        return;
      }

      setState(() {
        _connectionStatus = 'Connected and verified! Forcing WiFi usage...';
      });

      // 4. 强制使用 WiFi（增强方法）
      bool forceSuccess = await WiFiForIoTPlugin.forceWifiUsageWithRetry(
        true,
        retryCount: 5,
        retryDelay: 2000,
      );

      setState(() {
        if (forceSuccess) {
          _connectionStatus = 'Connected and WiFi forced successfully!';
          _forceWifiStatus = 'WiFi usage forced (enhanced method)';
        } else {
          _connectionStatus = 'Connected but WiFi force failed';
          _forceWifiStatus = 'WiFi force failed';
        }
        _isConnecting = false;
      });

    } catch (e) {
      setState(() {
        _connectionStatus = 'Enhanced connection failed: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _forceWifiStandard() async {
    setState(() {
      _isForcing = true;
      _forceWifiStatus = 'Forcing WiFi (standard)...';
    });

    try {
      bool success = await WiFiForIoTPlugin.forceWifiUsage(true);
      setState(() {
        _forceWifiStatus = success 
          ? 'WiFi forced successfully (standard)' 
          : 'WiFi force failed (standard)';
        _isForcing = false;
      });
    } catch (e) {
      setState(() {
        _forceWifiStatus = 'WiFi force error: $e';
        _isForcing = false;
      });
    }
  }

  Future<void> _forceWifiWithRetry() async {
    setState(() {
      _isForcing = true;
      _forceWifiStatus = 'Forcing WiFi with retry...';
    });

    try {
      bool success = await WiFiForIoTPlugin.forceWifiUsageWithRetry(
        true,
        retryCount: 5,
        retryDelay: 1500,
      );
      setState(() {
        _forceWifiStatus = success 
          ? 'WiFi forced successfully (with retry)' 
          : 'WiFi force failed (with retry)';
        _isForcing = false;
      });
    } catch (e) {
      setState(() {
        _forceWifiStatus = 'WiFi force error: $e';
        _isForcing = false;
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      // 1. 禁用强制 WiFi 使用
      await WiFiForIoTPlugin.forceWifiUsage(false);
      
      // 2. 断开连接
      await WiFiForIoTPlugin.disconnect();
      
      setState(() {
        _connectionStatus = 'Disconnected';
        _forceWifiStatus = 'WiFi force disabled';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Disconnect error: $e';
      });
    }
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
