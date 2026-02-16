class LeaveType {
  final int id;
  final String code;
  final String name;
  final String? description;
  final bool active;
  final String? nameTh;
  final String? nameEn;

  const LeaveType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.active,
    this.nameTh,
    this.nameEn,
  });

  String get displayName => nameEn ?? name;
}
