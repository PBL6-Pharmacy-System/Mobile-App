class ApiConfig {
  // ===========================================
  // 🔧 CONFIGURATION - Choose based on your setup
  // ===========================================

  // For Android Emulator: use 10.0.2.2
  // static const String _host = '10.0.2.2';

  // For iOS Simulator: use localhost
  // static const String _host = 'localhost';

  // For Real Device: use your computer's IP address
  // Check with: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _host =
      '192.168.1.88'; // 👈 CHANGE THIS to your PC's WiFi IP

  static const String _port = '3000';
  static const String baseUrl = 'http://$_host:$_port/api';

  // API Endpoints
  static const String flashSalesActive = '$baseUrl/flashsales/active';
  static const String products = '$baseUrl/products';
  static const String categories = '$baseUrl/categories';
  static const String auth = '$baseUrl/auth';
  static const String cart = '$baseUrl/cart';
  static const String orders = '$baseUrl/orders';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);

  // Common headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
