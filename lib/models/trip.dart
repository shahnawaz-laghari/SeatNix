const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${(date.year % 100).toString().padLeft(2, '0')}';
}

String formatLongDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} '
      '${_months[date.month - 1]} ${date.year}';
}

class Trip {
  const Trip({
    required this.reference,
    required this.from,
    required this.to,
    required this.seat,
    required this.travelDate,
    required this.total,
    required this.paymentMethod,
    required this.paymentDetail,
    required this.paidAt,
  });

  final String reference;
  final String from;
  final String to;
  final String seat;
  final DateTime travelDate;
  final int total;
  final String paymentMethod;
  final String paymentDetail;
  final DateTime paidAt;

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'from': from,
        'to': to,
        'seat': seat,
        'travelDate': travelDate.toIso8601String(),
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentDetail': paymentDetail,
        'paidAt': paidAt.toIso8601String(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        reference: json['reference'] as String,
        from: json['from'] as String,
        to: json['to'] as String,
        seat: json['seat'] as String,
        travelDate: DateTime.parse(json['travelDate'] as String),
        total: json['total'] as int,
        paymentMethod: json['paymentMethod'] as String,
        paymentDetail: json['paymentDetail'] as String,
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}
