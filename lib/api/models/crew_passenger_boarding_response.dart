/// Response model for /crew/passengers/{passengerId}/boarding API
class CrewPassengerBoardingResponse {
  final bool success;
  final String message;
  final CrewPassengerBoardingData? data;

  const CrewPassengerBoardingResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CrewPassengerBoardingResponse.fromJson(Map<String, dynamic> json) {
    return CrewPassengerBoardingResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? CrewPassengerBoardingData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class CrewPassengerBoardingData {
  final int passengerId;
  final String passengerName;
  final String seatNumber;
  final String boardingStatus; // 'boarded', 'no_show', 'pending'
  final String? boardedAt; // e.g. "10:15 PM"

  const CrewPassengerBoardingData({
    required this.passengerId,
    required this.passengerName,
    required this.seatNumber,
    required this.boardingStatus,
    this.boardedAt,
  });

  factory CrewPassengerBoardingData.fromJson(Map<String, dynamic> json) {
    return CrewPassengerBoardingData(
      passengerId: json['passenger_id'] is num
          ? (json['passenger_id'] as num).toInt()
          : int.tryParse(json['passenger_id']?.toString() ?? '') ?? 0,
      passengerName: json['passenger_name']?.toString() ?? '',
      seatNumber: json['seat_number']?.toString() ?? '',
      boardingStatus: json['boarding_status']?.toString() ?? 'pending',
      boardedAt: json['boarded_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'passenger_id': passengerId,
        'passenger_name': passengerName,
        'seat_number': seatNumber,
        'boarding_status': boardingStatus,
        'boarded_at': ?boardedAt,
      };

  bool get isBoarded => boardingStatus.toLowerCase() == 'boarded';
  bool get isNoShow => boardingStatus.toLowerCase() == 'no_show';
  bool get isPending => boardingStatus.toLowerCase() == 'pending';
}
