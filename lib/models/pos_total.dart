class PosTotal {
  final int totalAmount;
  final int totalFees;
  final int totalNet;

  PosTotal({
    required this.totalAmount,
    required this.totalFees,
    required this.totalNet,
  });

  factory PosTotal.zero() {
    return PosTotal(totalAmount: 0, totalFees: 0, totalNet: 0);
  }

  factory PosTotal.fromJson(Map<String, dynamic> json) {
    return PosTotal(
      totalAmount: json['total_amount'] ?? 0,
      totalFees: json['total_fees'] ?? 0,
      totalNet: json['total_net'] ?? 0,
    );
  }
}
