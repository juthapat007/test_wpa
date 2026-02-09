// lib/features/meeting/data/repository/table_repository_impl.dart

import 'package:test_wpa/features/meeting/data/models/table_view_model.dart';
import 'package:test_wpa/features/meeting/data/services/table_api.dart';
import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';
import 'package:test_wpa/features/meeting/domain/repositories/table_repository.dart';

class TableRepositoryImpl implements TableRepository {
  final TableApi api;

  TableRepositoryImpl({required this.api});

  @override
  Future<TableViewResponse> getTableView({String? date, String? time}) async {
    try {
      final json = await api.getTableView(date: date, time: time);
      final model = TableViewResponseModel.fromJson(json);
      return model.toEntity();
    } catch (e) {
      print('❌ TableRepositoryImpl error: $e');
      throw Exception('Failed to load table view: $e');
    }
  }
}
