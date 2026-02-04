class User {
  final String? email;
  final String? password;

  User({this.email, this.password});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(email: json['email'], password: json['password']);
  }
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
//แปลง object ให้เป็น json เพื่อส่งไปยัง api