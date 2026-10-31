import 'package:bus_driver/api/models/crew_login_response.dart';

/// Root API Response for Crew Dashboard (/crew/dashboard)
class CrewDashboardResponse {
  final bool success;
  final String message;
  final CrewDashboardData? data;
  final Map<String, dynamic>? errors;

  CrewDashboardResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewDashboardResponse.fromJson(Map<String, dynamic> json) {
    return CrewDashboardResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewDashboardData.fromJson(json['data'] as Map<String, dynamic>)
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
    return message.isNotEmpty ? message : 'Failed to retrieve dashboard data.';
  }
}

/// Container for Dashboard metrics, active trip, and roster
class CrewDashboardData {
  final CrewBasicInfo? crew;
  final DashboardMetrics? metrics;
  final DashboardTripItem? activeTrip;
  final List<DashboardTripItem> todayTrips;
  final List<DashboardTripItem> upcomingTrips;

  CrewDashboardData({
    this.crew,
    this.metrics,
    this.activeTrip,
    this.todayTrips = const [],
    this.upcomingTrips = const [],
  });

  factory CrewDashboardData.fromJson(Map<String, dynamic> json) {
    final rawTodayTrips = json['today_trips'];
    final rawUpcomingTrips = json['upcoming_trips'];

    return CrewDashboardData(
      crew: json['crew'] is Map<String, dynamic>
          ? CrewBasicInfo.fromJson(json['crew'] as Map<String, dynamic>)
          : null,
      metrics: json['metrics'] is Map<String, dynamic>
          ? DashboardMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : null,
      activeTrip: json['active_trip'] is Map<String, dynamic>
          ? DashboardTripItem.fromJson(json['active_trip'] as Map<String, dynamic>)
          : null,
      todayTrips: (rawTodayTrips is List)
          ? rawTodayTrips
              .whereType<Map<String, dynamic>>()
              .map((e) => DashboardTripItem.fromJson(e))
              .toList()
          : const [],
      upcomingTrips: (rawUpcomingTrips is List)
          ? rawUpcomingTrips
              .whereType<Map<String, dynamic>>()
              .map((e) => DashboardTripItem.fromJson(e))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'crew': crew?.toJson(),
        'metrics': metrics?.toJson(),
        'active_trip': activeTrip?.toJson(),
        'today_trips': todayTrips.map((e) => e.toJson()).toList(),
        'upcoming_trips': upcomingTrips.map((e) => e.toJson()).toList(),
      };
}

/// Basic Crew identity snippet on dashboard
class CrewBasicInfo {
  final int? id;
  final String crewId;
  final String name;
  final String role;
  final String roleLabel;
  final String status;

  CrewBasicInfo({
    this.id,
    required this.crewId,
    required this.name,
    required this.role,
    required this.roleLabel,
    required this.status,
  });

  factory CrewBasicInfo.fromJson(Map<String, dynamic> json) {
    return CrewBasicInfo(
      id: _parseInt(json['id']),
      crewId: json['crew_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Crew Member',
      role: json['role']?.toString() ?? 'driver',
      roleLabel: json['role_label']?.toString() ?? 'Bus Driver',
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crew_id': crewId,
        'name': name,
        'role': role,
        'role_label': roleLabel,
        'status': status,
      };
}

/// Key daily shift metrics
class DashboardMetrics {
  final String todayDate;
  final int totalToday;
  final int inTransitToday;
  final int completedToday;
  final int scheduledToday;

  DashboardMetrics({
    required this.todayDate,
    required this.totalToday,
    required this.inTransitToday,
    required this.completedToday,
    required this.scheduledToday,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      todayDate: json['today_date']?.toString() ?? '',
      totalToday: _parseInt(json['total_today']) ?? 0,
      inTransitToday: _parseInt(json['in_transit_today']) ?? 0,
      completedToday: _parseInt(json['completed_today']) ?? 0,
      scheduledToday: _parseInt(json['scheduled_today']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'today_date': todayDate,
        'total_today': totalToday,
        'in_transit_today': inTransitToday,
        'completed_today': completedToday,
        'scheduled_today': scheduledToday,
      };
}

/// Dashboard trip details (for active_trip, today_trips, upcoming_trips)
class DashboardTripItem {
  final int? id;
  int? get scheduleId => id;
  final String status; // 'in_transit', 'scheduled', 'completed'
  final int delayMinutes;
  final String? operationalNotes;
  final String departureDate;
  final String departureTime;
  final String? arrivalDate;
  final String arrivalTime;
  final ActiveRoute? route;
  final ActiveBus? bus;
  final CrewOperator? operator;
  final DashboardSeating? seating;
  final CrewPerson? driver;
  final CrewPerson? conductor;

  DashboardTripItem({
    this.id,
    required this.status,
    required this.delayMinutes,
    this.operationalNotes,
    required this.departureDate,
    required this.departureTime,
    this.arrivalDate,
    required this.arrivalTime,
    this.route,
    this.bus,
    this.operator,
    this.seating,
    this.driver,
    this.conductor,
  });

  factory DashboardTripItem.fromJson(Map<String, dynamic> json) {
    return DashboardTripItem(
      id: _parseInt(json['id']),
      status: json['status']?.toString() ?? 'scheduled',
      delayMinutes: _parseInt(json['delay_minutes']) ?? 0,
      operationalNotes: json['operational_notes']?.toString(),
      departureDate: json['departure_date']?.toString() ?? '',
      departureTime: json['departure_time']?.toString() ?? '',
      arrivalDate: json['arrival_date']?.toString(),
      arrivalTime: json['arrival_time']?.toString() ?? '',
      route: json['route'] is Map<String, dynamic>
          ? ActiveRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
      bus: json['bus'] is Map<String, dynamic>
          ? ActiveBus.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      operator: json['operator'] is Map<String, dynamic>
          ? CrewOperator.fromJson(json['operator'] as Map<String, dynamic>)
          : null,
      seating: json['seating'] is Map<String, dynamic>
          ? DashboardSeating.fromJson(json['seating'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] is Map<String, dynamic>
          ? CrewPerson.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      conductor: json['conductor'] is Map<String, dynamic>
          ? CrewPerson.fromJson(json['conductor'] as Map<String, dynamic>)
          : null,
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
        'route': route?.toJson(),
        'bus': bus?.toJson(),
        'operator': operator?.toJson(),
        'seating': seating?.toJson(),
        'driver': driver?.toJson(),
        'conductor': conductor?.toJson(),
      };
}

/// Live Seat Inventory on bus trip
class DashboardSeating {
  final int totalSeats;
  final int bookedSeats;
  final int availableSeats;

  DashboardSeating({
    required this.totalSeats,
    required this.bookedSeats,
    required this.availableSeats,
  });

  factory DashboardSeating.fromJson(Map<String, dynamic> json) {
    final total = _parseInt(json['total_seats']) ?? 30;
    final booked = _parseInt(json['booked_seats']) ?? 0;
    final avail = _parseInt(json['available_seats']) ?? (total - booked);
    return DashboardSeating(
      totalSeats: total,
      bookedSeats: booked,
      availableSeats: avail,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_seats': totalSeats,
        'booked_seats': bookedSeats,
        'available_seats': availableSeats,
      };
}

/// Assigned Driver or Conductor person
class CrewPerson {
  final int? id;
  final String name;
  final String phone;

  CrewPerson({
    this.id,
    required this.name,
    required this.phone,
  });

  factory CrewPerson.fromJson(Map<String, dynamic> json) {
    return CrewPerson(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? 'Crew Member',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
