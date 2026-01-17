import 'package:http/http.dart' as http;
import 'dart:convert';

class FederatedService {
  // Replace with your PC's IPv4 address (Run 'ipconfig' in CMD to find it)
  static const String baseUrl = "http://192.168.1.15:5000"; 

  Future<bool> startTraining(String clientId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"client_id": clientId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchMetrics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/metrics'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching metrics: $e");
    }
    return {};
  }
}