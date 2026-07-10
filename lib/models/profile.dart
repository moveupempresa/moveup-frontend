const _videoExtensions = ['.mp4', '.mov', '.avi'];

bool isGalleryVideoUrl(String url) =>
    _videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));

class SocialLinks {
  final String instagram;
  final String tiktok;
  final String youtube;
  final String facebook;
  final String twitter;

  const SocialLinks({
    required this.instagram,
    required this.tiktok,
    required this.youtube,
    required this.facebook,
    required this.twitter,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'] as String? ?? '',
      tiktok: json['tiktok'] as String? ?? '',
      youtube: json['youtube'] as String? ?? '',
      facebook: json['facebook'] as String? ?? '',
      twitter: json['twitter'] as String? ?? '',
    );
  }

  Map<String, String> toJson() => {
        'instagram': instagram,
        'tiktok': tiktok,
        'youtube': youtube,
        'facebook': facebook,
        'twitter': twitter,
      };

  SocialLinks copyWith({
    String? instagram,
    String? tiktok,
    String? youtube,
    String? facebook,
    String? twitter,
  }) {
    return SocialLinks(
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      youtube: youtube ?? this.youtube,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
    );
  }
}

class Profile {
  final String id;
  final String userId;
  final String displayName;
  final String artisticName;
  final String bio;
  final String city;
  final String country;
  final String? profileImage;
  final List<String> gallery;
  final String websiteUrl;
  final String cvUrl;
  final int experience;
  final SocialLinks socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.artisticName,
    required this.bio,
    required this.city,
    required this.country,
    required this.profileImage,
    required this.gallery,
    required this.websiteUrl,
    required this.cvUrl,
    required this.experience,
    required this.socialLinks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? '',
      artisticName: json['artisticName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      gallery: (json['gallery'] as List<dynamic>?)?.cast<String>() ?? const [],
      websiteUrl: json['websiteUrl'] as String? ?? '',
      cvUrl: json['cvUrl'] as String? ?? '',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      socialLinks: SocialLinks.fromJson(
        (json['socialLinks'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Profile copyWith({
    String? displayName,
    String? artisticName,
    String? bio,
    String? city,
    String? country,
    String? profileImage,
    List<String>? gallery,
    String? websiteUrl,
    String? cvUrl,
    int? experience,
    SocialLinks? socialLinks,
  }) {
    return Profile(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      artisticName: artisticName ?? this.artisticName,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      profileImage: profileImage ?? this.profileImage,
      gallery: gallery ?? this.gallery,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      experience: experience ?? this.experience,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
