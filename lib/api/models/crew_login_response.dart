/// Root API Response for Crew Login (/crew/login)
class CrewLoginResponse {
  final bool success;
  final String message;
  final CrewData? data;
  final Map<String, dynamic>? errors;

  CrewLoginResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewLoginResponse.fromJson(Map<String, dynamic> json) {
    return CrewLoginResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewData.fromJson(json['data'] as Map<String, dynamic>)
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

  /// Extract primary error message from structured errors if available
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
    return message.isNotEmpty ? message : 'Authentication failed. Please try again.';
  }
}

/// Root API Response for Crew Profile (/crew/me)
class CrewProfileResponse {
  final bool success;
  final String message;
  final CrewProfile? data;
  final Map<String, dynamic>? errors;

  CrewProfileResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory CrewProfileResponse.fromJson(Map<String, dynamic> json) {
    return CrewProfileResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success'] == 1 || json['success'] == 'true'),
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? CrewProfile.fromJson(json['data'] as Map<String, dynamic>)
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
    return message.isNotEmpty ? message : 'Failed to retrieve profile.';
  }
}

/// Crew Authentication & Profile Data Container
class CrewData {
  final String token;
  final String tokenType;
  final String role; // 'driver' or 'conductor'
  final CrewProfile? profile;

  CrewData({
    required this.token,
    required this.tokenType,
    required this.role,
    this.profile,
  });

