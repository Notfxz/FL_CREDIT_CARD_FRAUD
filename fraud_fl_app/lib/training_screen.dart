import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrainingScreen extends StatefulWidget {
  @override
  _TrainingScreenState createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final ApiService _api = ApiService();
  
  Map<String, dynamic> _status = {
    'status': 'idle',
    'progress': 0,
    'round': 0,
    'accuracy': 0.0,
    'recall': 0.0,
    'auc': 0.0,
    'message': 'Ready to train'
  };

  @override
  void dispose() {
    _api.stopPolling();
    super.dispose();
  }

  Future<void> _startTraining() async {
    try {
      await _api.startTraining('client_1');
      
      // Start real-time polling
      _api.startPolling((status) {
        setState(() {
          _status = status;
        });
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTraining = _status['status'] == 'training';
    final progress = (_status['progress'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text('Federated Learning Client'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _getStatusIcon(),
                      size: 60,
                      color: _getStatusColor(),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _status['status'].toString().toUpperCase(),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _status['message'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // Progress Bar
            if (isTraining) ...[
              Text('Progress: ${progress.toInt()}%'),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              SizedBox(height: 10),
              Text('Round: ${_status['round']} / 10'),
            ],

            SizedBox(height: 20),

            // Metrics Cards
            Row(
              children: [
                Expanded(child: _buildMetricCard('Accuracy', _status['accuracy'])),
                SizedBox(width: 10),
                Expanded(child: _buildMetricCard('Recall', _status['recall'])),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMetricCard('AUC', _status['auc'])),
                SizedBox(width: 10),
                Expanded(child: _buildMetricCard('Loss', _status['loss'])),
              ],
            ),

            Spacer(),

            // Action Button
            ElevatedButton(
              onPressed: isTraining ? null : _startTraining,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
                backgroundColor: Colors.deepPurple,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                isTraining ? 'TRAINING...' : 'START TRAINING',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, dynamic value) {
    Widget _buildMetricCard(String title, double? value, IconData icon, Color color) {
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          // The ?? 0.0 ensures the app never calls toStringAsFixed on a null
          Text(
            (value ?? 0.0).toStringAsFixed(4),
            style: TextStyle(fontSize: 18, color: color),
          ),
        ],
      ),
    ),
  );
}

  IconData _getStatusIcon() {
    switch (_status['status']) {
      case 'training':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.play_circle_outline;
    }
  }

  Color _getStatusColor() {
    switch (_status['status']) {
      case 'training':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}