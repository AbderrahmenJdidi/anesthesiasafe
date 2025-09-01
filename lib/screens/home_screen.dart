import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'account_screen.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/bottom_section_widget.dart';
import '../widgets/upload_section_widget.dart';
import '../widgets/progress_indicator_widget.dart';
import '../widgets/results_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  Uint8List? _segmentedImage;
  String? _segmentedImageUrl;
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  final AuthService _authService = AuthService();
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String SERVER_URL = 'http://192.168.1.11:8000';
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 120);

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _slideAnimationController.forward();
    _checkServerConnection();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _checkServerConnection() async {
    try {
      print('Checking server connection to: $SERVER_URL/api/health/');
      final response = await http.get(
        Uri.parse('$SERVER_URL/api/health/'),
      ).timeout(const Duration(seconds: 10));
      
      print('Health check response code: ${response.statusCode}');
      print('Health check response body: ${response.body}');
      
      if (response.statusCode == 200) {
        setState(() {
          _errorMessage = null;
        });
        return true;
      } else {
        setState(() {
          _errorMessage = 'Server returned status: ${response.statusCode}';
        });
        return false;
      }
    } catch (e) {
      print('Health check error: $e');
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
      });
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _segmentedImage = null;
          _segmentedImageUrl = null;
          _analysisResult = null;
          _errorMessage = null;
        });
        _slideAnimationController.reset();
        _slideAnimationController.forward();
      }
    } catch (e) {
      _showSnackBar('Error selecting image: ${e.toString()}');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    print('Starting analysis...');
    
    bool isConnected = await _checkServerConnection();
    if (!isConnected) {
      _showSnackBar('Cannot connect to analysis server');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('Creating multipart request to: $SERVER_URL/api/segment-and-analyze/');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$SERVER_URL/api/segment-and-analyze/'),
      );
      
      print('Adding image file: ${_selectedImage!.path}');
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path)
      );
      
      request.fields['threshold_mode'] = 'balanced';
      print('Request fields: ${request.fields}');
      
      print('Sending request...');
      var response = await request.send().timeout(REQUEST_TIMEOUT);
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      
      var responseBody = await response.stream.bytesToString();
      print('Response body length: ${responseBody.length}');
      print('Response body preview: ${responseBody.length > 200 ? responseBody.substring(0, 200) + "..." : responseBody}');
      
      if (response.statusCode == 200) {
        var responseData = jsonDecode(responseBody);
        print('Parsed response keys: ${responseData.keys}');
        
        // Check if we have the expected data structure
        if (responseData.containsKey('segmented_image_data') && 
            responseData.containsKey('analysis_result')) {
          
          print('Both segmented_image_data and analysis_result found');
          
          try {
            var imageBytes = base64.decode(responseData['segmented_image_data']);
            print('Decoded image bytes length: ${imageBytes.length}');
            
            var analysisData = responseData['analysis_result'];
            print('Analysis data: $analysisData');
            
            final formattedResult = {
              'safety': analysisData['safety'] ?? false,
              'confidence': analysisData['confidence'] ?? 0.0,
              'recommendation': analysisData['recommendation'] ?? 'No recommendation',
              'riskLevel': analysisData['risk_level'] ?? 'UNKNOWN',
              'riskFactors': _extractRiskFactors(analysisData),
              'notes': analysisData['notes'] ?? 'No notes',
              'probabilities': analysisData['probabilities'] ?? {},
              'threshold_used': analysisData['threshold_used'] ?? 0.0,
              'prediction': analysisData['prediction'] ?? 'UNKNOWN',
            };
            
            print('Formatted result: $formattedResult');
            
            await _authService.saveAnalysisResult({
              ...formattedResult,
              'segmented_image_url': responseData['segmented_image_url'] ?? '',
              'analysis_timestamp': DateTime.now().toIso8601String(),
              'model_version': 'MobileViT-v2',
            });
            
            setState(() {
              _segmentedImage = imageBytes;
              _segmentedImageUrl = responseData['segmented_image_url'];
              _analysisResult = formattedResult;
              _isProcessing = false;
            });
            
            _fadeAnimationController.reset();
            _fadeAnimationController.forward();
            
            print('Analysis completed successfully');
            
          } catch (decodeError) {
            print('Error decoding response data: $decodeError');
            throw Exception('Failed to process server response: $decodeError');
          }
          
        } else {
          print('Missing expected keys in response');
          print('Available keys: ${responseData.keys}');
          throw Exception('Invalid response format: missing required data');
        }
        
      } else {
        print('Non-200 status code received');
        try {
          var errorData = jsonDecode(responseBody);
          throw Exception('Server error (${response.statusCode}): ${errorData['error'] ?? errorData.toString()}');
        } catch (jsonError) {
          throw Exception('Server error (${response.statusCode}): $responseBody');
        }
      }
      
    } catch (e) {
      print('Analysis error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Analysis failed: ${e.toString()}';
      });
      
      if (e.toString().contains('TimeoutException')) {
        _showSnackBar('Request timeout - server may be overloaded');
      } else if (e.toString().contains('SocketException')) {
        _showSnackBar('Network connection failed');
      } else {
        _showSnackBar('Analysis failed: ${e.toString()}');
      }
    }
  }

  List<String> _extractRiskFactors(Map<String, dynamic> analysisData) {
    List<String> riskFactors = [];
    
    var probabilities = analysisData['probabilities'];
    if (probabilities == null) return ['Unable to assess risk factors'];
    
    double probHard = (probabilities['hard'] ?? 0.0).toDouble();
    double confidence = (analysisData['confidence'] ?? 0.0).toDouble();
    String riskLevel = analysisData['risk_level'] ?? 'LOW';
    
    if (probHard >= 0.7) {
      riskFactors.add('High probability of difficult intubation (${(probHard * 100).toStringAsFixed(1)}%)');
    }
    
    if (riskLevel == 'HIGH') {
      riskFactors.add('High risk classification - requires experienced staff');
    } else if (riskLevel == 'MODERATE') {
      riskFactors.add('Moderate risk - enhanced monitoring recommended');
    }
    
    if (confidence < 0.7) {
      riskFactors.add('Model confidence below 70% - requires clinical verification');
    }
    
    if (probHard >= 0.45 && probHard < 0.55) {
      riskFactors.add('Borderline case - additional clinical assessment needed');
    }
    
    if (riskFactors.isEmpty && probHard < 0.4) {
      riskFactors.add('No significant risk factors detected');
    }
    
    return riskFactors;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _segmentedImage = null;
      _segmentedImageUrl = null;
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pediatric Anesthesia Safety Assessment',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A237E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload a clear facial image for AI-assisted difficult intubation prediction',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.refresh, size: 16),
                                    onPressed: _checkServerConnection,
                                    color: Colors.orange[700],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  UploadSectionWidget(
                    selectedImage: _selectedImage,
                    segmentedImage: _segmentedImage,
                    isProcessing: _isProcessing,
                    onPickImage: _pickImage,
                    onAnalyze: _analyzeImage,
                    onReset: _resetAnalysis,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_analysisResult != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ResultsCardWidget(
                        analysisResult: _analysisResult!,
                      ),
                    ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          if (_isProcessing)
            const CustomProgressIndicator(),
        ],
      ),
      bottomNavigationBar: const BottomSectionWidget(),
    );
  }
}