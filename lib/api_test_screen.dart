import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pharmacy_app/services/api_service.dart';
import 'package:pharmacy_app/services/product_service.dart';
import 'dart:convert';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ProductService _productService = ProductService();
  final Dio _dio = ApiService().dio;
  
  String _result = 'Chưa có kết quả. Nhấn nút bên dưới để test.';
  bool _isLoading = false;

  // Test 1: Kiểm tra kết nối cơ bản
  Future<void> _testBasicConnection() async {
    setState(() {
      _isLoading = true;
      _result = '🔄 Đang kiểm tra kết nối...';
    });

    try {
      final response = await _dio.get('/products');
      
      setState(() {
        _result = '''
✅ KẾT NỐI THÀNH CÔNG!

📊 Status Code: ${response.statusCode}

📦 Response Data Type: ${response.data.runtimeType}

📝 Raw Response:
${JsonEncoder.withIndent('  ').convert(response.data)}

🔢 Số lượng products: ${response.data is List ? response.data.length : (response.data is Map && response.data['data'] is List ? response.data['data'].length : 'Unknown')}
''';
      });
    } on DioException catch (e) {
      setState(() {
        _result = '''
❌ LỖI KẾT NỐI!

🔴 Error Type: ${e.type}

📝 Message: ${e.message}

🌐 URL: ${e.requestOptions.uri}

${e.response != null ? '''
📊 Status Code: ${e.response?.statusCode}

📦 Response Data:
${e.response?.data}
''' : ''}

💡 Gợi ý:
${_getSuggestion(e)}
''';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Lỗi không xác định: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 2: Kiểm tra parse ProductModel
  Future<void> _testParseProducts() async {
    setState(() {
      _isLoading = true;
      _result = '🔄 Đang kiểm tra parse products...';
    });

    try {
      final products = await _productService.getAllProducts();
      
      setState(() {
        _result = '''
✅ PARSE THÀNH CÔNG!

🔢 Số sản phẩm: ${products.length}

${products.isNotEmpty ? '''
📦 Sản phẩm đầu tiên:
- ID: ${products[0].id}
- Tên: ${products[0].name}
- Giá: ${products[0].price}
- Stock: ${products[0].stock}
- Category: ${products[0].categories.name}
- Images: ${products[0].images.length} ảnh
''' : '⚠️ Không có sản phẩm nào'}
''';
      });
    } catch (e) {
      setState(() {
        _result = '''
❌ LỖI PARSE!

📝 Error: $e

💡 Có thể:
- Cấu trúc JSON không khớp với ProductModel
- Thiếu field bắt buộc
- Định dạng dữ liệu không đúng
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 3: Kiểm tra baseURL
  Future<void> _testBaseUrl() async {
    setState(() {
      _isLoading = true;
      _result = '🔄 Đang kiểm tra baseURL...';
    });

    try {
      // Test các endpoint khác nhau
      final endpoints = ['/products', '/categories'];
      final results = <String, dynamic>{};

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.get(endpoint);
          results[endpoint] = {
            'status': '✅ ${response.statusCode}',
            'type': response.data.runtimeType.toString(),
            'dataKeys': response.data is Map 
                ? (response.data as Map).keys.take(3).join(', ')
                : 'List with ${response.data is List ? response.data.length : 0} items',
          };
        } catch (e) {
          results[endpoint] = {
            'status': '❌ Error',
            'error': e.toString().length > 100 
                ? e.toString().substring(0, 100) + '...'
                : e.toString(),
          };
        }
      }

      setState(() {
        _result = '''
🌐 BASE URL: ${ApiService.baseUrl}

📡 Kết quả kiểm tra endpoints:

${results.entries.map((e) => '''
${e.key}:
  Status: ${e.value['status']}
  Type: ${e.value['type'] ?? 'N/A'}
  ${e.value['dataKeys'] != null ? 'Data: ${e.value['dataKeys']}' : ''}
  ${e.value['error'] != null ? 'Error: ${e.value['error']}' : ''}
''').join('\n')}
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getSuggestion(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return '''
- Backend chưa chạy
- URL không đúng
- Network quá chậm
''';
    } else if (e.type == DioExceptionType.connectionError) {
      return '''
- Backend chưa chạy hoặc sai port
- Nếu test trên emulator: đổi localhost → 10.0.2.2
- Nếu test trên thiết bị thật: đổi localhost → IP máy tính (VD: 192.168.1.x)
- Kiểm tra firewall
''';
    } else if (e.response?.statusCode == 404) {
      return '''
- Endpoint /api/products không tồn tại
- Kiểm tra lại route trong backend
''';
    }
    return '- Kiểm tra log backend để biết chi tiết';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Đang test...'),
                          ],
                        ),
                      )
                    : SelectableText(
                        _result,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Base URL: ${ApiService.baseUrl}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testBasicConnection,
                  icon: const Icon(Icons.wifi),
                  label: const Text('1. Test Kết Nối & Response'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testParseProducts,
                  icon: const Icon(Icons.inventory),
                  label: const Text('2. Test Parse Products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testBaseUrl,
                  icon: const Icon(Icons.language),
                  label: const Text('3. Test Multiple Endpoints'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
