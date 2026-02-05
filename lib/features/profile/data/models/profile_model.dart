import 'package:test_wpa/features/profile/domain/entities/profile.dart';

import '../../domain/entities/profile.dart'; // import Profile entity

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
      String companyName;
  if (json.containsKey('company_name')) {
    // Format 1: delegate response มี company_name ตรงๆ
    companyName = json['company_name'] ?? '';
  } else if (json.containsKey('company') && json['company'] is Map) {
    // Format 2: profile response มี company object
    companyName = json['company']['name'] ?? '';
  } else {
    companyName = '';
  }
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

  // แปลงจาก Model ไปเป็น Entity
  Profile toEntity() {
    return Profile(
      id: id,
      name: name,
      title: title,
      email: email,
      avatarUrl: avatarUrl,
      companyName: company.name,
      teamName: team.name,
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
