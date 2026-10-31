import 'package:bus_driver/api/models/crew_dashboard_response.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Root API Response for Assigned Trips (/crew/trips?filter=...)
class CrewAssignedTripsResponse {
  final bool success;
  final String message;
  final CrewAssignedTripsData? data;
  final Map<String, dynamic>? errors;

  CrewAssignedTripsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewAssignedTripsResponse.fromJson(Map<String, dynamic> json) {
    return CrewAssignedTripsResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewAssignedTripsData.fromJson(json['data'] as Map<String, dynamic>)
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
    return message.isNotEmpty ? message : 'Failed to retrieve assigned trips.';
  }
}

/// Container for trips list and pagination
class CrewAssignedTripsData {
  final List<DashboardTripItem> trips;
  final CrewPaginationInfo? pagination;

  CrewAssignedTripsData({
    this.trips = const [],
    this.pagination,
  });

  factory CrewAssignedTripsData.fromJson(Map<String, dynamic> json) {
    final rawTrips = json['trips'];
    return CrewAssignedTripsData(
      trips: (rawTrips is List)
          ? rawTrips
              .whereType<Map<String, dynamic>>()
              .map((e) => DashboardTripItem.fromJson(e))
              .toList()
          : const [],
      pagination: json['pagination'] is Map<String, dynamic>
          ? CrewPaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'trips': trips.map((e) => e.toJson()).toList(),
        'pagination': pagination?.toJson(),
      };
}

/// Pagination information for /crew/trips
class CrewPaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  CrewPaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory CrewPaginationInfo.fromJson(Map<String, dynamic> json) {
    return CrewPaginationInfo(
      currentPage: _parseInt(json['current_page']) ?? 1,
      lastPage: _parseInt(json['last_page']) ?? 1,
      perPage: _parseInt(json['per_page']) ?? 15,
      total: _parseInt(json['total']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
      };

  bool get hasMore => currentPage < lastPage;
}

/// Extension mapping DashboardTripItem to full DriverTrip model
extension DashboardTripItemConverter on DashboardTripItem {
  DriverTrip toDriverTrip() {
    TripStatus tripStatus = TripStatus.scheduled;
    if (status == 'in_transit') {
      tripStatus = TripStatus.inProgress;
    } else if (status == 'completed') {
      tripStatus = TripStatus.completed;
    } else if (status == 'scheduled') {
      tripStatus = TripStatus.scheduled;
    }

    final from = route?.sourceCity ?? 'Lucknow';
    final to = route?.destinationCity ?? 'Delhi';
    final dur = route?.durationHours != null ? '${route!.durationHours}h' : '7h 30m';
    final dist = route?.distanceKm != null ? '${route!.distanceKm} km' : '520 km';

    return DriverTrip(
      id: id != null ? 'TR-$id' : 'TR-19',
      tripNumber: 'SP-${id ?? "19"}',
      busNumber: bus?.registrationNumber ?? 'UP-32-BT-9999',
      busType: bus?.busType ?? 'AC Sleeper (2+1)',
      fromCity: from,
      toCity: to,
      fromTerminal: '$from Terminal',
      toTerminal: '$to ISBT',
      journeyDate: departureDate.isNotEmpty ? departureDate : '2026-10-26',
      departureTime: departureTime.isNotEmpty ? departureTime : '22:00:00',
      arrivalTime: arrivalTime.isNotEmpty ? arrivalTime : '05:30:00',
      duration: dur,
      distance: dist,
      totalSeats: seating?.totalSeats ?? bus?.totalSeats ?? 30,
      bookedSeats: seating?.bookedSeats ?? 0,
      status: tripStatus,
      delayMinutes: delayMinutes,
      operationalNotes: operationalNotes,
      driverName: driver?.name,
      driverPhone: driver?.phone,
      conductorName: conductor?.name,
      conductorPhone: conductor?.phone,
      operatorName: operator?.operatorName,
      stops: const [],
      passengers: const [],
    );
  }
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
