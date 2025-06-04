import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smartfarmer/provider/lang_provider.dart'; // Add provider import

class CropDiseaseDetectionScreen extends StatefulWidget {
  const CropDiseaseDetectionScreen({super.key});

  @override
  State<CropDiseaseDetectionScreen> createState() =>
      _CropDiseaseDetectionScreenState();
}

class _CropDiseaseDetectionScreenState
    extends State<CropDiseaseDetectionScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _detectionResult;
  String? _errorMessage;

  Future<void> _pickImage() async {
    print('[DEBUG] Starting image picker process');

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        print('[DEBUG] Image selected: ${pickedFile.path}');
        print('[DEBUG] File size: ${File(pickedFile.path).lengthSync()} bytes');

        setState(() {
          _selectedImage = File(pickedFile.path);
          _detectionResult = null;
          _errorMessage = null;
        });

        print('[DEBUG] Calling _analyzeImage with selected file');
        await _analyzeImage(_selectedImage!);
      } else {
        print('[DEBUG] User cancelled image selection');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      }
    } catch (e) {
      print('[ERROR] Exception in _pickImage: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _analyzeImage(File image) async {
    print('[DEBUG] Starting image analysis');
    print('[DEBUG] Image path: ${image.path}');

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Create multipart request
      final apiUrl = 'https://smartfarmer-iogu.onrender.com/crop';
      print('[DEBUG] Creating request to $apiUrl');

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add image file
      print('[DEBUG] Adding image to multipart request');
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      // Debug print request details
      print('[DEBUG] Sending request...');

      // Send request
      var response = await request.send();
      print('[DEBUG] Received response with status: ${response.statusCode}');

      // Get response
      final respStr = await response.stream.bytesToString();
      print(
        '[DEBUG] Raw response (first 100 chars): ${respStr.substring(0, respStr.length > 100 ? 100 : respStr.length)}',
      );

      // Check if response is HTML (indicating a problem)
      if (respStr.trim().toLowerCase().startsWith('<html>')) {
        throw Exception(
          'Server returned HTML instead of JSON. Check API deployment.',
        );
      }

      // Try parsing JSON
      try {
        final jsonResponse = json.decode(respStr);
        print(jsonResponse);
        print('----------------------------------------------------------');
        print('[DEBUG] Parsed JSON response: $jsonResponse');

        if (response.statusCode == 200) {
          print('[DEBUG] Analysis successful');
          setState(() {
            _detectionResult = jsonResponse;
            _isLoading = false;
          });
        } else {
          print('[ERROR] API returned error status: ${response.statusCode}');
          setState(() {
            _errorMessage =
                'API Error: ${jsonResponse['detail'] ?? 'Status ${response.statusCode}'}';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('[ERROR] JSON parsing failed: $e');
        throw Exception('Invalid API response format. Expected JSON.');
      }
    } catch (e, stackTrace) {
      print('[ERROR] Exception in _analyzeImage: $e');
      print('[ERROR] Stack trace: $stackTrace');
      setState(() {
        _errorMessage =
            'Analysis failed: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    } finally {
      print('[DEBUG] Analysis process completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] Building widget tree');
    print(
      '[DEBUG] Current state: '
      'isLoading=$_isLoading, '
      'hasImage=${_selectedImage != null}, '
      'result=$_detectionResult, '
      'error=$_errorMessage',
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildImageUploadCard(context),
                  if (_isLoading) _buildLoadingIndicator(),
                  if (_detectionResult != null) _buildResultCard(),
                  if (_errorMessage != null) _buildErrorCard(),
                  const SizedBox(height: 20),
                  _buildBestPracticesCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    print('[DEBUG] Building loading indicator');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(
            Provider.of<LanguageProvider>(context).getText('Analyzing image...'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    print('[DEBUG] Building result card with: $_detectionResult');

    // Handle case when crop is not recognized
    if (_detectionResult?['crop_name'] == 'unknown') {
      return Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    Provider.of<LanguageProvider>(context).getText('Crop Not Recognized'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Image preview
              if (_selectedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Text(
                _detectionResult?['description'] ??
                    Provider.of<LanguageProvider>(context).getText('The crop in the image could not be recognized. Please try again with a clearer image.'),
                style: TextStyle(color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),

              Text(
                Provider.of<LanguageProvider>(context).getText('Tips for better results:'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              _buildTipItem(Provider.of<LanguageProvider>(context).getText('Ensure the crop is clearly visible')),
              _buildTipItem(Provider.of<LanguageProvider>(context).getText('Take the photo in good lighting')),
              _buildTipItem(Provider.of<LanguageProvider>(context).getText('Focus on the leaves or distinctive features')),
              _buildTipItem(Provider.of<LanguageProvider>(context).getText('Avoid shadows or obstructions')),
            ],
          ),
        ),
      );
    }

    // Normal result display
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _detectionResult?['health_status'] == 'healthy'
                      ? Icons.check_circle
                      : Icons.warning,
                  color:
                      _detectionResult?['health_status'] == 'healthy'
                          ? Colors.green[700]
                          : Colors.orange[700],
                ),
                const SizedBox(width: 8),
                Text(
                  Provider.of<LanguageProvider>(context).getText('Analysis Result'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _detectionResult?['health_status'] == 'healthy'
                            ? Colors.green[700]
                            : Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Image preview
            if (_selectedImage != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Display the parsed results
            if (_detectionResult != null) ...[
              _buildResultItem(
                Provider.of<LanguageProvider>(context).getText('Crop'),
                _detectionResult!['crop_name'] ?? 'Unknown',
              ),
              if (_detectionResult!.containsKey('growth_stage'))
                _buildResultItem(
                  Provider.of<LanguageProvider>(context).getText('Growth Stage'),
                  _detectionResult!['growth_stage'],
                ),
              if (_detectionResult!.containsKey('health_status'))
                _buildResultItem(
                  Provider.of<LanguageProvider>(context).getText('Health Status'),
                  _detectionResult!['health_status'],
                ),
              const SizedBox(height: 12),
              if (_detectionResult!.containsKey('issues'))
                _buildResultSection(Provider.of<LanguageProvider>(context).getText('Issues'), _detectionResult!['issues']),
              const SizedBox(height: 12),
              if (_detectionResult!.containsKey('recommendations'))
                _buildResultSection(
                  Provider.of<LanguageProvider>(context).getText('Recommendations'),
                  _detectionResult!['recommendations'],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle( color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: TextStyle(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildErrorCard() {
    final errorMessage = _errorMessage ?? 'Unknown error occurred';
    final displayMessage = _parseApiErrorMessage(errorMessage);

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  Provider.of<LanguageProvider>(context).getText('Analysis Failed'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
            if (errorMessage != displayMessage) ...[
              const SizedBox(height: 12),
              Text(
                Provider.of<LanguageProvider>(context).getText('Technical Details:'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _selectedImage = null;
                });
              },
              child: Text(Provider.of<LanguageProvider>(context).getText('Try Again')),
            ),
          ],
        ),
      ),
    );
  }

  String _parseApiErrorMessage(String errorMessage) {
    try {
      // Handle non-standard JSON format (without quotes around keys)
      if (errorMessage.startsWith('{') && !errorMessage.startsWith('{"')) {
        // Convert to valid JSON by adding quotes around keys
        final fixedJson = errorMessage.replaceAllMapped(
          RegExp(r'(\w+):'),
          (match) => '"${match.group(1)}":',
        );
        final jsonData = json.decode(fixedJson);
        return jsonData['detail'] ?? errorMessage;
      }
      // Handle standard JSON format
      else if (errorMessage.startsWith('{')) {
        final jsonData = json.decode(errorMessage);
        return jsonData['detail'] ?? jsonData['message'] ?? errorMessage;
      }
      return errorMessage;
    } catch (e) {
      print('[ERROR] Failed to parse error message: $e');
      return errorMessage;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.0, // Status bar padding
        left: 16.0,
        right: 16.0,
        bottom: 24.0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF4A7C59), // Darker green for header
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FarmAssist",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            Provider.of<LanguageProvider>(context).getText('Crop Disease Detection'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Provider.of<LanguageProvider>(context).getText('AI-powered analysis with 95% accuracy'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0), // Light peach
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFFFA726), // Orange
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              Provider.of<LanguageProvider>(context).getText('Upload Crop Image'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Provider.of<LanguageProvider>(context).getText('Take a clear photo of your crop leaves or\ndrag and drop an image here'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 20),
              label: Text(
                Provider.of<LanguageProvider>(context).getText('Choose Image'),
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 16),
            Text(
              Provider.of<LanguageProvider>(context).getText('Supported formats: JPG, PNG, WEBP (Max 10MB)'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestPracticesCard(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<LanguageProvider>(context).getText('Best Practices'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      Provider.of<LanguageProvider>(context).getText('For accurate results'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPracticeItem(Provider.of<LanguageProvider>(context).getText('Take photos in good natural lighting'), context),
            _buildPracticeItem(Provider.of<LanguageProvider>(context).getText('Focus on affected leaves or areas'), context),
            _buildPracticeItem(Provider.of<LanguageProvider>(context).getText('Avoid blurry or dark images'), context),
            _buildPracticeItem(Provider.of<LanguageProvider>(context).getText('Include multiple angles if possible'), context),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}