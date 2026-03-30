import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Change this to your PC's local IP when testing on a real device
  // static const String baseUrl = 'http://10.0.2.2:5000/api'; //--> this for local
  // static const String baseUrl = 'http://192.168.29.167:5000/api'; //-->this for 
static const String baseUrl = 'https://thumbnail-ai-backend-30i1.onrender.com/api'; //-->aftre deploy

Future<Map<String, dynamic>> generateThumbnail({
    required String prompt,
    required String userId,
    required List<File> images,
  }) async {
    final uri = Uri.parse('$baseUrl/thumbnail/generate');
    final request = http.MultipartRequest('POST', uri);

    request.fields['prompt'] = prompt;
    request.fields['user_id'] = userId;

    for (final image in images) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }

    try {
      // ↓ increased from 60s to 180s
      final response = await request.send().timeout(const Duration(seconds: 300));
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to server: $e'};
    }
  }
}