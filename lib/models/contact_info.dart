/// One of a user's chosen contact methods (Teléfono / Email / Red social),
/// as surfaced to someone else - on a public profile or an event's
/// "Contactar con el creador" section. Carries the resolved value directly
/// (e.g. the actual phone number), not just which method was picked.
class ContactInfo {
  final String? phone;
  final String? email;
  final String? socialPlatform;
  final String? socialValue;

  const ContactInfo({
    this.phone,
    this.email,
    this.socialPlatform,
    this.socialValue,
  });

  bool get hasAny => phone != null || email != null || socialValue != null;

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    final social = json['social'] as Map<String, dynamic>?;
    return ContactInfo(
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      socialPlatform: social?['platform'] as String?,
      socialValue: social?['value'] as String?,
    );
  }
}
