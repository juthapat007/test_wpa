class ProfileModel {
  final int id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final Company company;
  final String avatarUrl;
  final Team team;
  final bool firstConference;
  final bool spouseAttending;
  final String spouseName;
  final bool needRoom;
  final String bookingNo;

  ProfileModel({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.company,
    required this.avatarUrl,
    required this.team,
    required this.firstConference,
    required this.spouseAttending,
    required this.spouseName,
    required this.needRoom,
    required this.bookingNo,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: Company.fromJson(json['company']),
      avatarUrl: json['avatar_url'] ?? '',
      team: Team.fromJson(json['team']),
      firstConference: json['first_conference'] ?? false,
      spouseAttending: json['spouse_attending'] ?? false,
      spouseName: json['spouse_name'] ?? '',
      needRoom: json['need_room'] ?? false,
      bookingNo: json['booking_no'] ?? '',
    );
  }
}

class Company {
  final int id;
  final String name;
  final String country;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    required this.country,
    this.logoUrl,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      logoUrl: json['logo_url'],
    );
  }
}

class Team {
  final int id;
  final String name;
  final String? countryCode;

  Team({required this.id, required this.name, this.countryCode});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'] ?? '',
      countryCode: json['country_code'],
    );
  }
}
//อาจจะมีปัญหา