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
  final bool isFavorite;

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
    this.isFavorite = false,
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
    isFavorite: json['isFavorite'] as bool? ?? false,
  );

  PopularProfile copyWith({bool? isFollowing, bool? isFavorite}) {
    return PopularProfile(
      userId: userId,
      username: username,
      displayName: displayName,
      artisticName: artisticName,
      bio: bio,
      profileImage: profileImage,
      city: city,
      country: country,
      experience: experience,
      followersCount: followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
