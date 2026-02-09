class User {
  final int id;
  final String name;
  final String email;
  final String avatarUrl;
  final String? password;
  final String? title;
  final String? companyName;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.password,
    this.title, 
    this.companyName, 
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'] ?? '',
      password: json['password'],
      title: json['title'],
      companyName: json['company_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        if (password != null) 'password': password,
        if (title != null) 'title': title,
        if (companyName != null) 'company_name': companyName,
      };
}