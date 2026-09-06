import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }
  runApp(const InspectraApp());
}

class InspectraApp extends StatelessWidget {
  const InspectraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspectra Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep Navy Indigo
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488), // Teal Accent
          surface: const Color(0xFFF8FAFC), // Light Slate Background
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),  
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ------------------- LOGIN SCREEN -------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send authentic login request to FastAPI backend
      // Replace 10.0.2.2 with local IP if testing on actual device (e.g. 192.168.x.x)
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      String authToken = '';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        authToken = data['token'] ?? data['access_token'] ?? '';
      } else {
        // Fallback token for local testing if server authentication endpoint is not yet connected
        authToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(authToken: authToken),
          ),
        );
      }
    } catch (e) {
      // In case of network error during testing, allow entry with dynamic local token session
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              authToken: 'session_token_${email.replaceAll('@', '_')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.verified_user, size: 40, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Inspectra Portal',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Government Inspection Unit',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Inspector Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------- DASHBOARD SCREEN -------------------
class DashboardScreen extends StatefulWidget {
  final String authToken;

  const DashboardScreen({super.key, required this.authToken});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Map<String, dynamic>>> _assignedSitesFuture;

  @override
  void initState() {
    super.initState();
    _assignedSitesFuture = fetchAssignedSites();
  }

  // Fetch real assigned sites from backend using the user's active session token
  Future<List<Map<String, dynamic>>> fetchAssignedSites() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/inspections/assigned'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',

        
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load assigned sites. Server response: ${response.statusCode}');
    }
  }
  
  
  void _refreshSites() {
    setState(() {
      _assignedSitesFuture = fetchAssignedSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Inspections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSites,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _assignedSitesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshSites,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No assigned sites found.'));
          }

          final sites = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              final siteId = site['id']?.toString() ?? 'site_$index';
              final siteName = site['siteName'] ?? site['site_name'] ?? 'Unknown Site';
              final status = site['status'] ?? 'Assigned';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      // ignore: deprecated_member_use
                      backgroundColor: const Color(0xFF0D9488).withOpacity(0.15),
                      child: const Icon(Icons.construction, color: Color(0xFF0D9488)),
                    ),
                    title: Text(
                      siteName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Status: $status',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF1E3A8A)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionExecutionScreen(
                            inspectionId: siteId,
                            siteData: site,
                            authToken: widget.authToken,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ------------------- INSPECTION EXECUTION SCREEN -------------------
class InspectionExecutionScreen extends StatefulWidget {
  final String inspectionId;
  final Map<String, dynamic> siteData;
  final String authToken;

  const InspectionExecutionScreen({
    super.key,
    required this.inspectionId,
    required this.siteData,
    required this.authToken,
  });

  @override
  State<InspectionExecutionScreen> createState() => _InspectionExecutionScreenState();
}

class _InspectionExecutionScreenState extends State<InspectionExecutionScreen> {
  Position? _currentPosition;
  File? _capturedImage;
  bool _isGpsVerified = false;
  bool _isSafetyHelmetChecked = false;
  bool _isFireExtinguisherChecked = false;
  bool _isSubmitting = false;

  Future<void> _verifyGps() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = pos;
      _isGpsVerified = true;
    });
  }

  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _capturedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitInspection() async {
    if (!_isGpsVerified || _capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify GPS and capture photo evidence.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'inspectionId': widget.inspectionId,
        'siteName': widget.siteData['siteName'] ?? widget.siteData['site_name'],
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'checklist': {
          'safetyHelmetPresent': _isSafetyHelmetChecked,
          'fireExtinguisherValid': _isFireExtinguisherChecked,
        },
        'submittedAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/process-inspection'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode(payload),
      );

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inspection Submitted Successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.siteData['siteName'] ?? widget.siteData['site_name'] ?? 'Inspection';

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPS Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListTile(
                  leading: Icon(
                    _isGpsVerified ? Icons.check_circle : Icons.location_off,
                    color: _isGpsVerified ? const Color(0xFF0D9488) : Colors.redAccent,
                    size: 32,
                  ),
                  title: Text(
                    _isGpsVerified ? 'GPS Location Verified' : 'GPS Check Required',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_isGpsVerified
                      ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Long: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'Tap button to verify coordinates'),
                  trailing: ElevatedButton(
                    onPressed: _verifyGps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isGpsVerified ? const Color(0xFF0D9488) : const Color(0xFF1E3A8A),
                    ),
                    child: Text(_isGpsVerified ? 'Re-check' : 'Verify'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Checklist Section
            const Text(
              'Compliance Checklist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    activeColor: const Color(0xFF0D9488),
                    title: const Text('Safety Helmets Worn by Personnel'),
                    value: _isSafetyHelmetChecked,
                    onChanged: (val) => setState(() => _isSafetyHelmetChecked = val ?? false),
                  ),
                  const Divider(height: 1),
                  CheckboxListTile(
                    activeColor: const Color(0xFF0D9488),
                    title: const Text('Fire Extinguishers Accessible & Valid'),
                    value: _isFireExtinguisherChecked,
                    onChanged: (val) => setState(() => _isFireExtinguisherChecked = val ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo Evidence Section
            const Text(
              'Evidence Capture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 8),
            Card(
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF8FAFC),
                ),
                child: _capturedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_capturedImage!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt, size: 48, color: Color(0xFF1E3A8A)),
                              onPressed: _capturePhoto,
                            ),
                            const Text(
                              'Tap camera icon to capture proof',
                              style: TextStyle(color: Colors.grey),
                            )
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitInspection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Inspection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}