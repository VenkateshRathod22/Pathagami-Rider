/// Response model for Onboarding (Online Spot Payment Initiate) API
/// Endpoint: POST /crew/trip/{schedule_id}/spot-payment/initiate
class CrewSpotPaymentInitiateResponse {
  final bool success;
  final String gateway;
  final String orderId;
  final int amount; // Amount in paise (e.g. 100000 = ₹1,000)
  final double fare; // Main fare in Rupees (e.g. 1000)
  final String currency;
  final String key;
  final String seatNumber;
  final String message;

  const CrewSpotPaymentInitiateResponse({
    required this.success,
    required this.gateway,
    required this.orderId,
    required this.amount,
    required this.fare,
    required this.currency,
    required this.key,
    required this.seatNumber,
    this.message = '',
  });

  factory CrewSpotPaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return CrewSpotPaymentInitiateResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      gateway: json['gateway']?.toString() ?? 'razorpay',
      orderId: json['order_id']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toInt()
          : int.tryParse(json['amount']?.toString() ?? '') ?? 0,
      fare: json['fare'] is num
          ? (json['fare'] as num).toDouble()
          : double.tryParse(json['fare']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      key: json['key']?.toString() ?? '',
      seatNumber: json['seat_number']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'gateway': gateway,
        'order_id': orderId,
        'amount': amount,
        'fare': fare,
        'currency': currency,
        'key': key,
        'seat_number': seatNumber,
        if (message.isNotEmpty) 'message': message,
      };

  /// Formatted amount in Rupees
  double get amountInRupees => amount > 0 ? (amount / 100.0) : fare;
}
