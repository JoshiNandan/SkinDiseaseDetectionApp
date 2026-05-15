import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  List<dynamic> _records = [];
  bool _isLoading = true;

  final String baseUrl = "http://10.15.65.92:3000/api/history";

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('apiKey') ?? '';
  }

  // ================= GET =================
  Future<void> fetchRecords() async {
    try {
      final apiKey = await getApiKey();

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'x-api-key': apiKey},
      );

      print("API RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _records = data is List ? data : data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("ERROR: $e");
      setState(() => _isLoading = false);
    }
  }

  // ================= DELETE =================
  Future<void> deleteRecord(int id) async {
    final apiKey = await getApiKey();

    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {'x-api-key': apiKey},
    );

    if (response.statusCode == 200) {
      fetchRecords();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical History"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? const Center(child: Text("No Records"))
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final r = _records[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Top row (Disease + Severity)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r['disease'] ?? 'No Disease',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (r['guidance']?['severity'] == 'HIGH')
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                r['guidance']?['severity'] ?? 'N/A',
                                style: TextStyle(
                                  color: (r['guidance']?['severity'] == 'HIGH')
                                      ? Colors.red
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Region + Area
                        Row(
                          children: [
                            const Icon(
                              Icons.place,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${r['region'] ?? 'N/A'} • ${r['area_type'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Confidence bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Confidence: ${((r['confidence'] ?? 0) * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (r['confidence'] ?? 0).toDouble(),
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  (r['confidence'] ?? 0) > 0.75
                                      ? Colors.green
                                      : (r['confidence'] ?? 0) > 0.5
                                      ? Colors.orange
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Infectious
                        Row(
                          children: [
                            Icon(
                              Icons.coronavirus,
                              size: 16,
                              color: r['guidance']?['infectious'] == true
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              r['guidance']?['infectious'] == true
                                  ? "Infectious"
                                  : "Non-infectious",
                              style: TextStyle(
                                color: r['guidance']?['infectious'] == true
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Tip
                        Text(
                          r['guidance']?['home_care']?[0] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🔹 Delete button aligned right
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteRecord(r['id']),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                ;
              },
            ),
    );
  }
}
