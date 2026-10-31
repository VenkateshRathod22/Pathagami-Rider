/// Response model for /crew/trips/{schedule_id}/spot-booking API
class CrewSpotBookingResponse {
  final bool success;
  final String message;
  final CrewSpotBookingData? data;

  const CrewSpotBookingResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CrewSpotBookingResponse.fromJson(Map<String, dynamic> json) {
    return CrewSpotBookingResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? CrewSpotBookingData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class CrewSpotBookingData {
  final int bookingId;
  final String pnr;
  final String seatNumber;
  final String passengerName;
  final double fare;
  final String paymentMethod;
  final String paymentStatus;
  final String boardingStatus;

  const CrewSpotBookingData({
    required this.bookingId,
    required this.pnr,
    required this.seatNumber,
    required this.passengerName,
    required this.fare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.boardingStatus,
  });

  factory CrewSpotBookingData.fromJson(Map<String, dynamic> json) {
    return CrewSpotBookingData(
      bookingId: json['booking_id'] is num
          ? (json['booking_id'] as num).toInt()
          : int.tryParse(json['booking_id']?.toString() ?? '') ?? 0,
      pnr: json['pnr']?.toString() ?? '',
      seatNumber: json['seat_number']?.toString() ?? '',
      passengerName: json['passenger_name']?.toString() ?? '',
      fare: json['fare'] is num
          ? (json['fare'] as num).toDouble()
          : double.tryParse(json['fare']?.toString() ?? '') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'paid',
      boardingStatus: json['boarding_status']?.toString() ?? 'boarded',
    );
  }

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'pnr': pnr,
        'seat_number': seatNumber,
        'passenger_name': passengerName,
        'fare': fare,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'boarding_status': boardingStatus,
      };

  bool get isBoarded => boardingStatus.toLowerCase() == 'boarded';
  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
}