  factory CrewData.fromJson(Map<String, dynamic> json) {
    return CrewData(
      token: json['token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      role: json['role']?.toString() ?? 'driver',
      profile: json['profile'] != null && json['profile'] is Map<String, dynamic>
          ? CrewProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'token_type': tokenType,
        'role': role,
        'profile': profile?.toJson(),
      };
}

/// Crew Profile Details
class CrewProfile {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'bus_driver', 'conductor'
  final String status;
  final String? profilePhoto;
  final CrewDetails? crewDetails;
  final CrewOperator? operator;
  final DutySummary? dutySummary;

  CrewProfile({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.profilePhoto,
    this.crewDetails,
    this.operator,
    this.dutySummary,
  });

  factory CrewProfile.fromJson(Map<String, dynamic> json) {
    return CrewProfile(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? 'Crew Member',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'bus_driver',
      status: json['status']?.toString() ?? 'active',
      profilePhoto: json['profile_photo']?.toString(),
      crewDetails: json['crew_details'] is Map<String, dynamic>
          ? CrewDetails.fromJson(json['crew_details'] as Map<String, dynamic>)
          : null,
      operator: json['operator'] is Map<String, dynamic>
          ? CrewOperator.fromJson(json['operator'] as Map<String, dynamic>)
          : null,
      dutySummary: json['duty_summary'] is Map<String, dynamic>
          ? DutySummary.fromJson(json['duty_summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'profile_photo': profilePhoto,
        'crew_details': crewDetails?.toJson(),
        'operator': operator?.toJson(),
        'duty_summary': dutySummary?.toJson(),
      };
}

/// Official Crew Member Particulars
class CrewDetails {
  final int? id;
  final String crewId; // e.g. "DRV00001", "CND00001"
  final String role; // 'driver', 'conductor'
  final String roleLabel; // 'Bus Driver', 'Conductor'
  final String name;
  final String email;
  final String phone;
  final String? alternatePhone;
  final String gender;
  final String bloodGroup;
  final String? dob;
  final String licenseNumber;
  final String? licenseExpiry;
  final int experienceYears;
  final String address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String status;

  CrewDetails({
    this.id,
    required this.crewId,
    required this.role,
    required this.roleLabel,
    required this.name,
    required this.email,
    required this.phone,
    this.alternatePhone,
    required this.gender,
    required this.bloodGroup,
    this.dob,
    required this.licenseNumber,
    this.licenseExpiry,
    required this.experienceYears,
    required this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    required this.status,
  });

  factory CrewDetails.fromJson(Map<String, dynamic> json) {
    return CrewDetails(
      id: _parseInt(json['id']),
      crewId: json['crew_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'driver',
      roleLabel: json['role_label']?.toString() ?? 'Bus Driver',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      alternatePhone: json['alternate_phone']?.toString(),
      gender: json['gender']?.toString() ?? 'unspecified',
      bloodGroup: json['blood_group']?.toString() ?? 'N/A',
      dob: json['dob']?.toString(),
      licenseNumber: json['license_number']?.toString() ?? 'N/A',
      licenseExpiry: json['license_expiry']?.toString(),
      experienceYears: _parseInt(json['experience_years']) ?? 0,
      address: json['address']?.toString() ?? '',
      emergencyContactName: json['emergency_contact_name']?.toString(),
      emergencyContactPhone: json['emergency_contact_phone']?.toString(),
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crew_id': crewId,
        'role': role,
        'role_label': roleLabel,
        'name': name,
        'email': email,
        'phone': phone,
        'alternate_phone': alternatePhone,
        'gender': gender,
        'blood_group': bloodGroup,
        'dob': dob,
        'license_number': licenseNumber,
        'license_expiry': licenseExpiry,
        'experience_years': experienceYears,
        'address': address,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'status': status,
      };
}

/// Bus Depot / Branch Operator Information
class CrewOperator {
  final int? id;
  final String operatorName;
  final String? contactNumber;
  final String? email;
  final String? address;

  CrewOperator({
    this.id,
    required this.operatorName,
    this.contactNumber,
    this.email,
    this.address,
  });

  factory CrewOperator.fromJson(Map<String, dynamic> json) {
    return CrewOperator(
      id: _parseInt(json['id']),
      operatorName: json['operator_name']?.toString() ?? 'Central Depot',
      contactNumber: json['contact_number']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'operator_name': operatorName,
        'contact_number': contactNumber,
        'email': email,
        'address': address,
      };
}

/// Duty and Rostered Shift Summary
class DutySummary {
  final String todayDate;
  final int totalTripsToday;
  final ActiveTrip? activeTrip;

  DutySummary({
    required this.todayDate,
    required this.totalTripsToday,
    this.activeTrip,
  });

  factory DutySummary.fromJson(Map<String, dynamic> json) {
    return DutySummary(
      todayDate: json['today_date']?.toString() ?? '',
      totalTripsToday: _parseInt(json['total_trips_today']) ?? 0,
      activeTrip: json['active_trip'] is Map<String, dynamic>
          ? ActiveTrip.fromJson(json['active_trip'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'today_date': todayDate,
        'total_trips_today': totalTripsToday,
        'active_trip': activeTrip?.toJson(),
      };
}

/// Active Bus Trip Scheduled for the Crew
class ActiveTrip {
  final int? scheduleId;
  final String status;
  final int delayMinutes;
  final String departureDate;
  final String departureTime;
  final String arrivalTime;
  final ActiveBus? bus;
  final ActiveRoute? route;

  ActiveTrip({
    this.scheduleId,
    required this.status,
    required this.delayMinutes,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalTime,
    this.bus,
    this.route,
  });

  factory ActiveTrip.fromJson(Map<String, dynamic> json) {
    return ActiveTrip(
      scheduleId: _parseInt(json['schedule_id']),
      status: json['status']?.toString() ?? 'scheduled',
      delayMinutes: _parseInt(json['delay_minutes']) ?? 0,
      departureDate: json['departure_date']?.toString() ?? '',
      departureTime: json['departure_time']?.toString() ?? '',
      arrivalTime: json['arrival_time']?.toString() ?? '',
      bus: json['bus'] is Map<String, dynamic>
          ? ActiveBus.fromJson(json['bus'] as Map<String, dynamic>)
          : null,
      route: json['route'] is Map<String, dynamic>
          ? ActiveRoute.fromJson(json['route'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'schedule_id': scheduleId,
        'status': status,
        'delay_minutes': delayMinutes,
        'departure_date': departureDate,
        'departure_time': departureTime,
        'arrival_time': arrivalTime,
        'bus': bus?.toJson(),
        'route': route?.toJson(),
      };
}

/// Active Assigned Bus Vehicle
class ActiveBus {
  final int? id;
  final String? busName;
  final String registrationNumber;
  final String busType;
  final int totalSeats;

  ActiveBus({
    this.id,
    this.busName,
    required this.registrationNumber,
    required this.busType,
    required this.totalSeats,
  });

  factory ActiveBus.fromJson(Map<String, dynamic> json) {
    return ActiveBus(
      id: _parseInt(json['id']),
      busName: json['bus_name']?.toString(),
      registrationNumber: json['registration_number']?.toString() ?? 'UP-32-BT-9999',
      busType: json['bus_type']?.toString() ?? 'AC Sleeper (2+1)',
      totalSeats: _parseInt(json['total_seats']) ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bus_name': busName,
        'registration_number': registrationNumber,
        'bus_type': busType,
        'total_seats': totalSeats,
      };
}

/// Active Bus Route Details
class ActiveRoute {
  final int? id;
  final String sourceCity;
  final String destinationCity;
  final num? distanceKm;
  final num? durationHours;

  ActiveRoute({
    this.id,
    required this.sourceCity,
    required this.destinationCity,
    this.distanceKm,
    this.durationHours,
  });

  factory ActiveRoute.fromJson(Map<String, dynamic> json) {
    return ActiveRoute(
      id: _parseInt(json['id']),
      sourceCity: json['source_city']?.toString() ?? 'Lucknow',
      destinationCity: json['destination_city']?.toString() ?? 'Delhi',
      distanceKm: json['distance_km'] is num ? json['distance_km'] as num : num.tryParse(json['distance_km']?.toString() ?? ''),
      durationHours: json['duration_hours'] is num ? json['duration_hours'] as num : num.tryParse(json['duration_hours']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_city': sourceCity,
        'destination_city': destinationCity,
        'distance_km': distanceKm,
        'duration_hours': durationHours,
      };
}

int? _parseInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}
