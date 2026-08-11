enum SubscriptionPlan {
  free,
  pro;

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere((plan) => plan.name == value);
  }
}

class User {
  final String id;
  final String email;
  final String username;
  final SubscriptionPlan subscriptionPlan;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.subscriptionPlan,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      subscriptionPlan: SubscriptionPlan.fromString(
        json['subscriptionPlan'] as String,
      ),
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
