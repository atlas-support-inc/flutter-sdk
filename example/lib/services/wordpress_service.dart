import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPressService {
  static const String baseUrl = 'https://app.kokiri.us/wp-json/public/v1';
  static const int perPage = 10;

  Future<List<Map<String, dynamic>>> getProducts({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products?page=$page&limit=$perPage'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> products = data['products'];
        final Map<String, dynamic> pagination = data['pagination'];
        
        // Store pagination info for later use
        _totalPages = pagination['total_pages'] as int;
        
        return products.map((item) => item as Map<String, dynamic>).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception('Failed to load products: ${error['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Map<String, dynamic>> getProductDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/product/$id'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception('Failed to load product details: ${error['message']}');
      }
    } catch (e) {
      throw Exception('Error fetching product details: $e');
    }
  }

  Future<Map<String, dynamic>> checkout({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String city,
    required String state,
    required String postcode,
    required String country,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checkout/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'billing_email': email,
        'billing_first_name': firstName,
        'billing_last_name': lastName,
        'billing_phone': phone,
        'billing_address': address,
        'billing_city': city,
        'billing_state': state,
        'billing_postcode': postcode,
        'billing_country': country,
        'items': items,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  // Track total pages for pagination
  int _totalPages = 1;
  int get totalPages => _totalPages;
} 