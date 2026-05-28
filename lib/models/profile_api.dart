class ProfileApi {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String motivation;
  final String? profilePhoto;

  const ProfileApi({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.motivation,
    required this.profilePhoto,
  });

  factory ProfileApi.fromJson(Map<String, dynamic> json) {
    return ProfileApi(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      motivation: json['motivation']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
    );
  }
}
