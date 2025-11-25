class User {
  final int id;
  final String name;
  final String token;

  User({required this.id, required this.name, required this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'] ?? json['id'],
      name: json['user']['name'] ?? json['name'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'token': token,
    };
  }
}