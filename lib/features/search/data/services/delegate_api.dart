import 'package:dio/dio.dart';

class DelegateApi {
  final Dio dio;

  DelegateApi(this.dio);

  Future<Map<String, dynamic>> searchDelegates({
    String? keyword,
    int page = 1,
    int perPage = 50,
    bool friendsOnly = false,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (friendsOnly) queryParams['friends_only'] = true;

    final response = await dio.get('/delegates', queryParameters: queryParams);
    return response.data as Map<String, dynamic>;
  }
}
