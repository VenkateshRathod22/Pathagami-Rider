import 'package:flutter/material.dart';

/// Represents the current lifecycle status of a bus trip
enum TripStatus {
  scheduled,
  boarding,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TripStatus.scheduled:
        return 'Scheduled';
      case TripStatus.boarding:
        return 'Boarding Active';
      case TripStatus.inProgress:
        return 'En Route';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TripStatus.scheduled:
        return const Color(0xFF3B82F6); // Blue
      case TripStatus.boarding:
        return const Color(0xFFF59E0B); // Amber
      case TripStatus.inProgress:
        return const Color(0xFF10B981); // Emerald
      case TripStatus.completed:
        return const Color(0xFF64748B); // Slate
      case TripStatus.cancelled:
        return const Color(0xFFEF4444); // Red
    }
  }
}

/// Ride Lifecycle Status for individual passenger bookings as per business requirements:
/// Requested → Accepted → Confirmed → Driver Arriving → Driver Arrived → Ride Started → Ride Completed
enum RideLifecycleStatus {
  requested,
  accepted,
  confirmed,
  driverArriving,
  driverArrived,
  rideStarted,
  rideCompleted,
  cancelled;

  String get displayName {
    switch (this) {
      case RideLifecycleStatus.requested:
        return 'Requested';
      case RideLifecycleStatus.accepted:
        return 'Accepted';
      case RideLifecycleStatus.confirmed:
        return 'Confirmed';
      case RideLifecycleStatus.driverArriving:
        return 'Driver Arriving';
      case RideLifecycleStatus.driverArrived:
        return 'Driver Arrived';
      case RideLifecycleStatus.rideStarted:
        return 'Ride Started';
      case RideLifecycleStatus.rideCompleted:
        return 'Ride Completed';
      case RideLifecycleStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case RideLifecycleStatus.requested:
        return const Color(0xFFF59E0B);
      case RideLifecycleStatus.accepted:
      case RideLifecycleStatus.confirmed:
        return const Color(0xFF3B82F6);
      case RideLifecycleStatus.driverArriving:
      case RideLifecycleStatus.driverArrived:
        return const Color(0xFF0284C7);
      case RideLifecycleStatus.rideStarted:
        return const Color(0xFF10B981);
      case RideLifecycleStatus.rideCompleted:
        return const Color(0xFF64748B);
      case RideLifecycleStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  /// Validates whether moving to [next] is a permitted transition
  bool canTransitionTo(RideLifecycleStatus next) {
    if (this == RideLifecycleStatus.cancelled || this == RideLifecycleStatus.rideCompleted) {
      return false;
    }
    if (next == RideLifecycleStatus.cancelled) {
      // Allowed before ride starts
      return this != RideLifecycleStatus.rideStarted && this != RideLifecycleStatus.rideCompleted;
    }
    switch (this) {
      case RideLifecycleStatus.requested:
        return next == RideLifecycleStatus.accepted;
      case RideLifecycleStatus.accepted:
        return next == RideLifecycleStatus.confirmed;
      case RideLifecycleStatus.confirmed:
        return next == RideLifecycleStatus.driverArriving;
      case RideLifecycleStatus.driverArriving:
        return next == RideLifecycleStatus.driverArrived;
      case RideLifecycleStatus.driverArrived:
        return next == RideLifecycleStatus.rideStarted;
      case RideLifecycleStatus.rideStarted:
        return next == RideLifecycleStatus.rideCompleted;
      default:
        return false;
    }
  }

  /// Single next valid driver action title
  String? get nextActionTitle {
    switch (this) {
      case RideLifecycleStatus.requested:
        return 'Accept Booking';
      case RideLifecycleStatus.accepted:
        return 'Confirm Booking';
      case RideLifecycleStatus.confirmed:
        return 'Start Heading to Pickup';
      case RideLifecycleStatus.driverArriving:
        return 'Mark Arrived at Pickup';
      case RideLifecycleStatus.driverArrived:
        return 'Start Ride / Board';
      case RideLifecycleStatus.rideStarted:
        return 'Complete Ride / Drop';
      default:
        return null;
    }
  }

  RideLifecycleStatus? get nextStatus {
    switch (this) {
      case RideLifecycleStatus.requested:
        return RideLifecycleStatus.accepted;
      case RideLifecycleStatus.accepted:
        return RideLifecycleStatus.confirmed;
      case RideLifecycleStatus.confirmed:
        return RideLifecycleStatus.driverArriving;
      case RideLifecycleStatus.driverArriving:
        return RideLifecycleStatus.driverArrived;
      case RideLifecycleStatus.driverArrived:
        return RideLifecycleStatus.rideStarted;
      case RideLifecycleStatus.rideStarted:
        return RideLifecycleStatus.rideCompleted;
      default:
        return null;
    }
  }
}

/// Driver Profile Model
class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String licenseNumber;
  final String badgeType;
  final double rating;
  final int totalTrips;
  final double onTimePercentage;
  final String assignedBusNumber;
  final String assignedBusType;
  final String depotName;
  final bool isOnline;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.badgeType,
    required this.rating,
    required this.totalTrips,
    required this.onTimePercentage,
    required this.assignedBusNumber,
    required this.assignedBusType,
    required this.depotName,
    this.isOnline = true,
  });

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? licenseNumber,
    String? badgeType,
    double? rating,
    int? totalTrips,
    double? onTimePercentage,
    String? assignedBusNumber,
    String? assignedBusType,
    String? depotName,
    bool? isOnline,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      badgeType: badgeType ?? this.badgeType,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      onTimePercentage: onTimePercentage ?? this.onTimePercentage,
      assignedBusNumber: assignedBusNumber ?? this.assignedBusNumber,
      assignedBusType: assignedBusType ?? this.assignedBusType,
      depotName: depotName ?? this.depotName,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// A milestone stop on a bus trip route
