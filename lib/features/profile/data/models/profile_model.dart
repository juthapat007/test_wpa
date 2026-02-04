class ProfileModel {
  final int id;
  final String name;
  final String title;
  final String email;
  final String avatarUrl;
  final Company company;
  final Team team;

  ProfileModel({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.avatarUrl,
    required this.company,
    required this.team,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      company: Company.fromJson(json['company']),
      team: Team.fromJson(json['team']),
    );
  }
}

class Company {
  final String name;
  Company({required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(name: json['name'] ?? '');
  }
}

class Team {
  final String name;
  Team({required this.name});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(name: json['name'] ?? '');
  }
}
