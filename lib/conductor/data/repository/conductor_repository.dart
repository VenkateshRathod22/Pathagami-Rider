import 'package:flutter/foundation.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// Conductor Repository Service
///
/// Wraps the shared SPINGO Crew repository to provide conductor-specific functionality,
/// role checks, spot ticketing, and passenger manifest management.
class ConductorRepository extends ChangeNotifier {
  static final ConductorRepository _instance = ConductorRepository._internal();
  factory ConductorRepository() => _instance;

  final DriverRepository _baseRepo = DriverRepository();

  ConductorRepository._internal() {
    _baseRepo.addListener(notifyListeners);
  }

  /// Access underlying DriverRepository instance
  DriverRepository get baseRepo => _baseRepo;

  // Delegate getters to base repository with Conductor awareness
  DriverProfile get profile => _baseRepo.profile;
  DriverTrip get activeTrip => _baseRepo.activeTrip;
  List<DriverTrip> get upcomingTrips => _baseRepo.upcomingTrips;
  List<DriverTrip> get completedTrips => _baseRepo.completedTrips;
  List<DriverTrip> get todayTrips => _baseRepo.todayTrips;
  List<FleetBus> get fleetBuses => _baseRepo.fleetBuses;

  CrewProfile? get crewProfile => _baseRepo.crewProfile;
  CrewDashboardData? get dashboardData => _baseRepo.dashboardData;
  CrewTripDetailsData? get selectedTripDetails => _baseRepo.selectedTripDetails;

  int get totalBookings => _baseRepo.totalBookings;
  int get totalSeats => _baseRepo.totalSeats;
  int get bookedSeats => _baseRepo.bookedSeats;
  int get availableSeats => _baseRepo.availableSeats;

  String get conductorName => _baseRepo.conductorName;
  String get conductorPhone => _baseRepo.conductorPhone;
  String get conductorCrewId => _baseRepo.conductorCrewId;

  String get driverName => _baseRepo.driverName;
  String get driverPhone => _baseRepo.driverPhone;
  String get driverCrewId => _baseRepo.driverCrewId;

  bool get isConductor => _baseRepo.isConductor;

  // Delegate API refresh functions
  Future<bool> refreshDashboard() => _baseRepo.refreshDashboardFromApi();
  Future<List<DriverTrip>> fetchTodayTrips() => _baseRepo.fetchAssignedTrips(filter: 'today');
  Future<bool> refreshProfile() => _baseRepo.refreshProfileFromApi();
  void toggleDutyStatus(bool value) => _baseRepo.toggleOnlineStatus(value);

  /// Mark passenger boarding status as conductor
  Future<ApiResponse<CrewPassengerBoardingResponse>> markBoarding({
    required int passengerId,
    required bool isBoarded,
    String? boardedAtStop,
  }) {
    return _baseRepo.updatePassengerBoardingOnServer(
      passengerId: passengerId,
      isBoarded: isBoarded,
      boardedAtStop: boardedAtStop,
    );
  }

  /// Issue on-spot ticket as conductor
  Future<ApiResponse<CrewSpotBookingResponse>> issueSpotTicket({
    required dynamic scheduleId,
    required String passengerName,
    required String passengerPhone,
    required String seatNumber,
    required String boardingStop,
    required String destinationStop,
    required double fareAmount,
    String paymentMethod = 'cash',
  }) {
    return _baseRepo.createSpotBookingOnServer(
      scheduleId: scheduleId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      seatNumber: seatNumber,
      boardingStop: boardingStop,
      destinationStop: destinationStop,
      fareAmount: fareAmount,
      paymentMethod: paymentMethod,
    );
  }

  /// Initiate online spot payment as conductor
  Future<ApiResponse<CrewSpotPaymentInitiateResponse>> initiateSpotPayment({
    dynamic scheduleId,
    required dynamic scheduleSeatId,
    required String seatNumber,
    required String passengerName,
    required String passengerPhone,
    required String passengerGender,
    required int passengerAge,
    required String boardingLocation,
    required String droppingLocation,
    String gateway = 'razorpay',
    double? fare,
  }) {
    return _baseRepo.initiateSpotPaymentOnServer(
      scheduleId: scheduleId,
      scheduleSeatId: scheduleSeatId,
      seatNumber: seatNumber,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerGender: passengerGender,
      passengerAge: passengerAge,
      boardingLocation: boardingLocation,
      droppingLocation: droppingLocation,
      gateway: gateway,
      fare: fare,
    );
  }

  /// Verify online spot payment for onboarding passenger
  Future<ApiResponse<CrewSpotPaymentVerifyResponse>> verifySpotPayment({
    dynamic scheduleId,
    required dynamic scheduleSeatId,
    required String seatNumber,
    required String passengerName,
    required String passengerPhone,
    required String passengerGender,
    required int passengerAge,
    required String boardingLocation,
    required String droppingLocation,
    String gateway = 'razorpay',
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    double? fare,
  }) {
    return _baseRepo.verifySpotPaymentOnServer(
      scheduleId: scheduleId,
      scheduleSeatId: scheduleSeatId,
      seatNumber: seatNumber,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerGender: passengerGender,
      passengerAge: passengerAge,
      boardingLocation: boardingLocation,
      droppingLocation: droppingLocation,
      gateway: gateway,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      fare: fare,
    );
  }
}

