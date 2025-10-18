import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({Key? key}) : super(key: key);

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  // Sample medical history data
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
      appBar: AppBar(
        title: const Text('Medical History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewEntry(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _medicalHistory.length,
          itemBuilder: (context, index) {
            final entry = _medicalHistory[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM d, y').format(entry['date']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildSeverityChip(entry['severity']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.person, entry['doctor']),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.medical_services, entry['diagnosis']),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.medication, entry['treatment']),
                    if (entry['notes'] != null && entry['notes'].isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.note, entry['notes']),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityChip(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.yellow;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        severity,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  void _addNewEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Medical Entry'),
        content: SingleChildScrollView(
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    icon: Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Treatment',
                    icon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    icon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  items: ['High', 'Medium', 'Low', 'None']
                      .map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    icon: Icon(Icons.warning),
                  ),
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save logic here
              Navigator.pop(context);
            },
            child: const Text('Save Entry'),
          ),
        ],
      ),
    );
  }
}