import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  ResultScreen
// ─────────────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> prediction;
  final String age;
  final String sex;
  final String region;
  final String areaType; // "urban" | "semi-urban" | "rural"
  final String imageUrl; // or base64Image

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.age,
    required this.sex,
    required this.region,
    required this.areaType,
    required this.imageUrl,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _guidance;
  bool _loading = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Derived values ──────────────────────────────────────────────────────────

  String get _disease => widget.prediction['disease'] as String? ?? 'Unknown';
  double get _confidence =>
      (widget.prediction['confidence'] as num?)?.toDouble() ?? 0.0;

  String get _confidenceBucket {
    if (_confidence >= 0.75) return 'high';
    if (_confidence >= 0.60) return 'moderate';
    return 'low';
  }

  String get _ageCategory {
    final age = int.tryParse(widget.age) ?? 25;
    if (age < 10) return 'child_under_10';
    if (age > 60) return 'elderly_over_60';
    return 'standard';
  }

  bool get _isHighSeverity =>
      (_guidance?['severity'] as String?)?.toUpperCase() == 'HIGH';
  bool get _isInfectious => (_guidance?['infectious'] as bool?) ?? false;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Widget _resultImage() {
    if (widget.imageUrl.isEmpty) {
      return const Text("No image available");
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.memory(base64Decode(widget.imageUrl), fit: BoxFit.cover),
    );
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/medical_data.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final diseases = json['diseases'] as Map<String, dynamic>;
      setState(() {
        _guidance = diseases[_disease] as Map<String, dynamic>?;
        _loading = false;
      });
      _fadeCtrl.forward();
      _saveHistory();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final userIdString = prefs.getString('userId');

    if (userIdString == null) {
      print("User ID not found in SharedPreferences");
      return;
    }

    final userId = int.parse(userIdString);

    try {
      final response = await http.post(
        Uri.parse('http://10.15.65.92:3000/api/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId, // ✅ REQUIRED
          "age": widget.age,
          "sex": widget.sex,
          "region": widget.region,
          "areaType": widget.areaType,
          "disease": _disease,
          "confidence": _confidence,
          "guidance": _guidance,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");
    } catch (e) {
      print("Error saving history: $e");
    }
  }

  // ── Colour helpers ──────────────────────────────────────────────────────────

  Color get _severityColor {
    if (_isHighSeverity) return const Color(0xFFB80505);
    return const Color(0xFFF57C00);
  }

  Color get _confidenceColor {
    switch (_confidenceBucket) {
      case 'high':
        return const Color(0xFF2E7D32);
      case 'moderate':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFFB71C1C);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: _loading
          ? _buildLoader()
          : _guidance == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  // ── Loading ─────────────────────────────────────────────────────────────────

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF40C015)),
          SizedBox(height: 16),
          Text(
            'Analysing result…',
            style: TextStyle(color: Color(0xFF546E7A), fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load guidance data.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please consult a healthcare professional.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF546E7A)),
            ),
            const SizedBox(height: 24),
            _outlineButton('Go Back', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _resultImage(),
                const SizedBox(height: 12),
                _disclaimerBanner(),
                const SizedBox(height: 12),
                _confidenceCard(),
                const SizedBox(height: 12),
                if (_isInfectious) _infectiousBanner(),
                if (_isInfectious) const SizedBox(height: 12),
                _summaryCard(),
                const SizedBox(height: 12),
                _areaRecommendationCard(),
                const SizedBox(height: 12),
                _ageCautionCard(),
                const SizedBox(height: 12),
                _homeCareCard(),
                const SizedBox(height: 12),
                _whenToDoctorCard(),
                const SizedBox(height: 24),
                _emergencyFooter(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar ────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final severityLabel = _isHighSeverity
        ? 'HIGH SEVERITY'
        : 'MODERATE SEVERITY';

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF1565C0),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B5E20),
                _isHighSeverity
                    ? const Color(0xFF0F3D38)
                    : const Color(0xFF1A6B5E),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _severityColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _severityColor.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      severityLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _disease,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.age} yrs · ${widget.sex} · ${widget.region}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Disclaimer ──────────────────────────────────────────────────────────────

  Widget _disclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This is not a medical diagnosis. Always consult a qualified healthcare professional.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF6D4C41)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence card ──────────────────────────────────────────────────────────

  Widget _confidenceCard() {
    final bucket = _confidenceBucket;
    final threshold =
        (_guidance!['confidence_thresholds'] as Map)[bucket] as Map;
    final interpretation = threshold['confidence_interpretation'] as String;
    final pct = (_confidence * 100).toStringAsFixed(1);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Model Confidence', Icons.speed_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _confidence,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(_confidenceColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _confidenceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _tagChip(
            bucket == 'high'
                ? 'High Confidence'
                : bucket == 'moderate'
                ? 'Moderate Confidence'
                : 'Low Confidence',
            _confidenceColor,
          ),
          const SizedBox(height: 8),
          Text(
            interpretation,
            style: const TextStyle(fontSize: 13, color: Color(0xFF546E7A)),
          ),
        ],
      ),
    );
  }

  // ── Infectious banner ────────────────────────────────────────────────────────

  Widget _infectiousBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.coronavirus_outlined,
            color: Color(0xFFC62828),
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠ Contagious Condition',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFFC62828),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Avoid close contact with others until evaluated by a doctor.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF6D4C41)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────────

  Widget _summaryCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'About This Condition',
            Icons.medical_information_outlined,
          ),
          const SizedBox(height: 10),
          Text(
            _guidance!['condition_summary'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF37474F),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ── Area recommendation ───────────────────────────────────────────────────────

  Widget _areaRecommendationCard() {
    final areaRec =
        (_guidance!['area_recommendations'] as Map)[widget.areaType] as Map?;
    if (areaRec == null) return const SizedBox.shrink();

    final action = areaRec['recommended_action'] as String;
    final facility = areaRec['facility_type'] as String;
    final isImmediate = action.toLowerCase().contains('immediately');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recommended Action', Icons.local_hospital_outlined),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isImmediate
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isImmediate
                    ? const Color(0xFFEF9A9A)
                    : const Color(0xFF90CAF9),
              ),
            ),
            child: Text(
              action,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: isImmediate
                    ? const Color(0xFFC62828)
                    : const Color(0xFF1565C0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: Color(0xFF78909C),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  facility,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF546E7A),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Age caution card ──────────────────────────────────────────────────────────

  Widget _ageCautionCard() {
    final ageCaution =
        (_guidance!['age_caution'] as Map)[_ageCategory] as String?;
    if (ageCaution == null || _ageCategory == 'standard') {
      // Still show standard if there is a note worth showing
      final standard =
          (_guidance!['age_caution'] as Map)['standard'] as String?;
      if (standard == null) return const SizedBox.shrink();
    }

    final isExtra = _ageCategory != 'standard';
    final text = (_guidance!['age_caution'] as Map)[_ageCategory] as String;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Age-Specific Guidance',
            _ageCategory == 'child_under_10'
                ? Icons.child_care_rounded
                : _ageCategory == 'elderly_over_60'
                ? Icons.elderly_rounded
                : Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          if (isExtra)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '⚠  Extra caution required for this age group',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF37474F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Home care card ────────────────────────────────────────────────────────────

  Widget _homeCareCard() {
    final tips = (_guidance!['home_care'] as List).cast<String>();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Home Care Tips', Icons.home_outlined),
          const SizedBox(height: 10),
          ...tips.asMap().entries.map((e) => _homeCareItem(e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _homeCareItem(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF37474F),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── When to see doctor ────────────────────────────────────────────────────────

  Widget _whenToDoctorCard() {
    final text = _guidance!['when_to_seek_doctor'] as String;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D38), Color(0xFF1A6B5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D38).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency_outlined, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'When to See a Doctor',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emergency footer ──────────────────────────────────────────────────────────

  Widget _emergencyFooter() {
    return Column(
      children: [
        if (_isHighSeverity)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFC62828),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a HIGH severity condition. Do not delay seeking medical attention.',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'This app does not replace professional medical advice.\nAlways consult a licensed healthcare provider.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: Color(0xFF90A4AE)),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
          ),
        ),
      ],
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1565C0),
        side: const BorderSide(color: Color(0xFF1565C0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
