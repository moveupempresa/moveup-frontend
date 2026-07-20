class PopularProfile {
  final String userId;
  final String username;
  final String displayName;
  final String artisticName;
  final String bio;
  final String? profileImage;
  final String city;
  final String country;
  final int experience;
  final int followersCount;
  final bool isFollowing;

  const PopularProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.artisticName = '',
    this.bio = '',
    this.profileImage,
    required this.city,
    required this.country,
    this.experience = 0,
    required this.followersCount,
    required this.isFollowing,
  });

  String get name => displayName.isNotEmpty ? displayName : username;

  factory PopularProfile.fromJson(Map<String, dynamic> json) => PopularProfile(
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String? ?? '',
        artisticName: json['artisticName'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        profileImage: json['profileImage'] as String?,
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        experience: json['experience'] as int? ?? 0,
        followersCount: json['followersCount'] as int,
        isFollowing: json['isFollowing'] as bool,
      );
}
