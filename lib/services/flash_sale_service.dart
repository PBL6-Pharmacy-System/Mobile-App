import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configs/api_config.dart';
import '../models/flash_sale_product_model.dart';

class FlashSaleService {
  /// Fetch active flash sales from the backend
  Future<List<FlashSaleProductModel>> getActiveFlashSales() async {
    try {
      print('[FlashSaleService] Fetching from: ${ApiConfig.flashSalesActive}');

      final response = await http
          .get(
            Uri.parse(ApiConfig.flashSalesActive),
            headers: ApiConfig.headers,
          )
          .timeout(
            ApiConfig.timeout,
            onTimeout: () {
              print(
                '[FlashSaleService] Request timeout after ${ApiConfig.timeout}',
              );
              throw Exception(
                'Connection timeout - Cannot reach backend server',
              );
            },
          );

      print('[FlashSaleService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Backend returns format: { success: true, data: flashsale }
        if (responseData['data'] == null) {
          print('[FlashSaleService] No active flashsale found');
          return [];
        }

        final flashsaleData = responseData['data'];
        print('[FlashSaleService] Flashsale found: ${flashsaleData['name']}');

        // Get flashsale_products array
        final List<dynamic> flashsaleProducts =
            flashsaleData['flashsale_products'] ?? [];

        print(
          '[FlashSaleService] Found ${flashsaleProducts.length} products in flashsale',
        );

        // Convert flashsale_products to FlashSaleProductModel
        return flashsaleProducts.map((productData) {
          final product = productData['products'] ?? {};
          final productunits = product['productunits'];

          return FlashSaleProductModel.fromJson({
            'id': product['id'],
            'product_id': product['id'],
            'name': product['name'] ?? '',
            'price': product['price'],
            'sale_price': productData['flash_price'],
            'image_url':
                (product['images'] != null &&
                    product['images'] is List &&
                    (product['images'] as List).isNotEmpty)
                ? (product['images'] as List)[0]
                : product['image_url'],
            'description': product['description'] ?? '',
            'usage': product['usage'] ?? '',
            'ingredients': product['ingredients'] ?? '',
            'stock_quantity': productData['stock_limit'],
            'sale_start_time': flashsaleData['start_time'],
            'sale_end_time': flashsaleData['end_time'],
            'category': product['category_id']?.toString(),
            'productunits': productunits,
          });
        }).toList();
      } else if (response.statusCode == 404) {
        // No active flash sales found
        print('[FlashSaleService] No active flashsale (404)');
        return [];
      } else {
        throw Exception('Failed to load flash sales: ${response.statusCode}');
      }
    } catch (e) {
      print('[FlashSaleService] Error: $e');
      throw Exception('Error fetching flash sales: $e');
    }
  }

  /// Fetch flash sale by ID
  Future<FlashSaleProductModel?> getFlashSaleById(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/flashsales/$id'),
            headers: ApiConfig.headers,
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return FlashSaleProductModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load flash sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching flash sale: $e');
    }
  }
}
