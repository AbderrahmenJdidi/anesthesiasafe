import 'package:flutter/material.dart';
import '../services/azure_service.dart';
import '../config/azure_config.dart';

class AzureStatusWidget extends StatefulWidget {
  const AzureStatusWidget({super.key});

  @override
  State<AzureStatusWidget> createState() => _AzureStatusWidgetState();
}

class _AzureStatusWidgetState extends State<AzureStatusWidget> {
  bool? _isConnected;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (!AzureConfig.isConfigured()) {
      setState(() {
        _isConnected = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      bool connected = await AzureService.testConnection();
      setState(() {
        _isConnected = connected;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AzureConfig.isConfigured()) {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Azure Not Configured',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    Text(
                      'Please update azure_config.dart with your Azure details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: _isConnected == true ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (_isChecking)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                _isConnected == true ? Icons.cloud_done : Icons.cloud_off,
                color: _isConnected == true ? Colors.green[700] : Colors.red[700],
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isChecking
                        ? 'Checking Azure Connection...'
                        : _isConnected == true
                            ? 'Azure SAM2 Connected'
                            : 'Azure SAM2 Disconnected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isConnected == true ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  if (!_isChecking)
                    Text(
                      _isConnected == true
                          ? 'Ready for image processing'
                          : 'Check your Azure configuration',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isConnected == true ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isChecking ? null : _checkConnection,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Connection',
            ),
          ],
        ),
      ),
    );
  }
}