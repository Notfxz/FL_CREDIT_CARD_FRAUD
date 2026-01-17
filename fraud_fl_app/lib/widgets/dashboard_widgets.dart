import 'package:flutter/material.dart';

class ComparisonDashboard extends StatelessWidget {
  final double probability;
  final List<dynamic> reasons;
  final double accuracy;
  final double recall; // Added
  final double auc;    // Added
  final String localResult; // Added
  final int roundNumber = 10; 

  const ComparisonDashboard({
    super.key,
    required this.probability,
    required this.reasons,
    required this.accuracy,
    required this.recall,
    required this.auc,
    required this.localResult,
  });

  @override
  Widget build(BuildContext context) {
    bool isFraud = probability > 0.4;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TRAINING ROUND INFO
          _buildTrainingHeader(),
          const SizedBox(height: 15),

          // 2. LOCAL VS GLOBAL COMPARISON
          Row(
            children: [
              _buildSmallCard("Local Model", localResult, Colors.grey),
              const SizedBox(width: 10),
              _buildSmallCard("Federated", isFraud ? "Fraud" : "Safe", isFraud ? Colors.red : Colors.green),
            ],
          ),
          const SizedBox(height: 20),

          // 3. FRAUD DETECTION (VERDICT)
          _buildDetectionVerdict(isFraud),
          const SizedBox(height: 20),

          // 4. PERFORMANCE BARS (Recall & AUC)
          _buildMetricsSection(),
          const SizedBox(height: 20),

          // 5. TRANSACTION LOGS
          const Text("Live Transaction Logs (LSTM Input Window)", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          _buildSequenceLogs(),
          
          const SizedBox(height: 25),
          
          if (isFraud) _buildXAISection(),
        ],
      ),
    );
  }

  Widget _buildTrainingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("🌐 Federated Round: #$roundNumber", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
          Text("Global Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%", 
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Column(
      children: [
        _metricBar("Recall (Fraud Catch Rate)", recall),
        const SizedBox(height: 8),
        _metricBar("AUC-ROC Score", auc),
      ],
    );
  }

  Widget _metricBar(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text("${(val * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: val, backgroundColor: Colors.grey[200], color: Colors.indigo),
      ],
    );
  }

  Widget _buildDetectionVerdict(bool isFraud) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Text("Fraud Probability Score", style: TextStyle(color: Colors.grey)),
              Text("${(probability * 100).toStringAsFixed(0)}%", 
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isFraud ? Colors.red : Colors.green)),
              Text(isFraud ? "SUSPICIOUS ACTIVITY" : "SECURE TRANSACTION", 
                style: TextStyle(fontWeight: FontWeight.bold, color: isFraud ? Colors.red : Colors.green)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSequenceLogs() {
    List<Map<String, String>> logs = [
      {"icon": "🛒", "amt": "\$42.00"},
      {"icon": "⛽", "amt": "\$65.00"},
      {"icon": "☕", "amt": "\$5.50"},
      {"icon": "📦", "amt": "\$120.00"},
      {"icon": "⚠️", "amt": "\$2,500.00"},
    ];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          bool isTarget = index == 4;
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isTarget ? Colors.red : Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              color: isTarget ? Colors.red[50] : Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(logs[index]["icon"]!, style: const TextStyle(fontSize: 18)),
                Text(logs[index]["amt"]!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildXAISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Explainable AI Insights", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        const Divider(),
        ...reasons.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 12))),
            ],
          ),
        )),
      ],
    );
  }
}