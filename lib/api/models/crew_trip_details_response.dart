import 'package:bus_driver/api/models/crew_login_response.dart';

/// Root API Response for Crew Trip Details (/crew/trips/{id})
class CrewTripDetailsResponse {
  final bool success;
  final String message;
  final CrewTripDetailsData? data;
  final Map<String, dynamic>? errors;

  CrewTripDetailsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewTripDetailsResponse.fromJson(Map<String, dynamic> json) {
    return CrewTripDetailsResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewTripDetailsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data?.toJson(),
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
    return message.isNotEmpty ? message : 'Failed to retrieve trip details.';
  }
}

/// Detailed Trip Data container
class CrewTripDetailsData {
  final TripSchedule? schedule;
  final ActiveBus? bus;
  final ActiveRoute? route;
  final CrewOperator? operator;
  final TripCrewMember? driver;
  final TripCrewMember? conductor;
  final TripSeatingSummary? seatingSummary;
  final dynamic manifest;

  CrewTripDetailsData({
    this.schedule,
    this.bus,
    this.route,
    this.operator,
    this.driver,
    this.conductor,
    this.seatingSummary,
    this.manifest,
  });

  factory CrewTripDetailsData.fromJson(Map<String, dynamic> json) {
    return CrewTripDetailsData(
      schedule: json['schedule'] is Map<String, dynamic>
          ? TripSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : null,
      bus: json['bus'] is Map<String, dynamic>
          ? ActiveBus.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      route: json['route'] is Map<String, dynamic>
          ? ActiveRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      operator: json['operator'] is Map<String, dynamic>
          ? CrewOperator.fromJson(json['operator'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? TripCrewMember.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      conductor: json['conductor'] is Map<String, dynamic>
          ? TripCrewMember.fromJson(json['conductor'] as Map<String, dynamic>)
          : null,
      seatingSummary: json['seating_summary'] is Map<String, dynamic>
          ? TripSeatingSummary.fromJson(json['seating_summary'] as Map<String, dynamic>)
          : null,
      manifest: json['manifest'],
    );
  }

  Map<String, dynamic> toJson() => {
        'schedule': schedule?.toJson(),
        'bus': bus?.toJson(),
        'route': route?.toJson(),
        'operator': operator?.toJson(),
        'driver': driver?.toJson(),
        'conductor': conductor?.toJson(),
        'seating_summary': seatingSummary?.toJson(),
        'manifest': manifest,
      };
}

/// Trip Schedule Particulars
class TripSchedule {
  final int? id;
  final String status;
  final int delayMinutes;
  final String? operationalNotes;
  final String departureDate;
  final String departureTime;
  final String? arrivalDate;
  final String arrivalTime;
  final num? baseFare;

  TripSchedule({
    this.id,
    required this.status,
    required this.delayMinutes,
    this.operationalNotes,
    required this.departureDate,
    required this.departureTime,
    this.arrivalDate,
    required this.arrivalTime,
    this.baseFare,
  });

  factory TripSchedule.fromJson(Map<String, dynamic> json) {
    return TripSchedule(
      id: _parseInt(json['id']),
      status: json['status']?.toString() ?? 'scheduled',
      delayMinutes: _parseInt(json['delay_minutes']) ?? 0,
      operationalNotes: json['operational_notes']?.toString(),
      departureDate: json['departure_date']?.toString() ?? '',
      departureTime: json['departure_time']?.toString() ?? '',
      arrivalDate: json['arrival_date']?.toString(),
      arrivalTime: json['arrival_time']?.toString() ?? '',
      baseFare: json['base_fare'] is num
          ? json['base_fare'] as num
          : num.tryParse(json['base_fare']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'delay_minutes': delayMinutes,
        'operational_notes': operationalNotes,
        'departure_date': departureDate,
        'departure_time': departureTime,
        'arrival_date': arrivalDate,
        'arrival_time': arrivalTime,
        'base_fare': baseFare,
      };
}

/// Assigned Driver or Conductor with Crew ID Badge
class TripCrewMember {
  final int? id;
  final String crewId;
  final String name;
  final String phone;

  TripCrewMember({
    this.id,
    required this.crewId,
    required this.name,
    required this.phone,
  });

  factory TripCrewMember.fromJson(Map<String, dynamic> json) {
    return TripCrewMember(
      id: _parseInt(json['id']),
      crewId: json['crew_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Crew Member',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crew_id': crewId,
        'name': name,
        'phone': phone,
      };
}

/// Live Seating & Boarding Breakdown for Trip
class TripSeatingSummary {
  final int totalSeats;
  final int bookedSeatsCount;
  final int vacantSeatsCount;
  final int boardedCount;
  final int pendingBoardingCount;
  final int noShowCount;

  TripSeatingSummary({
    required this.totalSeats,
    required this.bookedSeatsCount,
    required this.vacantSeatsCount,
    required this.boardedCount,
    required this.pendingBoardingCount,
    required this.noShowCount,
  });

  factory TripSeatingSummary.fromJson(Map<String, dynamic> json) {
    final total = _parseInt(json['total_seats']) ?? 30;
    final booked = _parseInt(json['booked_seats_count']) ?? 0;
    final vacant = _parseInt(json['vacant_seats_count']) ?? (total - booked);
    final boarded = _parseInt(json['boarded_count']) ?? 0;
    final pending = _parseInt(json['pending_boarding_count']) ?? (booked - boarded).clamp(0, total);
    final noShow = _parseInt(json['no_show_count']) ?? 0;

    return TripSeatingSummary(
      totalSeats: total,
      bookedSeatsCount: booked,
      vacantSeatsCount: vacant,
      boardedCount: boarded,
      pendingBoardingCount: pending,
      noShowCount: noShow,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_seats': totalSeats,
        'booked_seats_count': bookedSeatsCount,
        'vacant_seats_count': vacantSeatsCount,
        'boarded_count': boardedCount,
        'pending_boarding_count': pendingBoardingCount,
        'no_show_count': noShowCount,
      };
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
