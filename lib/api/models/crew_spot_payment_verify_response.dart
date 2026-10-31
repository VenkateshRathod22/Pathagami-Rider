/// Response model for Onboarding Payment Verify API
/// POST /crew/trip/{schedule}/spot-payment/verify
class CrewSpotPaymentVerifyResponse {
  final bool success;
  final String message;
  final String? pnr;
  final String? seatNumber;
  final int? bookingId;
  final int? passengerId;
  final Map<String, dynamic>? errors;

  CrewSpotPaymentVerifyResponse({
    required this.success,
    required this.message,
    this.pnr,
    this.seatNumber,
    this.bookingId,
    this.passengerId,
    this.errors,
  });

  factory CrewSpotPaymentVerifyResponse.fromJson(Map<String, dynamic> json) {
    return CrewSpotPaymentVerifyResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      pnr: json['pnr']?.toString(),
      seatNumber: json['seat_number']?.toString(),
      bookingId: _parseInt(json['booking_id']),
      passengerId: _parseInt(json['passenger_id']),
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (pnr != null) 'pnr': pnr,
        if (seatNumber != null) 'seat_number': seatNumber,
        if (bookingId != null) 'booking_id': bookingId,
        if (passengerId != null) 'passenger_id': passengerId,
        if (errors != null) 'errors': errors,
      };

  String get firstErrorMessage {
    if (errors != null && errors!.isNotEmpty) {
      for (final key in errors!.keys) {
        final val = errors![key];
        if (val is List && val.isNotEmpty) {
          return val.first.toString();
        } else if (val is String && val.isNotEmpty) {
          return val;
        }
      }
    }
    return message.isNotEmpty ? message : 'Payment verification failed.';
  }
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
