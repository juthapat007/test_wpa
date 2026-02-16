import 'package:test_wpa/features/schedules/domain/entities/leave_type.dart';

class LeaveTypeModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final bool active;
  final String? nameTh;
  final String? nameEn;

  LeaveTypeModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.active,
    this.nameTh,
    this.nameEn,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      active: json['active'] ?? true,
      nameTh: json['name_th'],
      nameEn: json['name_en'],
    );
  }

  LeaveType toEntity() {
    return LeaveType(
      id: id,
      code: code,
      name: name,
      description: description,
      active: active,
      nameTh: nameTh,
      nameEn: nameEn,
    );
  }
}
