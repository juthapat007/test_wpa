import 'package:test_wpa/features/profile/domain/entities/profile.dart';
import 'package:equatable/equatable.dart';

// import Profile entity
class ProfileModel extends Equatable {
  final int id;
  final String name;
  final String title;
  final String email;
  final String avatarUrl;
  final Company company;
  final Team team;
  final int companyId;
  final int teamId;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.avatarUrl,
    required this.company,
    required this.team,
    required this.companyId,
    required this.teamId,
    required phone,
    required firstConference,
    required spouseAttending,
    required spouseName,
    required needRoom,
    required bookingNo,
  });

  @override
  List<Object?> get props => [id, name, title, email, avatarUrl, company, team];

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',

      company: json['company'] != null
          ? Company.fromJson(json['company'])
          : Company(id: 0, name: '', country: ''),

      avatarUrl: json['avatar_url'] ?? '',

      team: json['team'] != null
          ? Team.fromJson(json['team'])
          : Team(id: 0, name: ''),

      firstConference: json['first_conference'] ?? false,
      spouseAttending: json['spouse_attending'] ?? false,
      spouseName: json['spouse_name'] ?? '',
      needRoom: json['need_room'] ?? false,
      bookingNo: json['booking_no'] ?? '',
      companyId: json['company_id'] ?? 0,
      teamId: json['team_id'] ?? 0,
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
      companyId: company.id,
      teamId: team.id,
      company: company.name,
      team: team.name,
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
