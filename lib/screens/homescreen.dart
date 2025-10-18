import 'package:disease_detection_app/screens/userprofile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'medicalhistory.dart';
import 'login_screen.dart'; // <-- import your login screen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _sliderItems = [
    {
      'image': 'images/character_new.jpg',
      'title': 'Skin Disease',
      'description': 'Common symptoms include redness, itching, and rashes',
    },
    {
      'image': 'images/female-doctor_new.jpg',
      'title': 'Respiratory Issues',
      'description': 'Look for coughing, shortness of breath, chest pain',
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Check if user is logged in, else redirect to login page
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      // If not logged in → redirect to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  void _showImageInfo(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_sliderItems[index]['title']),
        content: Text(_sliderItems[index]['description']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Logout function
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // logout button in appbar
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'User Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Userprofile()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About the App'),
              onTap: () {}, // Handle about the app action
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Medical History'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MedicalHistoryPage()));
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.grey.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Image slider with overlay
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: _sliderItems.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageInfo(context, index),
                        child: Image.asset(
                          _sliderItems[index]['image'],
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    top: 280,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _sliderItems.length,
                            (index) => Container(
                          width: 8,
                          height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == index
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Buttons for disease detection and body checkup
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {}, // Handle disease detection
                  child: const Text('Disease Detection'),
                ),
                ElevatedButton(
                  onPressed: () {}, // Handle body checkup
                  child: const Text('Body Checkup'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Center(child: Text("ChatBot")),
          ],
        ),
      ),
    );
  }
}
