import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({Key? key}) : super(key: key);

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  // Sample medical history data - keeping static data as requested
  final List<Map<String, dynamic>> _medicalHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'doctor': 'Dr. Sarah Johnson',
      'diagnosis': 'Seasonal Allergies',
      'treatment': 'Antihistamines prescribed',
      'notes': 'Avoid pollen exposure, follow up in 2 weeks',
      'severity': 'Low',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'doctor': 'Dr. Michael Chen',
      'diagnosis': 'Hypertension',
      'treatment': 'Lisinopril 10mg daily',
      'notes': 'Blood pressure under control, reduce sodium intake',
      'severity': 'Medium',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 90)),
      'doctor': 'Dr. Angela Lopez',
      'diagnosis': 'Annual Physical Exam',
      'treatment': 'None',
      'notes': 'All vitals normal, recommended regular exercise',
      'severity': 'None',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal.shade700,
        title: Text(
          'Medical History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _addNewEntry(context),
            tooltip: 'Add New Entry',
          ),
        ],
      ),
      body: _medicalHistory.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _medicalHistory.length,
        itemBuilder: (context, index) {
          final entry = _medicalHistory[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.teal.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('MMMM d, y').format(entry['date']),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSeverityChip(entry['severity']),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildDetailRow(
                    Icons.person,
                    'Doctor',
                    entry['doctor'],
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.medical_services,
                    'Diagnosis',
                    entry['diagnosis'],
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.medication,
                    'Treatment',
                    entry['treatment'],
                  ),
                  if (entry['notes'] != null && entry['notes'].isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          Icons.note_alt_outlined,
                          'Notes',
                          entry['notes'],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _medicalHistory.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: () => _addNewEntry(context),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_information_outlined,
                size: 80,
                color: Colors.teal.shade300,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'No Medical History',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your health journey by adding your first medical record',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _addNewEntry(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add New Entry',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.teal.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityChip(String severity) {
    Color color;
    IconData icon;

    switch (severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.info;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            severity,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewEntry(BuildContext context) {
    final diagnosisController = TextEditingController();
    final doctorController = TextEditingController();
    final treatmentController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSeverity = 'Low';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_circle, color: Colors.teal.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Medical Entry',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: doctorController,
                  decoration: InputDecoration(
                    labelText: 'Doctor Name',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.person, color: Colors.teal.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Diagnosis',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.medical_services, color: Colors.teal.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: treatmentController,
                  decoration: InputDecoration(
                    labelText: 'Treatment',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.medication, color: Colors.teal.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.note_alt, color: Colors.teal.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                    ),
                  ),
                  maxLines: 3,
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  items: ['High', 'Medium', 'Low', 'None']
                      .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  ))
                      .toList(),
                  decoration: InputDecoration(
                    labelText: 'Severity',
                    labelStyle: GoogleFonts.poppins(),
                    prefixIcon: Icon(Icons.warning_amber, color: Colors.teal.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    selectedSeverity = value!;
                  },
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Add validation and save logic here
              if (diagnosisController.text.isNotEmpty) {
                setState(() {
                  _medicalHistory.insert(0, {
                    'date': DateTime.now(),
                    'doctor': doctorController.text.isEmpty
                        ? 'Not specified'
                        : doctorController.text,
                    'diagnosis': diagnosisController.text,
                    'treatment': treatmentController.text.isEmpty
                        ? 'Not specified'
                        : treatmentController.text,
                    'notes': notesController.text,
                    'severity': selectedSeverity,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Medical entry added successfully',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.teal.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a diagnosis',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Save Entry',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}