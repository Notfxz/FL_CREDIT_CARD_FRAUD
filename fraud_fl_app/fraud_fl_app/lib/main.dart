import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FraudFLApp());
}

class FraudFLApp extends StatelessWidget {
  const FraudFLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Federated Learning Client',
      home: const ClientDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  String status = "idle";
  double? accuracy;
  double? auc;
  double? recall;

  Timer? timer;

  final String apiBase = "http://127.0.0.1:8000";

  // -----------------------------
  // START TRAINING
  // -----------------------------
  Future<void> startTraining() async {
    await http.post(
      Uri.parse("$apiBase/train"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"client_id": "client_1"}),
    );

    startPolling();
  }

  // -----------------------------
  // POLL METRICS
  // -----------------------------
  void startPolling() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final res = await http.get(Uri.parse("$apiBase/metrics"));
      final data = jsonDecode(res.body);

      setState(() {
        status = data["status"];
        accuracy = data["accuracy"];
        auc = data["auc"];
        recall = data["recall"];
      });

      if (status == "completed" || status == "failed") {
        timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Federated Client Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Client Status: $status",
                style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            if (accuracy != null)
              Text("Accuracy: ${accuracy!.toStringAsFixed(3)}"),

            if (auc != null)
              Text("AUC: ${auc!.toStringAsFixed(3)}"),

            if (recall != null)
              Text("Recall: ${recall!.toStringAsFixed(3)}"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: startTraining,
              child: const Text("Start Local Training"),
            ),
          ],
        ),
      ),
    );
  }
}
