import 'package:test_wpa/features/meeting/domain/entities/table_view_entities.dart';

abstract class TableRepository {
  Future<TableViewResponse> getTableView({String? date, String? time});
}
