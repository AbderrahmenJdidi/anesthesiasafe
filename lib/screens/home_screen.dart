import 'dart:io';
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
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  final AuthService _authService = AuthService();
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
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
    
    // Start initial animations
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  /// Handle image selection from camera or gallery
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
          _analysisResult = null; // Clear previous results
        });
        _slideAnimationController.reset();
        _slideAnimationController.forward();
      }
    } catch (e) {
      _showSnackBar('Error selecting image: ${e.toString()}');
    }
  }

  /// Simulate AI model processing with mock API call
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 3));
      
      // Mock API response - in real app, this would be an actual HTTP request
      final mockResponse = {
        'safety': true,
        'confidence': 0.92,
        'recommendation': 'Patient appears to be in good condition for anesthesia administration. Proceed with standard pediatric protocols.',
        'riskFactors': ['None detected'],
        'notes': 'Patient shows normal facial characteristics with no visible signs of respiratory distress or abnormalities.'
      };

      setState(() {
        _analysisResult = mockResponse;
        _isProcessing = false;
      });

      // Trigger fade-in animation for results
      _fadeAnimationController.reset();
      _fadeAnimationController.forward();

      // Save analysis result to Firestore
      await _authService.saveAnalysisResult(mockResponse);

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Analysis failed: ${e.toString()}');
    }
  }

  /// Show snackbar with message
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
      ),
    );
  }

  /// Reset the analysis state
  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
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
                  // Welcome Section
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
                            'Upload a clear image of the patient for AI-assisted safety evaluation',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Upload Section
                  UploadSectionWidget(
                    selectedImage: _selectedImage,
                    isProcessing: _isProcessing,
                    onPickImage: _pickImage,
                    onAnalyze: _analyzeImage,
                    onReset: _resetAnalysis,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Results Section
                  if (_analysisResult != null)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ResultsCardWidget(
                        analysisResult: _analysisResult!,
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Space for bottom section
                ],
              ),
            ),
          ),
          
          // Progress Indicator Overlay
          if (_isProcessing)
            const CustomProgressIndicator(),
        ],
      ),
      bottomNavigationBar: const BottomSectionWidget(),
    );
  }
}