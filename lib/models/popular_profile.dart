class PopularProfile {
  final String userId;
  final String username;
  final String displayName;
  final String? profileImage;
  final String city;
  final String country;
  final int followersCount;
  final bool isFollowing;

  const PopularProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.profileImage,
    required this.city,
    required this.country,
    required this.followersCount,
    required this.isFollowing,
  });

  String get name => displayName.isNotEmpty ? displayName : username;

  factory PopularProfile.fromJson(Map<String, dynamic> json) => PopularProfile(
        userId: json['userId'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String? ?? '',
        profileImage: json['profileImage'] as String?,
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        followersCount: json['followersCount'] as int,
        isFollowing: json['isFollowing'] as bool,
      );
}
