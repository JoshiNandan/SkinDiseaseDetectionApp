import 'dart:convert';
import 'dart:core';

import 'package:disease_detection_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://10.15.65.92:3000';

// ── Brand colors ──────────────────────────────────────────────────────────────
const _teal900 = Color(0xFF04342C);
const _teal700 = Color(0xFF0F6E56);
const _teal500 = Color(0xFF1D9E75);
const _teal100 = Color(0xFF9FE1CB);
const _teal50 = Color(0xFFE1F5EE);
const _gray50 = Color(0xFFF1EFE8);
const _gray200 = Color(0xFFB4B2A9);
const _gray800 = Color(0xFF444441);
const _white = Color(0xFFFFFFFF);
const _red400 = Color(0xFFEF5350);
const _red50 = Color(0xFFFFEBEE);

class Userprofile extends StatefulWidget {
  const Userprofile({super.key});

  @override
  State<Userprofile> createState() => _UserprofileState();
}

class _UserprofileState extends State<Userprofile>
    with SingleTickerProviderStateMixin {
  String userId = '';
  String userName = '';
  String userEmail = '';
  String userDob = '';
  String userPhone = '';
  String userGender = '';
  String userAge = '';
  String userProfileImage = '';
  String userCreatedAt = '';
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── READ ───────────────────────────────────────────────────────────────────
  Future<void> _fetchUserProfile() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('apiKey') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {'x-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final data = responseData['data'];
          setState(() {
            userId = data['id'].toString();
            userName = data['name'] ?? 'User';
            userEmail = data['email'] ?? '';
            userDob = data['dob'] ?? 'Not set';
            userPhone = data['phone'] ?? 'Not set';
            userGender = _formatGender(data['gender'] ?? 'Not set');
            userProfileImage = data['profile_image'] ?? '';
            userCreatedAt = _formatDate(data['created_at'] ?? '');
            userAge = _calculateAge(data['dob'] ?? '');
            isLoading = false;
          });
          _animationController.forward();
        } else {
          setState(() => isLoading = false);
          _showSnackBar('Failed to load profile data', isError: true);
        }
      } else {
        setState(() => isLoading = false);
        _showSnackBar(
          'Failed to load profile (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(
        'Network error. Please check your connection.',
        isError: true,
      );
    }
  }

  String _formatGender(String gender) {
    if (gender == 'Not set') return 'Not set';
    return gender[0].toUpperCase() + gender.substring(1);
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not set';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return 'Not set';
    }
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty || dob == 'Not set') return 'Not set';
    try {
      final birth = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return 'Not set';
    }
  }

  // ── UPDATE (Image) ─────────────────────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) await _updateProfileImage(img.path);
  }

  Future<void> _updateProfileImage(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('apiKey') ?? '';
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/user/profile'),
      );
      request.headers['x-api-key'] = apiKey;
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', path),
      );
      final res = await request.send();
      if (res.statusCode == 200) {
        _showSnackBar('Profile photo updated!');
        _fetchUserProfile();
      } else {
        _showSnackBar(
          'Failed to update photo (${res.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Network error while uploading photo.', isError: true);
    }
  }

  // ── UPDATE (Profile) ───────────────────────────────────────────────────────
  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: userName,
          currentDob: userDob,
          currentPhone: userPhone,
          currentGender: userGender,
          currentAge: userAge,
          currentAddress: '', // Address not in API response
          currentCreatedAt: userCreatedAt,
          onSaved: (_) {
            _fetchUserProfile();
            _showSnackBar('Profile updated successfully!');
          },
        ),
      ),
    );
  }

  // ── DELETE (Account) ───────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    // Step 1: first confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: _red400, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Account?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: const Text(
          'This action is permanent. All your data, scan history, and profile information will be erased and cannot be recovered.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _gray800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red400,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // Step 2: type-to-confirm
    final confirmController = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Are you absolutely sure?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type DELETE to confirm account removal:',
                style: TextStyle(fontSize: 13, color: _gray800),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: const TextStyle(color: _gray200),
                  filled: true,
                  fillColor: _red50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _gray800)),
            ),
            ElevatedButton(
              onPressed: confirmController.text == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _red400,
                foregroundColor: _white,
                disabledBackgroundColor: _gray200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete My Account'),
            ),
          ],
        ),
      ),
    );

    if (secondConfirm != true) return;

    // Step 3: API call
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('apiKey') ?? '';
      final response = await http.delete(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {'x-api-key': apiKey},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(
          'Failed to delete account (${response.statusCode}). Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Network error. Could not delete account.', isError: true);
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────────────────────────
  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _gray800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal700,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── SnackBar helper ────────────────────────────────────────────────────────
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: _white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _red400 : _teal700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _gray50,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal500))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildStatRow(),
                            const SizedBox(height: 28),
                            _sectionLabel('Personal Information'),
                            const SizedBox(height: 12),
                            _buildInfoCard(),
                            const SizedBox(height: 28),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Sliver header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _teal700,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal500.withOpacity(0.35),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _teal900.withOpacity(0.3),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _white, width: 3),
                            color: _teal100,
                          ),
                          child: ClipOval(
                            child: userProfileImage.isNotEmpty
                                ? Image.network(
                                    userProfileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarFallback(),
                                  )
                                : _avatarFallback(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _teal100, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: _teal700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: _white.withOpacity(0.75),
                      letterSpacing: 0.1,
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

  Widget _avatarFallback() {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: _teal700,
        ),
      ),
    );
  }

  // ── Stat row ───────────────────────────────────────────────────────────────
  Widget _buildStatRow() {
    return Row(
      children: [
        _statCard(Icons.cake_rounded, 'Age', userAge),
        const SizedBox(width: 12),
        _statCard(Icons.wc_rounded, 'Gender', userGender),
        const SizedBox(width: 12),
        _statCard(Icons.calendar_today_rounded, 'Member Since', userCreatedAt),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _teal500.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: _teal500),
            const SizedBox(height: 6),
            Text(
              value == 'Not set' ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _teal900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _gray200,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal500.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.phone_rounded, 'Phone', userPhone, isFirst: true),
          _divider(),
          _infoRow(Icons.cake_rounded, 'Date of Birth', userDob),
          _divider(),
          _infoRow(Icons.email_rounded, 'Email', userEmail, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 10, 16, isLast ? 16 : 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _teal50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _teal500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _gray200,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _gray800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: _gray50),
  );

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(
      children: [
        _actionButton(
          icon: Icons.edit_rounded,
          label: 'Edit Profile',
          onTap: _openEditProfile,
          style: _ButtonStyle.primary,
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          onTap: _logout,
          style: _ButtonStyle.secondary,
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.delete_forever_rounded,
          label: 'Delete Account',
          onTap: _deleteAccount,
          style: _ButtonStyle.danger,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required _ButtonStyle style,
  }) {
    final Color bgColor;
    final Color fgColor;
    final Border? border;

    switch (style) {
      case _ButtonStyle.primary:
        bgColor = _teal700;
        fgColor = _white;
        border = null;
        break;
      case _ButtonStyle.secondary:
        bgColor = _white;
        fgColor = _gray800;
        border = Border.all(color: _gray200.withOpacity(0.5));
        break;
      case _ButtonStyle.danger:
        bgColor = _red50;
        fgColor = _red400;
        border = Border.all(color: _red400.withOpacity(0.3));
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _gray800,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Button style enum ──────────────────────────────────────────────────────
enum _ButtonStyle { primary, secondary, danger }

// ══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentDob;
  final String currentPhone;
  final String currentGender;
  final String currentAge;
  final String currentAddress;
  final String currentCreatedAt;
  final Function(String) onSaved;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentDob,
    required this.currentPhone,
    required this.currentGender,
    required this.currentAge,
    required this.currentAddress,
    required this.currentCreatedAt,
    required this.onSaved,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController dobController;
  late TextEditingController phoneController;
  String? gender;
  bool isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    dobController = TextEditingController(text: widget.currentDob);
    phoneController = TextEditingController(text: widget.currentPhone);
    gender = widget.currentGender == 'Not set'
        ? null
        : widget.currentGender.toLowerCase();
  }

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _validate() {
    if (nameController.text.trim().isEmpty) return 'Name cannot be empty.';
    final phone = phoneController.text.trim();
    if (phone.isNotEmpty && phone.length < 7) {
      return 'Enter a valid phone number.';
    }
    final dob = dobController.text.trim();
    if (dob.isNotEmpty && dob != 'Not set') {
      try {
        String normalized = dob;
        if (dob.contains('/')) {
          final p = dob.split('/');
          normalized = '${p[2]}-${p[1]}-${p[0]}';
        }
        DateTime.parse(normalized);
      } catch (_) {
        return 'Enter DOB as YYYY-MM-DD or DD/MM/YYYY.';
      }
    }
    return null;
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  Future<void> updateProfile() async {
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    setState(() {
      isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('apiKey') ?? '';

      String dob = dobController.text.trim();
      if (dob.contains('/')) {
        final p = dob.split('/');
        dob = '${p[2]}-${p[1]}-${p[0]}';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: json.encode({
          "name": nameController.text.trim(),
          "dob": dob == 'Not set' ? '' : dob,
          "phone": phoneController.text.trim(),
          "gender": gender ?? '',
        }),
      );

      setState(() => isSaving = false);

      if (response.statusCode == 200) {
        widget.onSaved('success');
        Navigator.pop(context);
      } else {
        setState(
          () => _errorMessage =
              'Update failed (${response.statusCode}). Try again.',
        );
      }
    } catch (e) {
      setState(() {
        isSaving = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _gray50,
      appBar: AppBar(
        backgroundColor: _teal700,
        elevation: 0,
        foregroundColor: _white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Error banner ─────────────────────────────────────────────────
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _red400.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: _red400,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _red400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _formCard([
              _buildField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_rounded,
                hint: 'Enter your name',
              ),
              _formDivider(),
              _buildField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                hint: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
            ]),
            const SizedBox(height: 16),
            _formCard([
              _buildField(
                controller: dobController,
                label: 'Date of Birth',
                icon: Icons.cake_rounded,
                hint: 'YYYY-MM-DD or DD/MM/YYYY',
              ),
              _formDivider(),
              _buildGenderPicker(),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal700,
                  foregroundColor: _white,
                  disabledBackgroundColor: _teal100,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal500.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _teal50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _teal500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _gray200,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _gray800,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: _gray200),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _teal50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wc_rounded, size: 17, color: _teal500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _gray200,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['male', 'female', 'other'].map((g) {
                    final selected = gender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => gender = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? _teal700 : _teal50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            g[0].toUpperCase() + g.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? _white : _teal500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: _gray50),
  );
}
