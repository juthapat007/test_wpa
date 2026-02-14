class Profile {
  final int id;
  final int companyId;
  final int teamId;
  final String name;
  final String title;
  final String email;
  final String avatarUrl;
  final String company;
  final String team;

  Profile({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.avatarUrl,
    required this.company,
    required this.team,
    required this.companyId,
    required this.teamId,
  });
}
