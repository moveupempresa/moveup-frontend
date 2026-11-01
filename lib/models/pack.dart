/// Currencies offered in the pack price's currency selector.
const kPackCurrencies = [
  'EUR',
  'USD',
  'GBP',
  'MXN',
  'COP',
  'ARS',
  'PEN',
  'CLP',
  'BRL',
];

enum PaymentType {
  offline('offline', 'Efectivo'),
  bizum('bizum', 'Bizum'),
  paypal('paypal', 'PayPal'),
  bankTransfer('bank_transfer', 'Transferencia bancaria'),
  online('online', 'Plataforma externa (Stripe, Monei...)');

  const PaymentType(this.value, this.label);
  final String value;
  final String label;

  /// Every method except cash needs somewhere/something for the student to
  /// pay to - a phone, an account, a link - which doubles as what the
  /// organizer fills in to tell them where.
  bool get needsPaymentDetails => this != offline;

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
  final String currency;
  final PaymentType paymentType;
  final String? paymentDetails;
  final String? bizumConcept;
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
    this.currency = 'EUR',
    required this.paymentType,
    this.paymentDetails,
    this.bizumConcept,
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
    currency: json['currency'] as String? ?? 'EUR',
    paymentType: PaymentType.fromValue(json['paymentType'] as String),
    paymentDetails: json['paymentDetails'] as String?,
    bizumConcept: json['bizumConcept'] as String?,
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
