const _videoExtensions = ['.mp4', '.mov', '.avi'];

bool isGalleryVideoUrl(String url) =>
    _videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));

class GalleryItem {
  final String id;
  final List<String> urls;

  const GalleryItem({required this.id, required this.urls});

  bool get isVideo => isGalleryVideoUrl(urls.first);

  factory GalleryItem.fromJson(Map<String, dynamic> json) => GalleryItem(
    id: json['id'] as String,
    urls: (json['urls'] as List<dynamic>).cast<String>(),
  );
}

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

/// Which of the user's already-filled-in fields (their account phone/
/// email, or one of [SocialLinks]) they've chosen to surface as contact
/// info - on their own profile, and (for event creators) on their events.
class ContactMethods {
  final bool phone;
  final bool email;
  final bool socialEnabled;
  final String? socialPlatform;

  const ContactMethods({
    required this.phone,
    required this.email,
    required this.socialEnabled,
    required this.socialPlatform,
  });

  static const empty = ContactMethods(
    phone: false,
    email: false,
    socialEnabled: false,
    socialPlatform: null,
  );

  bool get hasAny => phone || email || socialEnabled;

  factory ContactMethods.fromJson(Map<String, dynamic>? json) {
    final social = json?['social'] as Map<String, dynamic>?;
    return ContactMethods(
      phone: json?['phone'] as bool? ?? false,
      email: json?['email'] as bool? ?? false,
      socialEnabled: social?['enabled'] as bool? ?? false,
      socialPlatform: social?['platform'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'email': email,
    'social': {'enabled': socialEnabled, 'platform': socialPlatform},
  };

  ContactMethods copyWith({
    bool? phone,
    bool? email,
    bool? socialEnabled,
    String? socialPlatform,
  }) {
    return ContactMethods(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      socialEnabled: socialEnabled ?? this.socialEnabled,
      socialPlatform: socialPlatform ?? this.socialPlatform,
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
  final List<GalleryItem> gallery;
  final String websiteUrl;
  final String cvUrl;
  final int experience;
  final SocialLinks socialLinks;
  final ContactMethods contactMethods;
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
    required this.contactMethods,
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
      gallery:
          (json['gallery'] as List<dynamic>?)
              ?.map((g) => GalleryItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      websiteUrl: json['websiteUrl'] as String? ?? '',
      cvUrl: json['cvUrl'] as String? ?? '',
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      socialLinks: SocialLinks.fromJson(
        (json['socialLinks'] as Map<String, dynamic>?) ?? {},
      ),
      contactMethods: ContactMethods.fromJson(
        json['contactMethods'] as Map<String, dynamic>?,
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
    List<GalleryItem>? gallery,
    String? websiteUrl,
    String? cvUrl,
    int? experience,
    SocialLinks? socialLinks,
    ContactMethods? contactMethods,
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
      contactMethods: contactMethods ?? this.contactMethods,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
