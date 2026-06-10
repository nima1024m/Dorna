
class User {
  String? id;
  String? email;
  String? password;
  String? fullName;
  bool? avatarExist;

  User({
    this.email,
    this.id,
    this.password,
    this.fullName,
    this.avatarExist,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    password = json['password'];
    fullName = json['full_name'] ?? json['name'];
    avatarExist = json['avatar_exist'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['password'] = password;
    data['full_name'] = fullName;
    data['avatar_exist'] = avatarExist;

    return data;
  }
}
