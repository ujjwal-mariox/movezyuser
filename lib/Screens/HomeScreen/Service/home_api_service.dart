import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Screens/HomeScreen/Model/home_page_model.dart';

class HomeApiService {
  /// Fetches all home page data in a single API call.
  /// GET /v1/api/home — public endpoint, no auth needed.
  Future<HomePageData?> fetchHomePage() async {
    try {
      print('[HomeAPI] GET ${ApiUrls.homeUrl}');
      final response = await http.get(
        Uri.parse(ApiUrls.homeUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('[HomeAPI] Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = HomePageData.fromJson(jsonData);
        print('[HomeAPI] Loaded ${data.vehicleTypes.length} vehicles, ${data.promoBanners.length} promos');
        return data;
      } else {
        print('[HomeAPI] Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('[HomeAPI] Exception: $e');
      return null;
    }
  }
}
