import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/checkin_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final data = await CheckInService.getHistory();
    setState(() {
    
      history = data.reversed.toList(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Participation History"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                "No participation history yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.star, color: Colors.white),
                    ),
                
                    title: Text(
                      item['fairName'] ?? 'Unknown Fair',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Points Earned: +${item['points'] ?? '0'}",
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Time: ${item['timestamp'] ?? 'Unknown time'}",
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
