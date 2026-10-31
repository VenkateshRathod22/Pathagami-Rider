/// Model for /crew/trips/{tripId}/vacant-seats response
class CrewVacantSeatsResponse {
  final bool success;
  final String message;
  final CrewVacantSeatsData? data;

  const CrewVacantSeatsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory CrewVacantSeatsResponse.fromJson(Map<String, dynamic> json) {
    return CrewVacantSeatsResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null ? CrewVacantSeatsData.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    if (data != null) 'data': data!.toJson(),
  };
}

class CrewVacantSeatsData {
  final int scheduleId;
  final int totalVacantSeats;
  final List<VacantSeatItem> vacantSeats;

  const CrewVacantSeatsData({
    required this.scheduleId,
    required this.totalVacantSeats,
    required this.vacantSeats,
  });

  factory CrewVacantSeatsData.fromJson(Map<String, dynamic> json) {
    return CrewVacantSeatsData(
      scheduleId: json['schedule_id'] is num
          ? (json['schedule_id'] as num).toInt()
          : int.tryParse(json['schedule_id']?.toString() ?? '') ?? 0,
      totalVacantSeats: json['total_vacant_seats'] is num
          ? (json['total_vacant_seats'] as num).toInt()
          : int.tryParse(json['total_vacant_seats']?.toString() ?? '') ?? 0,
      vacantSeats: (json['vacant_seats'] as List<dynamic>?)
              ?.map((item) => VacantSeatItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'schedule_id': scheduleId,
    'total_vacant_seats': totalVacantSeats,
    'vacant_seats': vacantSeats.map((v) => v.toJson()).toList(),
  };

  /// Find vacant seat by berth code (e.g. 'L1A', 'U2C')
  VacantSeatItem? findBySeatNumber(String seatNum) {
    final clean = seatNum.trim().toUpperCase();
    for (final v in vacantSeats) {
      if (v.seatNumber.trim().toUpperCase() == clean) {
        return v;
      }
    }
    return null;
  }
}

class VacantSeatItem {
  final int id;
  final String seatNumber;
  final String deck;
  final String seatType;
  final num fare;

  const VacantSeatItem({
    required this.id,
    required this.seatNumber,
    required this.deck,
    required this.seatType,
    required this.fare,
  });

  factory VacantSeatItem.fromJson(Map<String, dynamic> json) {
    return VacantSeatItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      seatNumber: json['seat_number']?.toString() ?? '',
      deck: json['deck']?.toString() ?? 'lower',
      seatType: json['seat_type']?.toString() ?? 'sleeper',
      fare: json['fare'] is num ? (json['fare'] as num) : num.tryParse(json['fare']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seat_number': seatNumber,
    'deck': deck,
    'seat_type': seatType,
    'fare': fare,
  };

  bool get isUpperDeck => deck.toLowerCase().contains('upper');
}
