class Profile {
  final int id;
  final String name;
  final String title;
  final String email;
  final String avatarUrl;
  final String companyName;
  final String teamName;

  Profile({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.avatarUrl,
    required this.companyName,
    required this.teamName,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      companyName: json['company_name'],
      teamName: json['team_name'] ?? '',
    );
  }
}
