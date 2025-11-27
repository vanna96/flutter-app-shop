import 'package:dio/dio.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio dio;

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: "https://laurelfashionvc.com.kh",
      connectTimeout: Duration(seconds: 60),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        "x-api-key": "Testing",
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
    ));
  }

  Future<Response> get(String endpoint) async {
    return await dio.get(endpoint);
  }
}
