import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000"; 

  // Starts the federated training process
  Future<Map<String, dynamic>> startTraining(String clientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"client_id": clientId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"error": "Training connection failed: $e"};
    }
  }

  // Fetches live metrics from the Python API
  Future<Map<String, dynamic>> getMetrics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/metrics'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": "error", "message": "Server error"};
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // Sends data to the Python API for a fraud prediction
  Future<Map<String, dynamic>> getPrediction(List<double> features) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"features": features}),
      );

      // This part prevents the "string indices must be integers" error
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {"error": "Server returned a non-map response: $decoded"};
      }
    } catch (e) {
      return {"error": "Prediction connection failed: $e"};
    }
  }
} // <--- This bracket was likely missing!