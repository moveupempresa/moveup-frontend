enum PaymentType {
  bizum('bizum', 'Bizum'),
  paypal('paypal', 'PayPal'),
  offline('offline', 'Efectivo'),
  online('online', 'Pago online');

  const PaymentType(this.value, this.label);
  final String value;
  final String label;

  /// Bizum and PayPal are paid outside the app, same as Efectivo - the
  /// organizer confirms payment manually rather than through the in-app
  /// payment flow.
  bool get needsPaymentDetails => this == bizum || this == paypal;

  static PaymentType fromValue(String value) =>
      PaymentType.values.firstWhere((e) => e.value == value);
}

enum PackType {
  fixed('fixed', 'Fijo'),
  customizable('customizable', 'Personalizable');

  const PackType(this.value, this.label);
  final String value;
  final String label;

  static PackType fromValue(String value) =>
      PackType.values.firstWhere((e) => e.value == value);
}

enum ApprovalMode {
  automatic('automatic', 'Automático'),
  manual('manual', 'Manual');

  const ApprovalMode(this.value, this.label);
  final String value;
  final String label;

  static ApprovalMode fromValue(String value) =>
      ApprovalMode.values.firstWhere((e) => e.value == value);
}

class Pack {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final PaymentType paymentType;
  final String? paymentDetails;
  final PackType packType;
  final ApprovalMode approvalMode;
  final int? maxSelectableSessions;
  final List<String> sessionIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int confirmedCount;
  final int pendingRequestsCount;
  final bool isSignedUp;
  final bool isWaitlisted;
  final bool isPending;
  final bool isAwaitingPayment;
  final bool myHasPaid;
  final List<String> mySelectedSessionIds;

  const Pack({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.paymentType,
    this.paymentDetails,
    required this.packType,
    required this.approvalMode,
    this.maxSelectableSessions,
    required this.sessionIds,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedCount = 0,
    this.pendingRequestsCount = 0,
    this.isSignedUp = false,
    this.isWaitlisted = false,
    this.isPending = false,
    this.isAwaitingPayment = false,
    this.myHasPaid = false,
    this.mySelectedSessionIds = const [],
  });

  factory Pack.fromJson(Map<String, dynamic> json) => Pack(
    id: json['id'] as String,
    eventId: json['eventId'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    paymentType: PaymentType.fromValue(json['paymentType'] as String),
    paymentDetails: json['paymentDetails'] as String?,
    packType: PackType.fromValue(json['packType'] as String),
    approvalMode: ApprovalMode.fromValue(json['approvalMode'] as String),
    maxSelectableSessions: json['maxSelectableSessions'] as int?,
    sessionIds: json['sessionIds'] != null
        ? (json['sessionIds'] as List<dynamic>).cast<String>()
        : const [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    confirmedCount: (json['confirmedCount'] as num?)?.toInt() ?? 0,
    pendingRequestsCount: (json['pendingRequestsCount'] as num?)?.toInt() ?? 0,
    isSignedUp: json['isSignedUp'] as bool? ?? false,
    isWaitlisted: json['isWaitlisted'] as bool? ?? false,
    isPending: json['isPending'] as bool? ?? false,
    isAwaitingPayment: json['isAwaitingPayment'] as bool? ?? false,
    myHasPaid: json['myHasPaid'] as bool? ?? false,
    mySelectedSessionIds: json['mySelectedSessionIds'] != null
        ? (json['mySelectedSessionIds'] as List<dynamic>).cast<String>()
        : const [],
  );
}
