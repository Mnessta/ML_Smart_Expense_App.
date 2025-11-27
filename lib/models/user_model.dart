class AppUser {
  AppUser({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        email: map['email'] as String,
        displayName: map['displayName'] as String?,
      );
}































