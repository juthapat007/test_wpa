class User {
  final int id;
  final String name;
  final String email;
  final String avatarUrl;
  final String password;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      password: json['password'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
    );
  }
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
//แปลง object ให้เป็น json เพื่อส่งไปยัง api