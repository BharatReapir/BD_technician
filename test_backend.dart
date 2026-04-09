import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://us-central1-bharat-doorstep-native.cloudfunctions.net';
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/createWalletRechargeOrder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'technicianId': 'test_tech_123',
        'amount': 118.0,
      }),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch(e) {
    print('Error: $e');
  }
}