class RouteStop {
  final String id;
  final String stopName;
  final String city;
  final String scheduledTime;
  final String? actualTime;
  final bool isPassed;
  final bool isNext;
  final int passengerBoardingCount;
  final int passengerDroppingCount;

  const RouteStop({
    required this.id,
    required this.stopName,
    required this.city,
    required this.scheduledTime,
    this.actualTime,
    this.isPassed = false,
    this.isNext = false,
    this.passengerBoardingCount = 0,
    this.passengerDroppingCount = 0,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id']?.toString() ?? '',
      stopName: json['stop_name']?.toString() ?? json['name']?.toString() ?? 'Station Stop',
      city: json['city']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? json['time']?.toString() ?? '',
      actualTime: json['actual_time']?.toString(),
      isPassed: json['is_passed'] == true,
      isNext: json['is_next'] == true,
      passengerBoardingCount: int.tryParse(json['passenger_boarding_count']?.toString() ?? '') ?? 0,
      passengerDroppingCount: int.tryParse(json['passenger_dropping_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stop_name': stopName,
        'city': city,
        'scheduled_time': scheduledTime,
        'actual_time': actualTime,
        'is_passed': isPassed,
        'is_next': isNext,
        'passenger_boarding_count': passengerBoardingCount,
        'passenger_dropping_count': passengerDroppingCount,
      };
}

/// Fleet Bus Model to display other buses active at the same time and route
class FleetBus {
  final String busNumber;
  final String busType;
  final String route;
  final String departureTime;
  final String status; // 'Boarding', 'En Route', 'On Standby'
  final int availableSeats;

  const FleetBus({
    required this.busNumber,
    required this.busType,
    required this.route,
    required this.departureTime,
    required this.status,
    required this.availableSeats,
  });
}

/// Passenger Booking Information
class PassengerBooking {
  final int? passengerId;
  final String pnr;
  final String? bookingId;
  final String passengerName;
  final String phone;
  final String? email;
  final int age;
  final String gender;
  final String seatNumber;
  final bool isUpperDeck;
  final String pickupLocation;
  final String dropLocation;
  final String pickupTime;
  final String dropTime;
  final String status; // 'Confirmed', 'Boarded', 'Pending', 'Cancelled', 'No-Show'
  final double fare;
  final bool isBoarded;
  final String boardingStatus; // 'boarded', 'no_show', 'pending'
  final String? boardedAt; // e.g. "10:15 PM"
  final String paymentStatus;
  final RideLifecycleStatus rideStatus;
  final int passengerCount;
  final String journeyDate;

  const PassengerBooking({
    this.passengerId,
    required this.pnr,
    this.bookingId,
    required this.passengerName,
    required this.phone,
    this.email,
    required this.age,
    required this.gender,
    required this.seatNumber,
    required this.isUpperDeck,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupTime,
    required this.dropTime,
    required this.status,
    required this.fare,
    this.isBoarded = false,
    this.boardingStatus = 'pending',
    this.boardedAt,
    this.paymentStatus = 'Paid (Online)',
    this.rideStatus = RideLifecycleStatus.confirmed,
    this.passengerCount = 1,
    this.journeyDate = '26 Oct 2026',
  });

  String get effectiveBookingId => bookingId ?? pnr;

  int get effectivePassengerId {
    if (passengerId != null && passengerId! > 0) return passengerId!;
    final match = RegExp(r'\d+').firstMatch(pnr);
    if (match != null) {
      final digits = match.group(0)!;
      return int.tryParse(digits.substring(0, digits.length.clamp(1, 4))) ?? 45;
    }
    return 45;
  }

  bool get isNoShow =>
      boardingStatus.toLowerCase() == 'no_show' ||
      status.toLowerCase() == 'no_show' ||
      status.toLowerCase() == 'no-show';

  bool get isPending => !isBoarded && !isNoShow;

  bool get isCancelled =>
      rideStatus == RideLifecycleStatus.cancelled ||
      status.toLowerCase() == 'cancelled';

  PassengerBooking copyWith({
    int? passengerId,
    String? pnr,
    String? bookingId,
    String? passengerName,
    String? phone,
    String? email,
    int? age,
    String? gender,
    String? seatNumber,
    bool? isUpperDeck,
    String? pickupLocation,
    String? dropLocation,
    String? pickupTime,
    String? dropTime,
    String? status,
    double? fare,
    bool? isBoarded,
    String? boardingStatus,
    String? boardedAt,
    String? paymentStatus,
    RideLifecycleStatus? rideStatus,
    int? passengerCount,
    String? journeyDate,
  }) {
    return PassengerBooking(
      passengerId: passengerId ?? this.passengerId,
      pnr: pnr ?? this.pnr,
      bookingId: bookingId ?? this.bookingId,
      passengerName: passengerName ?? this.passengerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      seatNumber: seatNumber ?? this.seatNumber,
      isUpperDeck: isUpperDeck ?? this.isUpperDeck,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      pickupTime: pickupTime ?? this.pickupTime,
      dropTime: dropTime ?? this.dropTime,
      status: status ?? this.status,
      fare: fare ?? this.fare,
      isBoarded: isBoarded ?? this.isBoarded,
      boardingStatus: boardingStatus ?? this.boardingStatus,
      boardedAt: boardedAt ?? this.boardedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rideStatus: rideStatus ?? this.rideStatus,
      passengerCount: passengerCount ?? this.passengerCount,
      journeyDate: journeyDate ?? this.journeyDate,
    );
  }
}

/// Individual Seat Model in the Bus Layout
class SeatModel {
  final String seatNumber; // e.g. 'L1A', 'L1B', 'U1A'
  final int row;
  final int column;
  final bool isUpperDeck;
  final bool isSleeper;
  final bool isBooked;
  final bool isUnavailable;
  final PassengerBooking? passenger;
  final int? seatId; // database ID from API (e.g. 451)
  final num? fare; // e.g. 1000, 950
  final String? seatType; // e.g. "sleeper"
  final String? deckName; // e.g. "lower", "upper"

  const SeatModel({
    required this.seatNumber,
    required this.row,
    required this.column,
    required this.isUpperDeck,
    required this.isSleeper,
    required this.isBooked,
    this.isUnavailable = false,
    this.passenger,
    this.seatId,
    this.fare,
    this.seatType,
    this.deckName,
  });
}

/// Driver Trip Model
class DriverTrip {
  final String id;
  final String tripNumber;
  final String busNumber;
  final String busType;
  final String fromCity;
  final String toCity;
  final String fromTerminal;
  final String toTerminal;
  final String journeyDate;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String distance;
  final int totalSeats;
  final int bookedSeats;
  final TripStatus status;
  final List<RouteStop> stops;
  final List<PassengerBooking> passengers;
  final int delayMinutes;
  final String? operationalNotes;
  final String? driverName;
  final String? driverPhone;
  final String? conductorName;
  final String? conductorPhone;
  final String? operatorName;

  const DriverTrip({
    required this.id,
    required this.tripNumber,
    required this.busNumber,
    required this.busType,
    required this.fromCity,
    required this.toCity,
    required this.fromTerminal,
    required this.toTerminal,
    required this.journeyDate,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.distance,
    required this.totalSeats,
    required this.bookedSeats,
    required this.status,
    required this.stops,
    required this.passengers,
    this.delayMinutes = 0,
    this.operationalNotes,
    this.driverName,
    this.driverPhone,
    this.conductorName,
    this.conductorPhone,
    this.operatorName,
  });

  /// Actual active booked seats count excluding cancelled bookings and preventing double counting
  int get activeBookedSeatsCount {
    final activeBookings = passengers.where((p) => !p.isCancelled);
    final bookedSeatsSet = activeBookings.map((p) => p.seatNumber).toSet();
    return bookedSeatsSet.length;
  }

  /// Available seats calculated strictly as: Total seats - Active booked seats
  int get availableSeats => (totalSeats - activeBookedSeatsCount).clamp(0, totalSeats);

  DriverTrip copyWith({
    String? id,
    String? tripNumber,
    String? busNumber,
    String? busType,
    String? fromCity,
    String? toCity,
    String? fromTerminal,
    String? toTerminal,
    String? journeyDate,
    String? departureTime,
    String? arrivalTime,
    String? duration,
    String? distance,
    int? totalSeats,
    int? bookedSeats,
    TripStatus? status,
    List<RouteStop>? stops,
    List<PassengerBooking>? passengers,
    int? delayMinutes,
    String? operationalNotes,
    String? driverName,
    String? driverPhone,
    String? conductorName,
    String? conductorPhone,
    String? operatorName,
  }) {
    return DriverTrip(
      id: id ?? this.id,
      tripNumber: tripNumber ?? this.tripNumber,
      busNumber: busNumber ?? this.busNumber,
      busType: busType ?? this.busType,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      fromTerminal: fromTerminal ?? this.fromTerminal,
      toTerminal: toTerminal ?? this.toTerminal,
      journeyDate: journeyDate ?? this.journeyDate,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      status: status ?? this.status,
      stops: stops ?? this.stops,
      passengers: passengers ?? this.passengers,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      operationalNotes: operationalNotes ?? this.operationalNotes,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      conductorName: conductorName ?? this.conductorName,
      conductorPhone: conductorPhone ?? this.conductorPhone,
      operatorName: operatorName ?? this.operatorName,
    );
  }
}
