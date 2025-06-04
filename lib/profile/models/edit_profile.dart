class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? location;
  final String? memberSince;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
    this.memberSince,
  });
}
