import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final ApiService _apiService = ApiService();
  double _accuracy = 0.0, _auc = 0.0, _recall = 0.0;
  String _status = "idle", _predictionResult = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) => _fetchMetrics());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetchMetrics() async {
    try {
      final data = await _apiService.getMetrics();
      if (data is Map) {
        setState(() {
          _accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
          _auc = (data['auc'] as num?)?.toDouble() ?? 0.0;
          _recall = (data['recall'] as num?)?.toDouble() ?? 0.0;
          _status = data['status'] ?? "idle";
        });
      }
    } catch (e) { debugPrint("Metrics error: $e"); }
  }

  Future<void> _handleTestPrediction() async {
  setState(() => _predictionResult = "Checking...");
  try {
    List<double> dummyData = List.generate(2005, (index) => 0.1); 
    final result = await _apiService.getPrediction(dummyData);
    
    setState(() {
      // FIX: Ensure result is actually a Map before using result['...']
      if (result is Map<String, dynamic>) {
        if (result.containsKey('prediction')) {
          _predictionResult = "Result: ${result['prediction']} (${(result['probability'] * 100).toStringAsFixed(2)}%)";
        } else if (result.containsKey('error')) {
          _predictionResult = "Python Error: ${result['error']}";
        } else {
          _predictionResult = "Unknown error format from server";
        }
      } else {
        // If it's a string, we just show the string instead of crashing
        _predictionResult = "Server Error: $result";
      }
    });
  } catch (e) { 
    setState(() => _predictionResult = "Connection Error: $e"); 
  }
}

  @override
  Widget build(BuildContext context) {
    bool isTraining = _status == "training";
    return Scaffold(
      appBar: AppBar(title: const Text("Fraud Detection FL"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              tileColor: isTraining ? Colors.orange[100] : Colors.green[100],
              title: Text("STATUS: ${_status.toUpperCase()}"),
              trailing: isTraining ? const CircularProgressIndicator() : null,
            ),
            const SizedBox(height: 10),
            if (_predictionResult.isNotEmpty) 
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.indigo[900], borderRadius: BorderRadius.circular(8)),
                child: Text(_predictionResult, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildCard("Accuracy", _accuracy, Colors.green),
                  _buildCard("AUC Score", _auc, Colors.blue),
                  _buildCard("Recall", _recall, Colors.orange),
                  _buildCard("Privacy", 1.0, Colors.purple),
                ],
              ),
            ),
            if (_status == "completed")
              ElevatedButton(
                onPressed: _handleTestPrediction, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                child: const Text("TEST PREDICTION LIVE", style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isTraining ? null : () => _apiService.startTraining("client_1"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: Text(isTraining ? "TRAINING..." : "START FEDERATED TRAINING"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String t, double v, Color c) => Card(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(t), Text(v.toStringAsFixed(4), style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold))
    ]),
  );
}