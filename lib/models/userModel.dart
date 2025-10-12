class UserModel {
  String uid;
  String name;
  String username;
  String email;
  String? photoUrl;
  bool isOnline;
  String? status;

  UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    this.photoUrl,
    this.isOnline = false,
    this.status,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'username': username,
    'email': email,
    'photoUrl': photoUrl,
    'isOnline': isOnline,
    'status': status ?? '',
  };

  static UserModel fromJson(Map<dynamic, dynamic> json) => UserModel(
    uid: json['uid'],
    name: json['name'],
    username: json['username'],
    email: json['email'],
    photoUrl: json['photoUrl'],
    isOnline: json['isOnline'] ?? false,
    status: json['status'] ?? '',
  );
}
