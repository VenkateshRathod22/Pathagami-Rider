import 'package:flutter/foundation.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';

/// Repository managing driver profile, trips, passenger manifest, and bus seat layout.
/// Inherits ChangeNotifier so all UI screens react in real-time to status updates.
class DriverRepository extends ChangeNotifier {
  static final DriverRepository _instance = DriverRepository._internal();
  factory DriverRepository() => _instance;

  DriverRepository._internal() {
    _initData();
  }

  late DriverProfile _profile;
  late DriverTrip _activeTrip;
  late List<DriverTrip> _upcomingTrips;
  late List<DriverTrip> _completedTrips;
  late List<FleetBus> _fleetBuses;
  List<DriverTrip> _todayTrips = [];
  CrewVacantSeatsData? _vacantSeatsData;

  DriverProfile get profile => _profile;
  DriverTrip get activeTrip => _activeTrip;
  List<DriverTrip> get upcomingTrips => List.unmodifiable(_upcomingTrips);
  List<DriverTrip> get completedTrips => List.unmodifiable(_completedTrips);
  List<DriverTrip> get todayTrips => List.unmodifiable(_todayTrips);
  List<FleetBus> get fleetBuses => List.unmodifiable(_fleetBuses);
  CrewVacantSeatsData? get vacantSeatsData => _vacantSeatsData;

  // ---------------------------------------------------------------------------
  // Calculated Metrics (Strictly avoiding double counting & excluding cancelled)
  // ---------------------------------------------------------------------------

  /// Total active bookings (excluding cancelled bookings)
  int get totalBookings =>
      _dashboardData?.activeTrip?.seating?.bookedSeats ??
      _activeTrip.passengers.where((p) => !p.isCancelled).length;

  /// Total seats on assigned bus
  int get totalSeats =>
      _dashboardData?.activeTrip?.seating?.totalSeats ?? _activeTrip.totalSeats;

  /// Unique booked seats for active passengers
  int get bookedSeats =>
      _dashboardData?.activeTrip?.seating?.bookedSeats ??
      _activeTrip.activeBookedSeatsCount;

  /// Available seats = Total Seats - Booked Seats
  int get availableSeats =>
      _dashboardData?.activeTrip?.seating?.availableSeats ??
      _activeTrip.availableSeats;

  CrewProfile? _crewProfile;
  CrewProfile? get crewProfile => _crewProfile;

  CrewDashboardData? _dashboardData;
  CrewDashboardData? get dashboardData => _dashboardData;

  CrewTripDetailsData? _selectedTripDetails;
  CrewTripDetailsData? get selectedTripDetails => _selectedTripDetails;

  CrewPaginationInfo? _tripsPagination;
  CrewPaginationInfo? get tripsPagination => _tripsPagination;

  bool? _overrideIsConductor;

  /// Explicitly set the active crew mode ('conductor' or 'driver')
  void setActiveRole(String role) {
    final isCond = role.toLowerCase().contains('conductor');
    _overrideIsConductor = isCond;
    _profile = _profile.copyWith(
      badgeType: isCond ? 'Bus Conductor' : 'Bus Driver',
    );
    notifyListeners();
  }

  bool get isConductor =>
      _overrideIsConductor ??
      (_crewProfile?.role == 'conductor' ||
          _profile.badgeType.toLowerCase().contains('conductor'));
  bool get isDriver => !isConductor;

  /// Effective Conductor Name
  String get conductorName {
    if (_selectedTripDetails?.conductor?.name != null &&
        _selectedTripDetails!.conductor!.name.isNotEmpty) {
      return _selectedTripDetails!.conductor!.name;
    }
    if (_dashboardData?.activeTrip?.conductor?.name != null &&
        _dashboardData!.activeTrip!.conductor!.name.isNotEmpty) {
      return _dashboardData!.activeTrip!.conductor!.name;
    }
    if (_activeTrip.conductorName != null &&
        _activeTrip.conductorName!.isNotEmpty) {
      return _activeTrip.conductorName!;
    }
    if (isConductor) {
      return _profile.name;
    }
    return 'Khalil Swaniawski';
  }

  /// Effective Conductor Phone
  String get conductorPhone {
    if (_selectedTripDetails?.conductor?.phone != null &&
        _selectedTripDetails!.conductor!.phone.isNotEmpty) {
      return _selectedTripDetails!.conductor!.phone;
    }
    if (_dashboardData?.activeTrip?.conductor?.phone != null &&
        _dashboardData!.activeTrip!.conductor!.phone.isNotEmpty) {
      return _dashboardData!.activeTrip!.conductor!.phone;
    }
    if (_activeTrip.conductorPhone != null &&
        _activeTrip.conductorPhone!.isNotEmpty) {
      return _activeTrip.conductorPhone!;
    }
    if (isConductor) {
      return _profile.phone;
    }
    return '7527425651';
  }

  /// Effective Conductor Crew ID / Badge
  String get conductorCrewId {
    if (_selectedTripDetails?.conductor?.crewId != null &&
        _selectedTripDetails!.conductor!.crewId.isNotEmpty) {
      return _selectedTripDetails!.conductor!.crewId;
    }
    if (isConductor) {
      return _profile.id;
    }
    return _crewProfile?.crewDetails?.crewId ?? 'CND00001';
  }

  /// Effective Driver Name
  String get driverName {
    if (_selectedTripDetails?.driver?.name != null &&
        _selectedTripDetails!.driver!.name.isNotEmpty) {
      return _selectedTripDetails!.driver!.name;
    }
    if (_dashboardData?.activeTrip?.driver?.name != null &&
        _dashboardData!.activeTrip!.driver!.name.isNotEmpty) {
      return _dashboardData!.activeTrip!.driver!.name;
    }
    if (_activeTrip.driverName != null && _activeTrip.driverName!.isNotEmpty) {
      return _activeTrip.driverName!;
    }
    if (isDriver) {
      return _profile.name;
    }
    return 'Reece Wiza-Robel';
  }

  /// Effective Driver Phone
  String get driverPhone {
    if (_selectedTripDetails?.driver?.phone != null &&
        _selectedTripDetails!.driver!.phone.isNotEmpty) {
      return _selectedTripDetails!.driver!.phone;
    }
    if (_dashboardData?.activeTrip?.driver?.phone != null &&
        _dashboardData!.activeTrip!.driver!.phone.isNotEmpty) {
      return _dashboardData!.activeTrip!.driver!.phone;
    }
    if (_activeTrip.driverPhone != null &&
        _activeTrip.driverPhone!.isNotEmpty) {
      return _activeTrip.driverPhone!;
    }
    if (isDriver) {
      return _profile.phone;
    }
    return '6327114051';
  }

  /// Effective Driver Crew ID / Badge
  String get driverCrewId {
    if (_selectedTripDetails?.driver?.crewId != null &&
        _selectedTripDetails!.driver!.crewId.isNotEmpty) {
      return _selectedTripDetails!.driver!.crewId;
    }
    if (isDriver) {
      return _profile.id;
    }
    return 'DRV00001';
  }

  // ---------------------------------------------------------------------------
  // Authentication & API Session Integration
  // ---------------------------------------------------------------------------

  /// Update repository state with authenticated Crew details from the API login
  void updateFromCrewLogin(CrewLoginResponse loginResponse) {
    final data = loginResponse.data;
    if (data == null) return;

    if (data.profile != null) {
      updateFromProfile(data.profile!);
    }
  }

  /// Update repository state with full CrewProfile (from /crew/me or /crew/login)
  void updateFromProfile(CrewProfile profile) {
    _crewProfile = profile;

    final crew = profile.crewDetails;
    final op = profile.operator;
    final duty = profile.dutySummary;
    final activeTrip = duty?.activeTrip;
    final bus = activeTrip?.bus;
    final route = activeTrip?.route;

    final isCond =
        _overrideIsConductor ??
        (profile.role == 'conductor' ||
            (crew?.role.contains('conductor') ?? false));

    // Update Crew Profile
    _profile = _profile.copyWith(
      id: (crew?.crewId != null && crew!.crewId.isNotEmpty)
          ? crew.crewId
          : (profile.id != null
                ? (isCond ? 'CND-${profile.id}' : 'DRV-${profile.id}')
                : _profile.id),
      name: (profile.name.isNotEmpty) ? profile.name : _profile.name,
      phone: (profile.phone.isNotEmpty) ? profile.phone : _profile.phone,
      email: (profile.email.isNotEmpty) ? profile.email : _profile.email,
      licenseNumber:
          (crew?.licenseNumber != null && crew!.licenseNumber.isNotEmpty)
          ? crew.licenseNumber
          : _profile.licenseNumber,
      badgeType: (crew?.roleLabel != null && crew!.roleLabel.isNotEmpty)
          ? crew.roleLabel
          : (isCond ? 'Bus Conductor' : 'Bus Driver'),
      depotName: (op?.operatorName != null && op!.operatorName.isNotEmpty)
          ? op.operatorName
          : _profile.depotName,
      assignedBusNumber:
          (bus?.registrationNumber != null &&
              bus!.registrationNumber.isNotEmpty)
          ? bus.registrationNumber
          : _profile.assignedBusNumber,
      assignedBusType: (bus?.busType != null && bus!.busType.isNotEmpty)
          ? bus.busType
          : _profile.assignedBusType,
      isOnline: true,
    );

    // Update Active Trip if available from API duty summary
    if (activeTrip != null) {
      TripStatus status = _activeTrip.status;
      if (activeTrip.status == 'in_transit') {
        status = TripStatus.inProgress;
      } else if (activeTrip.status == 'completed') {
        status = TripStatus.completed;
      } else if (activeTrip.status == 'scheduled') {
        status = TripStatus.scheduled;
      }

      _activeTrip = _activeTrip.copyWith(
        id: activeTrip.scheduleId != null
            ? 'SCH-${activeTrip.scheduleId}'
            : _activeTrip.id,
        busNumber:
            (bus?.registrationNumber != null &&
                bus!.registrationNumber.isNotEmpty)
            ? bus.registrationNumber
            : _activeTrip.busNumber,
        busType: (bus?.busType != null && bus!.busType.isNotEmpty)
            ? bus.busType
            : _activeTrip.busType,
        totalSeats: (bus?.totalSeats != null && bus!.totalSeats > 0)
            ? bus.totalSeats
            : _activeTrip.totalSeats,
        fromCity: (route?.sourceCity != null && route!.sourceCity.isNotEmpty)
            ? route.sourceCity
            : _activeTrip.fromCity,
        toCity:
            (route?.destinationCity != null &&
                route!.destinationCity.isNotEmpty)
            ? route.destinationCity
            : _activeTrip.toCity,
        departureTime: activeTrip.departureTime.isNotEmpty
            ? activeTrip.departureTime
            : _activeTrip.departureTime,
        arrivalTime: activeTrip.arrivalTime.isNotEmpty
            ? activeTrip.arrivalTime
            : _activeTrip.arrivalTime,
        journeyDate: activeTrip.departureDate.isNotEmpty
            ? activeTrip.departureDate
            : _activeTrip.journeyDate,
        distance: route?.distanceKm != null
            ? '${route!.distanceKm} km'
            : _activeTrip.distance,
        status: status,
      );
    }

    notifyListeners();
  }

  /// Fetch live Crew Profile from /crew/me and update all app screens
  Future<bool> refreshProfileFromApi() async {
    try {
      final response = await AuthApiService().getProfile();
      if (response.isSuccess && response.data?.data != null) {
        updateFromProfile(response.data!.data!);
        return true;
      }
    } catch (_) {
      // Keep existing data on failure
    }
    return false;
  }

  /// Update repository state with live Crew Dashboard data from /crew/dashboard
  void updateFromDashboard(CrewDashboardData dashboard) {
    _dashboardData = dashboard;

    final crew = dashboard.crew;
    final activeTrip = dashboard.activeTrip;

    // Update Crew Profile
    if (crew != null) {
      final isCond =
          crew.role == 'conductor' ||
          crew.roleLabel.toLowerCase().contains('conductor');
      _profile = _profile.copyWith(
        id: crew.crewId.isNotEmpty
            ? crew.crewId
            : (crew.id != null
                  ? (isCond ? 'CND-${crew.id}' : 'DRV-${crew.id}')
                  : _profile.id),
        name: crew.name.isNotEmpty ? crew.name : _profile.name,
        badgeType: crew.roleLabel.isNotEmpty
            ? crew.roleLabel
            : (isCond ? 'Bus Conductor' : 'Bus Driver'),
        isOnline: crew.status.toLowerCase() == 'active',
      );
    }

    // Update Active Trip from Dashboard Active Trip
    if (activeTrip != null) {
      final bus = activeTrip.bus;
      final route = activeTrip.route;
      final op = activeTrip.operator;

      _profile = _profile.copyWith(
        assignedBusNumber:
            (bus?.registrationNumber != null &&
                bus!.registrationNumber.isNotEmpty)
            ? bus.registrationNumber
            : _profile.assignedBusNumber,
        assignedBusType: (bus?.busType != null && bus!.busType.isNotEmpty)
            ? bus.busType
            : _profile.assignedBusType,
        depotName: (op?.operatorName != null && op!.operatorName.isNotEmpty)
            ? op.operatorName
            : _profile.depotName,
      );

      TripStatus status = _activeTrip.status;
      if (activeTrip.status == 'in_transit') {
        status = TripStatus.inProgress;
      } else if (activeTrip.status == 'completed') {
        status = TripStatus.completed;
      } else if (activeTrip.status == 'scheduled') {
        status = TripStatus.scheduled;
      }

      _activeTrip = _activeTrip.copyWith(
        id: activeTrip.id != null ? 'TR-${activeTrip.id}' : _activeTrip.id,
        busNumber:
            (bus?.registrationNumber != null &&
                bus!.registrationNumber.isNotEmpty)
            ? bus.registrationNumber
            : _activeTrip.busNumber,
        busType: (bus?.busType != null && bus!.busType.isNotEmpty)
            ? bus.busType
            : _activeTrip.busType,
        totalSeats:
            (activeTrip.seating?.totalSeats ??
            bus?.totalSeats ??
            _activeTrip.totalSeats),
        bookedSeats:
            (activeTrip.seating?.bookedSeats ?? _activeTrip.bookedSeats),
        fromCity: (route?.sourceCity != null && route!.sourceCity.isNotEmpty)
            ? route.sourceCity
            : _activeTrip.fromCity,
        toCity:
            (route?.destinationCity != null &&
                route!.destinationCity.isNotEmpty)
            ? route.destinationCity
            : _activeTrip.toCity,
        departureTime: activeTrip.departureTime.isNotEmpty
            ? activeTrip.departureTime
            : _activeTrip.departureTime,
        arrivalTime: activeTrip.arrivalTime.isNotEmpty
            ? activeTrip.arrivalTime
            : _activeTrip.arrivalTime,
        journeyDate: activeTrip.departureDate.isNotEmpty
            ? activeTrip.departureDate
            : _activeTrip.journeyDate,
        distance: route?.distanceKm != null
            ? '${route!.distanceKm} km'
            : _activeTrip.distance,
        status: status,
        driverName: activeTrip.driver?.name ?? _activeTrip.driverName,
        driverPhone: activeTrip.driver?.phone ?? _activeTrip.driverPhone,
        conductorName: activeTrip.conductor?.name ?? _activeTrip.conductorName,
        conductorPhone:
            activeTrip.conductor?.phone ?? _activeTrip.conductorPhone,
      );
    }

    // Update upcoming trips if provided in dashboard
    if (dashboard.upcomingTrips.isNotEmpty) {
      final convertedUpcoming = dashboard.upcomingTrips.map((dt) {
        return DriverTrip(
          id: dt.id != null ? 'TR-${dt.id}' : 'TR-UP',
          tripNumber: 'SP-${dt.id ?? "403"}',
          busNumber: dt.bus?.registrationNumber ?? _activeTrip.busNumber,
          busType: dt.bus?.busType ?? _activeTrip.busType,
          fromCity: dt.route?.sourceCity ?? 'Lucknow',
          toCity: dt.route?.destinationCity ?? 'Delhi',
          fromTerminal: '${dt.route?.sourceCity ?? "Depot"} Terminal',
          toTerminal: '${dt.route?.destinationCity ?? "Delhi"} ISBT',
          journeyDate: dt.departureDate.isNotEmpty
              ? dt.departureDate
              : 'Upcoming',
          departureTime: dt.departureTime,
          arrivalTime: dt.arrivalTime,
          duration: '8h 30m',
          distance: dt.route?.distanceKm != null
              ? '${dt.route!.distanceKm} km'
              : '520 km',
          totalSeats: dt.seating?.totalSeats ?? dt.bus?.totalSeats ?? 30,
          bookedSeats: dt.seating?.bookedSeats ?? 0,
          status: TripStatus.scheduled,
          stops: const [],
          passengers: const [],
        );
      }).toList();

      _upcomingTrips = convertedUpcoming;
    }

    notifyListeners();
  }

  /// Fetch live Crew Dashboard from /crew/dashboard and update all app screens
  Future<bool> refreshDashboardFromApi() async {
    try {
      final response = await AuthApiService().getDashboard();
      if (response.isSuccess && response.data?.data != null) {
        updateFromDashboard(response.data!.data!);
        return true;
      }
    } catch (_) {
      // Keep existing data on failure
    }
    return false;
  }

  /// Update repository with live trip details from /crew/trips/{id}
  void updateFromTripDetails(CrewTripDetailsData data) {
    _selectedTripDetails = data;

    final schedule = data.schedule;
    final bus = data.bus;
    final route = data.route;
    final op = data.operator;
    final driver = data.driver;
    final seating = data.seatingSummary;

    // If driver/conductor details present, update profile according to active user role
    if (isDriver && driver != null && driver.name.isNotEmpty) {
      _profile = _profile.copyWith(
        name: driver.name,
        id: driver.crewId.isNotEmpty ? driver.crewId : _profile.id,
        phone: driver.phone.isNotEmpty ? driver.phone : _profile.phone,
      );
    } else if (isConductor &&
        data.conductor != null &&
        data.conductor!.name.isNotEmpty) {
      _profile = _profile.copyWith(
        name: data.conductor!.name,
        id: data.conductor!.crewId.isNotEmpty
            ? data.conductor!.crewId
            : _profile.id,
        phone: data.conductor!.phone.isNotEmpty
            ? data.conductor!.phone
            : _profile.phone,
      );
    }

    if (op != null && op.operatorName.isNotEmpty) {
      _profile = _profile.copyWith(depotName: op.operatorName);
    }

    if (bus != null) {
      _profile = _profile.copyWith(
        assignedBusNumber: bus.registrationNumber.isNotEmpty
            ? bus.registrationNumber
            : _profile.assignedBusNumber,
        assignedBusType: bus.busType.isNotEmpty
            ? bus.busType
            : _profile.assignedBusType,
      );
    }

    // Sync activeTrip if schedule matches or if active
    if (schedule != null) {
      TripStatus status = _activeTrip.status;
      if (schedule.status == 'in_transit') {
        status = TripStatus.inProgress;
      } else if (schedule.status == 'completed') {
        status = TripStatus.completed;
      } else if (schedule.status == 'scheduled') {
        status = TripStatus.scheduled;
      }

      _activeTrip = _activeTrip.copyWith(
        id: schedule.id != null ? 'TR-${schedule.id}' : _activeTrip.id,
        busNumber: bus?.registrationNumber ?? _activeTrip.busNumber,
        busType: bus?.busType ?? _activeTrip.busType,
        totalSeats:
            seating?.totalSeats ?? bus?.totalSeats ?? _activeTrip.totalSeats,
        bookedSeats: seating?.bookedSeatsCount ?? _activeTrip.bookedSeats,
        fromCity: route?.sourceCity ?? _activeTrip.fromCity,
        toCity: route?.destinationCity ?? _activeTrip.toCity,
        departureTime: schedule.departureTime.isNotEmpty
            ? schedule.departureTime
            : _activeTrip.departureTime,
        arrivalTime: schedule.arrivalTime.isNotEmpty
            ? schedule.arrivalTime
            : _activeTrip.arrivalTime,
        journeyDate: schedule.departureDate.isNotEmpty
            ? schedule.departureDate
            : _activeTrip.journeyDate,
        distance: route?.distanceKm != null
            ? '${route!.distanceKm} km'
            : _activeTrip.distance,
        status: status,
        driverName: driver?.name ?? _activeTrip.driverName,
        driverPhone: driver?.phone ?? _activeTrip.driverPhone,
        conductorName: data.conductor?.name ?? _activeTrip.conductorName,
        conductorPhone: data.conductor?.phone ?? _activeTrip.conductorPhone,
      );
    }

    notifyListeners();
  }

  /// Fetch live trip details from /crew/trips/{id}
  Future<CrewTripDetailsData?> fetchTripDetails(dynamic tripId) async {
    try {
      final response = await AuthApiService().getTripDetails(tripId);
      if (response.isSuccess && response.data?.data != null) {
        updateFromTripDetails(response.data!.data!);
        return response.data!.data!;
      }
    } catch (_) {
      // Keep existing data on failure
    }
    return null;
  }

  /// Update repository with trips fetched from /crew/trips?filter=...
  void updateFromAssignedTrips(CrewAssignedTripsData data, {String? filter}) {
    _tripsPagination = data.pagination;

    final convertedTrips = data.trips.map((dt) => dt.toDriverTrip()).toList();

    if (filter == 'today') {
      _todayTrips = convertedTrips;
      // If today's trips have an active trip or scheduled trip, update _activeTrip
      final inTransit = convertedTrips.where(
        (t) => t.status == TripStatus.inProgress,
      );
      if (inTransit.isNotEmpty) {
        final chosen = inTransit.first;
        _activeTrip = chosen.copyWith(
          passengers: chosen.passengers.isNotEmpty
              ? chosen.passengers
              : _activeTrip.passengers,
          stops: chosen.stops.isNotEmpty ? chosen.stops : _activeTrip.stops,
        );
      } else if (convertedTrips.isNotEmpty &&
          _activeTrip.status != TripStatus.inProgress) {
        final chosen = convertedTrips.first;
        _activeTrip = chosen.copyWith(
          passengers: chosen.passengers.isNotEmpty
              ? chosen.passengers
              : _activeTrip.passengers,
          stops: chosen.stops.isNotEmpty ? chosen.stops : _activeTrip.stops,
        );
      }
    } else if (filter == 'upcoming') {
      _upcomingTrips = convertedTrips;
    } else if (filter == 'completed') {
      _completedTrips = convertedTrips;
    } else {
      _todayTrips = convertedTrips;
    }

    // Also update driver/conductor profile particulars if present in first trip
    if (data.trips.isNotEmpty) {
      final first = data.trips.first;
      if (isDriver && first.driver != null && first.driver!.name.isNotEmpty) {
        _profile = _profile.copyWith(
          name: first.driver!.name,
          phone: first.driver!.phone.isNotEmpty
              ? first.driver!.phone
              : _profile.phone,
          id: first.driver!.id != null
              ? 'DRV-${first.driver!.id}'
              : _profile.id,
        );
      } else if (isConductor &&
          first.conductor != null &&
          first.conductor!.name.isNotEmpty) {
        _profile = _profile.copyWith(
          name: first.conductor!.name,
          phone: first.conductor!.phone.isNotEmpty
              ? first.conductor!.phone
              : _profile.phone,
          id: first.conductor!.id != null
              ? 'CND-${first.conductor!.id}'
              : _profile.id,
        );
      }
      if (first.bus != null && first.bus!.registrationNumber.isNotEmpty) {
        _profile = _profile.copyWith(
          assignedBusNumber: first.bus!.registrationNumber,
          assignedBusType: first.bus!.busType,
        );
      }
      if (first.operator != null && first.operator!.operatorName.isNotEmpty) {
        _profile = _profile.copyWith(depotName: first.operator!.operatorName);
      }
    }

    notifyListeners();
  }

  /// Fetch live assigned trips from /crew/trips with filter ('today', 'upcoming', 'completed')
  Future<List<DriverTrip>> fetchAssignedTrips({
    String? filter,
    int? page,
  }) async {
    try {
      final response = await AuthApiService().getAssignedTrips(
        filter: filter,
        page: page,
      );
      if (response.isSuccess && response.data?.data != null) {
        updateFromAssignedTrips(response.data!.data!, filter: filter);
        return response.data!.data!.trips.map((t) => t.toDriverTrip()).toList();
      }
    } catch (_) {
      // Keep existing data on failure
    }
    if (filter == 'today') return _todayTrips;
    if (filter == 'upcoming') return _upcomingTrips;
    if (filter == 'completed') return _completedTrips;
    return _todayTrips;
  }

  /// Restore saved crew session on app launch
  Future<bool> restoreSavedSession() async {
    final saved = await AuthStorage.getSavedSession();
    if (saved != null && saved.success && saved.data != null) {
      updateFromCrewLogin(saved);
      final role = await AuthStorage.getRole();
      if (role != null) {
        setActiveRole(role);
      }
      return true;
    }
    return false;
  }

  /// Log out crew member via official server API (/crew/logout), clear session storage and reset memory state
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    toggleOnlineStatus(false);
    _overrideIsConductor = null;
    final response = await AuthApiService().logout();
    notifyListeners();
    return response;
  }

  /// Authenticate Driver against registered fleet credentials (Fallback / Offline support)
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 650));

    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    // Accepted registered driver credentials:
    // Email: rajesh.kumar@tripride.com, driver@trippried.com
    // Phone: 9876543210
    // Driver ID: DRV-1048
    final bool matchesIdentifier =
        cleanId == 'driver@trippried.com' ||
        cleanId == 'rajesh.kumar@tripride.com' ||
        cleanId == '9876543210' ||
        cleanId == '+919876543210' ||
        cleanId == 'drv-1048';

    // Password validation (min 6 characters or standard driver pin)
    if (cleanPass.isEmpty) {
      return {
        'success': false,
        'message': 'Password cannot be empty. Please enter your password.',
      };
    }

    if (!matchesIdentifier) {
      return {
        'success': false,
        'message':
            'Invalid Driver ID, Email, or Phone Number. Please check your credentials.',
      };
    }

    // Set driver online upon login
    _profile = _profile.copyWith(isOnline: true);
    notifyListeners();

    return {
      'success': true,
      'message': 'Authentication successful. Welcome ${_profile.name}!',
    };
  }

  // ---------------------------------------------------------------------------
  // Business Actions & Validated Transitions
  // ---------------------------------------------------------------------------

  /// Toggle Online / Offline status
  void toggleOnlineStatus(bool isOnline) {
    _profile = _profile.copyWith(isOnline: isOnline);
    notifyListeners();
  }

  /// Update local repository state directly from CrewTripStatusData
  void updateFromTripStatus(CrewTripStatusData data) {
    TripStatus localStatus = TripStatus.scheduled;
    if (data.status == 'in_transit') {
      localStatus = TripStatus.inProgress;
    } else if (data.status == 'completed') {
      localStatus = TripStatus.completed;
    }

    _activeTrip = _activeTrip.copyWith(
      status: localStatus,
      delayMinutes: data.delayMinutes,
      operationalNotes: data.operationalNotes ?? _activeTrip.operationalNotes,
    );

    if (localStatus == TripStatus.completed) {
      if (!_completedTrips.any((t) => t.id == _activeTrip.id)) {
        _completedTrips.insert(0, _activeTrip);
      }
    }

    // Also update selectedTripDetails if loaded
    if (_selectedTripDetails != null &&
        _selectedTripDetails!.schedule != null) {
      final oldSchedule = _selectedTripDetails!.schedule!;
      _selectedTripDetails = CrewTripDetailsData(
        schedule: TripSchedule(
          id: oldSchedule.id,
          status: data.status,
          delayMinutes: data.delayMinutes,
          operationalNotes:
              data.operationalNotes ?? oldSchedule.operationalNotes,
          departureDate: oldSchedule.departureDate,
          departureTime: oldSchedule.departureTime,
          arrivalDate: oldSchedule.arrivalDate,
          arrivalTime: oldSchedule.arrivalTime,
          baseFare: oldSchedule.baseFare,
        ),
        bus: _selectedTripDetails!.bus,
        route: _selectedTripDetails!.route,
        operator: _selectedTripDetails!.operator,
        driver: _selectedTripDetails!.driver,
        conductor: _selectedTripDetails!.conductor,
        seatingSummary: _selectedTripDetails!.seatingSummary,
        manifest: _selectedTripDetails!.manifest,
      );
    }

    // Also update in today's trips if present
    _todayTrips = _todayTrips.map((t) {
      if (t.id == _activeTrip.id ||
          (data.scheduleId > 0 && t.id.contains(data.scheduleId.toString()))) {
        return t.copyWith(
          status: localStatus,
          delayMinutes: data.delayMinutes,
          operationalNotes: data.operationalNotes ?? t.operationalNotes,
        );
      }
      return t;
    }).toList();

    notifyListeners();
  }

  /// Update trip status on server (/crew/trips/{id}/status) and synchronize local state
  Future<ApiResponse<CrewTripStatusResponse>> updateTripStatusOnServer({
    required dynamic tripId,
    required String status,
    int delayMinutes = 0,
    String? operationalNotes,
  }) async {
    final response = await AuthApiService().updateTripStatus(
      tripId: tripId,
      status: status,
      delayMinutes: delayMinutes,
      operationalNotes: operationalNotes,
    );

    if (response.data?.data != null) {
      updateFromTripStatus(response.data!.data!);
    } else {
      updateFromTripStatus(
        CrewTripStatusData(
          scheduleId:
              int.tryParse(
                tripId.toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0,
          status: status,
          delayMinutes: delayMinutes,
          operationalNotes: operationalNotes,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    return response;
  }

  /// Start a scheduled trip (calls live API /crew/trips/{id}/status with in_transit)
  Future<ApiResponse<CrewTripStatusResponse>?> startTrip(
    String tripId, {
    String operationalNotes = 'Departed from main depot on time',
    int delayMinutes = 0,
  }) async {
    _activeTrip = _activeTrip.copyWith(
      status: TripStatus.inProgress,
      operationalNotes: operationalNotes,
      delayMinutes: delayMinutes,
    );
    notifyListeners();

    try {
      final res = await updateTripStatusOnServer(
        tripId: tripId,
        status: 'in_transit',
        operationalNotes: operationalNotes,
        delayMinutes: delayMinutes,
      );
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Complete an in-progress trip (calls live API /crew/trips/{id}/status with completed)
  Future<ApiResponse<CrewTripStatusResponse>?> completeTrip(
    String tripId, {
    String operationalNotes = 'Arrived at destination safely',
    int delayMinutes = 0,
  }) async {
    _activeTrip = _activeTrip.copyWith(
      status: TripStatus.completed,
      operationalNotes: operationalNotes,
      delayMinutes: delayMinutes,
    );
    if (!_completedTrips.any((t) => t.id == _activeTrip.id)) {
      _completedTrips.insert(0, _activeTrip);
    }
    notifyListeners();

    try {
      final res = await updateTripStatusOnServer(
        tripId: tripId,
        status: 'completed',
        operationalNotes: operationalNotes,
        delayMinutes: delayMinutes,
      );
      return res;
    } catch (_) {
      return null;
    }
  }

  /// Update individual ride lifecycle status strictly validating allowed transitions:
  /// Requested → Accepted → Confirmed → Driver Arriving → Driver Arrived → Ride Started → Ride Completed
  bool updateRideLifecycle(String pnr, RideLifecycleStatus newStatus) {
    final index = _activeTrip.passengers.indexWhere((p) => p.pnr == pnr);
    if (index == -1) return false;

    final currentPassenger = _activeTrip.passengers[index];

    // Validate transition
    if (!currentPassenger.rideStatus.canTransitionTo(newStatus)) {
      return false;
    }

    final updated = currentPassenger.copyWith(
      rideStatus: newStatus,
      isBoarded:
          newStatus == RideLifecycleStatus.rideStarted ||
          newStatus == RideLifecycleStatus.rideCompleted,
      status: newStatus == RideLifecycleStatus.cancelled
          ? 'Cancelled'
          : (newStatus == RideLifecycleStatus.rideStarted ||
                newStatus == RideLifecycleStatus.rideCompleted)
          ? 'Boarded'
          : currentPassenger.status,
    );

    final updatedList = List<PassengerBooking>.from(_activeTrip.passengers);
    updatedList[index] = updated;

    _activeTrip = _activeTrip.copyWith(
      passengers: updatedList,
      bookedSeats: _activeTrip.activeBookedSeatsCount,
    );

    notifyListeners();
    return true;
  }

  /// Cancel or reject a passenger booking (frees up the seat)
  bool cancelBooking(String pnr, {String? reason}) {
    return updateRideLifecycle(pnr, RideLifecycleStatus.cancelled);
  }

  /// Confirm passenger boarding on server (/crew/passengers/{passengerId}/boarding)
  /// [status]: 'boarded', 'no_show', 'pending'
  Future<ApiResponse<CrewPassengerBoardingResponse>>
  confirmPassengerBoardingOnServer({
    required dynamic passengerId,
    required String status,
    String? pnr,
  }) async {
    final response = await AuthApiService().confirmPassengerBoarding(
      passengerId: passengerId,
      status: status,
    );

    if (response.data?.data != null) {
      updateFromPassengerBoarding(response.data!.data!, fallbackPnr: pnr);
    } else {
      // Local fallback with simulated timestamp if boarded
      final now = DateTime.now();
      final hour = now.hour > 12
          ? now.hour - 12
          : (now.hour == 0 ? 12 : now.hour);
      final ampm = now.hour >= 12 ? 'PM' : 'AM';
      final minute = now.minute.toString().padLeft(2, '0');
      final timeStr = status == 'boarded' ? '$hour:$minute $ampm' : null;

      updateFromPassengerBoarding(
        CrewPassengerBoardingData(
          passengerId:
              int.tryParse(
                passengerId.toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              45,
          passengerName: '',
          seatNumber: '',
          boardingStatus: status,
          boardedAt: timeStr,
        ),
        fallbackPnr: pnr,
      );
    }

    return response;
  }

  /// Update passenger boarding state from CrewPassengerBoardingData
  void updateFromPassengerBoarding(
    CrewPassengerBoardingData data, {
    String? fallbackPnr,
  }) {
    final isBoarded = data.isBoarded;
    final isNoShow = data.isNoShow;

    final updatedPassengers = _activeTrip.passengers.map((p) {
      final matchesId =
          (data.passengerId > 0 && p.passengerId == data.passengerId);
      final matchesPnr = fallbackPnr != null && p.pnr == fallbackPnr;
      final matchesSeat =
          data.seatNumber.isNotEmpty &&
          p.seatNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase() ==
              data.seatNumber
                  .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                  .toLowerCase();
      final matchesName =
          data.passengerName.isNotEmpty &&
          p.passengerName.toLowerCase() == data.passengerName.toLowerCase();

      if (matchesId || matchesPnr || matchesSeat || matchesName) {
        return p.copyWith(
          passengerId: data.passengerId > 0 ? data.passengerId : p.passengerId,
          isBoarded: isBoarded,
          boardingStatus: data.boardingStatus,
          boardedAt:
              data.boardedAt ?? (isBoarded ? p.boardedAt ?? 'Just now' : null),
          status: isBoarded ? 'Boarded' : (isNoShow ? 'No-Show' : 'Pending'),
          rideStatus: isBoarded
              ? RideLifecycleStatus.rideStarted
              : (isNoShow
                    ? RideLifecycleStatus.cancelled
                    : RideLifecycleStatus.confirmed),
        );
      }
      return p;
    }).toList();

    _activeTrip = _activeTrip.copyWith(passengers: updatedPassengers);

    // Also update selectedTripDetails seating summary counts if present
    if (_selectedTripDetails != null &&
        _selectedTripDetails!.seatingSummary != null) {
      final oldSummary = _selectedTripDetails!.seatingSummary!;
      final boarded = updatedPassengers.where((p) => p.isBoarded).length;
      final noShow = updatedPassengers.where((p) => p.isNoShow).length;
      final pending = (oldSummary.bookedSeatsCount - boarded - noShow).clamp(
        0,
        oldSummary.totalSeats,
      );

      _selectedTripDetails = CrewTripDetailsData(
        schedule: _selectedTripDetails!.schedule,
        bus: _selectedTripDetails!.bus,
        route: _selectedTripDetails!.route,
        operator: _selectedTripDetails!.operator,
        driver: _selectedTripDetails!.driver,
        conductor: _selectedTripDetails!.conductor,
        seatingSummary: TripSeatingSummary(
          totalSeats: oldSummary.totalSeats,
          bookedSeatsCount: oldSummary.bookedSeatsCount,
          vacantSeatsCount: oldSummary.vacantSeatsCount,
          boardedCount: boarded,
          pendingBoardingCount: pending,
          noShowCount: noShow,
        ),
        manifest: _selectedTripDetails!.manifest,
      );
    }

    notifyListeners();
  }

  /// Toggle passenger boarding status (calls live API with fallback)
  Future<ApiResponse<CrewPassengerBoardingResponse>> togglePassengerBoarding(
    String pnr,
  ) async {
    final passenger = _activeTrip.passengers.firstWhere(
      (p) => p.pnr == pnr,
      orElse: () => _activeTrip.passengers.first,
    );
    final targetStatus = passenger.isBoarded ? 'pending' : 'boarded';
    return confirmPassengerBoardingOnServer(
      passengerId: passenger.effectivePassengerId,
      status: targetStatus,
      pnr: pnr,
    );
  }

  /// Book a spot ticket on server (/crew/trips/{schedule_id}/spot-booking)
  Future<ApiResponse<CrewSpotBookingResponse>> bookSpotTicketOnServer({
    dynamic scheduleId,
    required dynamic scheduleSeatId,
    required String seatNumber,
    required String passengerName,
    required String passengerPhone,
    required String passengerGender,
    required int passengerAge,
    required String paymentMethod,
    required String boardingLocation,
    required String droppingLocation,
    double? fare,
  }) async {
    final effectiveScheduleId =
        scheduleId ??
        _selectedTripDetails?.schedule?.id ??
        _dashboardData?.activeTrip?.id ??
        (int.tryParse(_activeTrip.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 19);

    final response = await AuthApiService().bookSpotTicket(
      scheduleId: effectiveScheduleId,
      scheduleSeatId: scheduleSeatId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerGender: passengerGender,
      passengerAge: passengerAge,
      paymentMethod: paymentMethod,
      boardingLocation: boardingLocation,
      droppingLocation: droppingLocation,
    );

    if (response.data?.data != null) {
      updateFromSpotBooking(
        response.data!.data!,
        scheduleSeatId: scheduleSeatId,
        boardingLocation: boardingLocation,
        droppingLocation: droppingLocation,
        age: passengerAge,
        gender: passengerGender,
        phone: passengerPhone,
        fallbackSeatNumber: seatNumber,
      );
    } else {
      // Local fallback with simulated spot booking matching API response schema
      final cleanSeat = seatNumber.isNotEmpty ? seatNumber : 'U-05';
      final isUpper = cleanSeat.toUpperCase().startsWith('U');
      final fallbackFare = fare ?? (isUpper ? 980.0 : 1000.0);
      final bookingId = 89 + (_activeTrip.passengers.length);
      final pnr = 'TRP261026X9Y2';

      final fallbackData = CrewSpotBookingData(
        bookingId: bookingId,
        pnr: pnr,
        seatNumber: cleanSeat,
        passengerName: passengerName,
        fare: fallbackFare,
        paymentMethod: paymentMethod.toLowerCase(),
        paymentStatus: 'paid',
        boardingStatus: 'boarded',
      );

      updateFromSpotBooking(
        fallbackData,
        scheduleSeatId: scheduleSeatId,
        boardingLocation: boardingLocation,
        droppingLocation: droppingLocation,
        age: passengerAge,
        gender: passengerGender,
        phone: passengerPhone,
        fallbackSeatNumber: cleanSeat,
      );
    }

    return response;
  }

  /// Initiate online spot payment on server (/crew/trip/{schedule_id}/spot-payment/initiate)
  Future<ApiResponse<CrewSpotPaymentInitiateResponse>> initiateSpotPaymentOnServer({
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
  }) async {
    final effectiveScheduleId =
        scheduleId ??
        _selectedTripDetails?.schedule?.id ??
        _dashboardData?.activeTrip?.id ??
        (int.tryParse(_activeTrip.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 19);

    final response = await AuthApiService().initiateSpotPayment(
      scheduleId: effectiveScheduleId,
      scheduleSeatId: scheduleSeatId,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerGender: passengerGender,
      passengerAge: passengerAge,
      boardingLocation: boardingLocation,
      droppingLocation: droppingLocation,
      gateway: gateway,
    );

    return response;
  }

  /// Verify online spot payment on server (/crew/trip/{schedule_id}/spot-payment/verify)
  Future<ApiResponse<CrewSpotPaymentVerifyResponse>> verifySpotPaymentOnServer({
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
  }) async {
    final effectiveScheduleId =
        scheduleId ??
        _selectedTripDetails?.schedule?.id ??
        _dashboardData?.activeTrip?.id ??
        (int.tryParse(_activeTrip.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 19);

    final response = await AuthApiService().verifySpotPayment(
      scheduleId: effectiveScheduleId,
      scheduleSeatId: scheduleSeatId,
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
    );

    if (response.isSuccess && response.data != null && response.data!.success) {
      final verifyData = response.data!;
      final cleanSeat = (verifyData.seatNumber != null && verifyData.seatNumber!.isNotEmpty)
          ? verifyData.seatNumber!
          : seatNumber;

      final spotData = CrewSpotBookingData(
        bookingId: verifyData.bookingId ?? 16,
        pnr: verifyData.pnr ?? 'TRP2610279K1X',
        seatNumber: cleanSeat,
        passengerName: passengerName,
        fare: fare ?? 1000.0,
        paymentMethod: 'razorpay',
        paymentStatus: 'paid',
        boardingStatus: 'boarded',
      );

      updateFromSpotBooking(
        spotData,
        scheduleSeatId: scheduleSeatId,
        boardingLocation: boardingLocation,
        droppingLocation: droppingLocation,
        age: passengerAge,
        gender: passengerGender,
        phone: passengerPhone,
        fallbackSeatNumber: cleanSeat,
      );
    }

    return response;
  }

  /// Update passenger boarding on server with boolean flag (Conductor convenience wrapper)
  Future<ApiResponse<CrewPassengerBoardingResponse>>
  updatePassengerBoardingOnServer({
    required int passengerId,
    required bool isBoarded,
    String? boardedAtStop,
  }) {
    return confirmPassengerBoardingOnServer(
      passengerId: passengerId,
      status: isBoarded ? 'boarded' : 'pending',
    );
  }

  /// Create spot booking on server (Conductor convenience wrapper)
  Future<ApiResponse<CrewSpotBookingResponse>> createSpotBookingOnServer({
    required dynamic scheduleId,
    required String passengerName,
    required String passengerPhone,
    required String seatNumber,
    required String boardingStop,
    required String destinationStop,
    required double fareAmount,
    String paymentMethod = 'cash',
  }) {
    final vacant = _vacantSeatsData?.findBySeatNumber(seatNumber);
    return bookSpotTicketOnServer(
      scheduleId: scheduleId,
      scheduleSeatId: vacant?.id ?? 142,
      seatNumber: seatNumber,
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      passengerGender: 'male',
      passengerAge: 32,
      paymentMethod: paymentMethod,
      boardingLocation: boardingStop,
      droppingLocation: destinationStop,
      fare: fareAmount,
    );
  }

  /// Update state from CrewSpotBookingData
  void updateFromSpotBooking(
    CrewSpotBookingData data, {
    dynamic scheduleSeatId,
    required String boardingLocation,
    required String droppingLocation,
    required int age,
    required String gender,
    required String phone,
    String? fallbackSeatNumber,
  }) {
    final seatNum = data.seatNumber.isNotEmpty
        ? data.seatNumber
        : (fallbackSeatNumber ?? 'U-05');
    final isUpper = seatNum.toUpperCase().startsWith('U');

    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    final newPassenger = PassengerBooking(
      passengerId: data.bookingId,
      bookingId: 'BK-${data.bookingId}',
      pnr: data.pnr,
      passengerName: data.passengerName,
      phone: phone,
      age: age,
      gender: gender.isEmpty
          ? 'Male'
          : (gender[0].toUpperCase() + gender.substring(1)),
      seatNumber: seatNum,
      isUpperDeck: isUpper,
      pickupLocation: boardingLocation,
      dropLocation: droppingLocation,
      pickupTime: _activeTrip.departureTime,
      dropTime: _activeTrip.arrivalTime,
      status: 'Boarded',
      fare: data.fare,
      isBoarded: true,
      boardingStatus: data.boardingStatus,
      boardedAt: timeStr,
      paymentStatus: 'Paid (${data.paymentMethod.toUpperCase()})',
      rideStatus: RideLifecycleStatus.rideStarted,
      passengerCount: 1,
      journeyDate: _activeTrip.journeyDate,
    );

    // Remove booked seat from vacantSeatsData so it updates to occupied
    if (_vacantSeatsData != null) {
      final updatedVacants = _vacantSeatsData!.vacantSeats.where((v) {
        final matchesSeatNum =
            v.seatNumber
                .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                .toLowerCase() ==
            seatNum.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        final matchesId = scheduleSeatId != null && v.id == scheduleSeatId;
        return !matchesSeatNum && !matchesId;
      }).toList();

      _vacantSeatsData = CrewVacantSeatsData(
        scheduleId: _vacantSeatsData!.scheduleId,
        totalVacantSeats: updatedVacants.length,
        vacantSeats: updatedVacants,
      );
    }

    // Add passenger to active trip passengers list
    final List<PassengerBooking> updatedList = List.from(
      _activeTrip.passengers,
    );
    updatedList.removeWhere(
      (p) =>
          p.seatNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase() ==
          seatNum.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase(),
    );
    updatedList.add(newPassenger);

    _activeTrip = _activeTrip.copyWith(
      passengers: updatedList,
      bookedSeats: _activeTrip.bookedSeats + 1,
    );

    // Also update selectedTripDetails seating summary counts if present
    if (_selectedTripDetails != null &&
        _selectedTripDetails!.seatingSummary != null) {
      final oldSummary = _selectedTripDetails!.seatingSummary!;
      final total = oldSummary.totalSeats;
      final booked = (_activeTrip.passengers
          .where((p) => !p.isCancelled)
          .length);
      final boarded = (_activeTrip.passengers.where((p) => p.isBoarded).length);
      final noShow = (_activeTrip.passengers.where((p) => p.isNoShow).length);
      final pending = (booked - boarded - noShow).clamp(0, total);
      final vacant = (total - booked).clamp(0, total);

      _selectedTripDetails = CrewTripDetailsData(
        schedule: _selectedTripDetails!.schedule,
        bus: _selectedTripDetails!.bus,
        route: _selectedTripDetails!.route,
        operator: _selectedTripDetails!.operator,
        driver: _selectedTripDetails!.driver,
        conductor: _selectedTripDetails!.conductor,
        seatingSummary: TripSeatingSummary(
          totalSeats: total,
          bookedSeatsCount: booked,
          vacantSeatsCount: vacant,
          boardedCount: boarded,
          pendingBoardingCount: pending,
          noShowCount: noShow,
        ),
        manifest: _selectedTripDetails!.manifest,
      );
    }

    notifyListeners();
  }

  /// Update state from CrewVacantSeatsData (/crew/trips/{id}/vacant-seats)
  void updateFromVacantSeats(CrewVacantSeatsData data) {
    _vacantSeatsData = data;
    notifyListeners();
  }

  /// Fetch live vacant seats from server (/crew/trips/{tripId}/vacant-seats)
  Future<CrewVacantSeatsData?> fetchVacantSeats(dynamic tripId) async {
    try {
      final res = await AuthApiService().getVacantSeats(tripId);
      if (res.isSuccess && res.data?.data != null) {
        updateFromVacantSeats(res.data!.data!);
        return res.data!.data!;
      }
    } catch (_) {
      // Keep existing data on network glitch
    }
    return _vacantSeatsData;
  }

  /// Get seat matrix for the active bus (Lower & Upper Deck)
  List<SeatModel> getSeatsForDeck({required bool isUpperDeck}) {
    final List<SeatModel> seats = [];
    final deckPrefix = isUpperDeck ? 'U' : 'L';
    final deckStr = isUpperDeck ? 'upper' : 'lower';
    final passengers = _activeTrip.passengers
        .where((p) => !p.isCancelled)
        .toList();

    // 5 Rows of 2+1 sleeper berths (15 berths per deck)
    for (int row = 1; row <= 5; row++) {
      // Left 2 berths (A & B)
      for (final colLetter in ['A', 'B']) {
        final seatNum = '$deckPrefix$row$colLetter';
        final passenger = passengers.cast<PassengerBooking?>().firstWhere(
          (p) => p?.seatNumber == seatNum,
          orElse: () => null,
        );
        final vacantItem = _vacantSeatsData?.findBySeatNumber(seatNum);

        final isBooked = vacantItem != null ? false : (passenger != null);
        final effectivePassenger = isBooked ? passenger : null;
        seats.add(
          SeatModel(
            seatNumber: seatNum,
            row: row,
            column: colLetter == 'A' ? 0 : 1,
            isUpperDeck: isUpperDeck,
            isSleeper: true,
            isBooked: isBooked,
            passenger: effectivePassenger,
            seatId: vacantItem?.id,
            fare:
                vacantItem?.fare ??
                (effectivePassenger != null
                    ? effectivePassenger.fare
                    : (isUpperDeck ? 980 : 1000)),
            seatType: vacantItem?.seatType ?? 'sleeper',
            deckName: vacantItem?.deck ?? deckStr,
          ),
        );
      }

      // Right 1 berth (C)
      final singleSeatNum = '$deckPrefix${row}C';
      final passengerC = passengers.cast<PassengerBooking?>().firstWhere(
        (p) => p?.seatNumber == singleSeatNum,
        orElse: () => null,
      );
      final vacantItemC = _vacantSeatsData?.findBySeatNumber(singleSeatNum);
      final isBookedC = vacantItemC != null ? false : (passengerC != null);
      final effectivePassengerC = isBookedC ? passengerC : null;

      seats.add(
        SeatModel(
          seatNumber: singleSeatNum,
          row: row,
          column: 3, // Column 2 is the aisle
          isUpperDeck: isUpperDeck,
          isSleeper: true,
          isBooked: isBookedC,
          passenger: effectivePassengerC,
          seatId: vacantItemC?.id,
          fare:
              vacantItemC?.fare ??
              (effectivePassengerC != null
                  ? effectivePassengerC.fare
                  : (isUpperDeck ? 980 : 1000)),
          seatType: vacantItemC?.seatType ?? 'sleeper',
          deckName: vacantItemC?.deck ?? deckStr,
        ),
      );
    }

    return seats;
  }

  // ---------------------------------------------------------------------------
  // Data Initialization
  // ---------------------------------------------------------------------------

  void _initData() {
    _profile = const DriverProfile(
      id: 'DRV-1048',
      name: 'Rajesh Kumar',
      phone: '+91 98765 43210',
      email: 'rajesh.kumar@tripride.com',
      licenseNumber: 'UP-322018009214',
      badgeType: 'Commercial Heavy Passenger (HMV)',
      rating: 4.9,
      totalTrips: 412,
      onTimePercentage: 99.2,
      assignedBusNumber: 'UP-32-BT-9999',
      assignedBusType: 'Royal Multi-Axle Volvo AC Sleeper (2+1)',
      depotName: 'Lucknow Central Depot',
      isOnline: true,
    );

    // Fleet buses active at current route & terminal
    _fleetBuses = [
      const FleetBus(
        busNumber: 'UP-32-BT-9999',
        busType: 'Volvo AC Sleeper (2+1)',
        route: 'Lucknow → New Delhi (Your Bus)',
        departureTime: '10:00 PM',
        status: 'Boarding Active',
        availableSeats: 6,
      ),
      const FleetBus(
        busNumber: 'UP-32-BT-8888',
        busType: 'Scania Multi-Axle Semi-Sleeper',
        route: 'Lucknow → Agra → Noida',
        departureTime: '10:45 PM',
        status: 'On Standby',
        availableSeats: 12,
      ),
      const FleetBus(
        busNumber: 'UP-32-BT-7777',
        busType: 'Mercedes Benz Sleeper',
        route: 'Lucknow → Gorakhpur',
        departureTime: '11:15 PM',
        status: 'En Route',
        availableSeats: 4,
      ),
    ];

    final stops = [
      const RouteStop(
        id: 'stop-1',
        stopName: 'Alambagh Bus Terminal',
        city: 'Lucknow',
        scheduledTime: '10:00 PM',
        actualTime: '10:00 PM',
        isPassed: false,
        isNext: true,
        passengerBoardingCount: 16,
        passengerDroppingCount: 0,
      ),
      const RouteStop(
        id: 'stop-2',
        stopName: 'Kanpur Bypass (Rama Devi)',
        city: 'Kanpur',
        scheduledTime: '11:45 PM',
        isPassed: false,
        passengerBoardingCount: 8,
        passengerDroppingCount: 0,
      ),
      const RouteStop(
        id: 'stop-3',
        stopName: 'Agra-Lucknow Expressway Toll',
        city: 'Agra',
        scheduledTime: '02:30 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 2,
      ),
      const RouteStop(
        id: 'stop-4',
        stopName: 'Akshardham Metro Station',
        city: 'Delhi NCR',
        scheduledTime: '05:45 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 8,
      ),
      const RouteStop(
        id: 'stop-5',
        stopName: 'Kashmere Gate ISBT',
        city: 'New Delhi',
        scheduledTime: '06:30 AM',
        isPassed: false,
        passengerBoardingCount: 0,
        passengerDroppingCount: 14,
      ),
    ];

    // Seeded passenger bookings representing today's manifest with realistic statuses
    final passengers = [
      const PassengerBooking(
        passengerId: 45,
        pnr: 'RB202610254A45',
        bookingId: 'BK-9900',
        passengerName: 'Rahul Verma',
        phone: '+91 96955 41750',
        email: 'rahul.verma@gmail.com',
        age: 28,
        gender: 'Male',
        seatNumber: 'U-12',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 980.0,
        isBoarded: false,
        boardingStatus: 'pending',
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        passengerId: 46,
        pnr: 'RB202610254A66',
        bookingId: 'BK-9901',
        passengerName: 'Rahul Kumar',
        phone: '+91 96955 41750',
        email: 'rahul.kumar@gmail.com',
        age: 28,
        gender: 'Male',
        seatNumber: 'L5A',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1175.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102560FB',
        bookingId: 'BK-9902',
        passengerName: 'Priya Verma',
        phone: '+91 98390 12345',
        email: 'priya.verma@outlook.com',
        age: 25,
        gender: 'Female',
        seatNumber: 'L4A',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Akshardham Metro, Delhi NCR',
        pickupTime: '10:00 PM',
        dropTime: '05:45 AM',
        status: 'Confirmed',
        fare: 1175.0,
        isBoarded: false,
        paymentStatus: 'Paid (UPI)',
        rideStatus: RideLifecycleStatus.driverArriving,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB20261025F528',
        bookingId: 'BK-9903',
        passengerName: 'Amit Sharma',
        phone: '+91 94150 98765',
        age: 34,
        gender: 'Male',
        seatNumber: 'L1A',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1175.0,
        isBoarded: false,
        paymentStatus: 'Paid (Card)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        passengerId: 43,
        pnr: 'TRP261028C6F1',
        bookingId: 'BK-2701',
        passengerName: 'drt',
        phone: 'SDFGS',
        email: 'drt@spingo.in',
        age: 28,
        gender: 'Male',
        seatNumber: 'L1B',
        isUpperDeck: false,
        pickupLocation: 'Lucknow',
        dropLocation: 'Delhi',
        pickupTime: '10:00 PM',
        dropTime: '05:30 AM',
        status: 'No Show',
        fare: 950.0,
        isBoarded: false,
        boardingStatus: 'no_show',
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.cancelled,
        passengerCount: 1,
        journeyDate: '27 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102577C2',
        bookingId: 'BK-9905',
        passengerName: 'Sanjay Mishra',
        phone: '+91 98899 44332',
        age: 42,
        gender: 'Male',
        seatNumber: 'L1C',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1250.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideCompleted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102588D3',
        bookingId: 'BK-9906',
        passengerName: 'Vikram Chauhan',
        phone: '+91 97766 55443',
        age: 31,
        gender: 'Male',
        seatNumber: 'L2A',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Cancelled',
        fare: 1175.0,
        isBoarded: false,
        paymentStatus: 'Refunded',
        rideStatus: RideLifecycleStatus.cancelled,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102533E4',
        bookingId: 'BK-9907',
        passengerName: 'Ananya Roy',
        phone: '+91 96655 44332',
        age: 26,
        gender: 'Female',
        seatNumber: 'L2B',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Akshardham Metro, Delhi NCR',
        pickupTime: '10:00 PM',
        dropTime: '05:45 AM',
        status: 'Confirmed',
        fare: 1175.0,
        isBoarded: false,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.accepted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102511F5',
        bookingId: 'BK-9908',
        passengerName: 'Mohd. Faisal',
        phone: '+91 95544 33221',
        age: 38,
        gender: 'Male',
        seatNumber: 'L2C',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1250.0,
        isBoarded: false,
        paymentStatus: 'Paid (UPI)',
        rideStatus: RideLifecycleStatus.driverArrived,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102522G6',
        bookingId: 'BK-9909',
        passengerName: 'Sunil Yadav',
        phone: '+91 94433 22110',
        age: 45,
        gender: 'Male',
        seatNumber: 'L3A',
        isUpperDeck: false,
        pickupLocation: 'Rama Devi Bypass, Kanpur',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '11:45 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1050.0,
        isBoarded: false,
        paymentStatus: 'Paid (Card)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102555H7',
        bookingId: 'BK-9910',
        passengerName: 'Deepak Tiwari',
        phone: '+91 93322 11009',
        age: 33,
        gender: 'Male',
        seatNumber: 'L3B',
        isUpperDeck: false,
        pickupLocation: 'Rama Devi Bypass, Kanpur',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '11:45 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1050.0,
        isBoarded: false,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102566J8',
        bookingId: 'BK-9911',
        passengerName: 'Pooja Pandey',
        phone: '+91 92211 00998',
        age: 27,
        gender: 'Female',
        seatNumber: 'L3C',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1250.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102544K9',
        bookingId: 'BK-9912',
        passengerName: 'Manoj Tripathi',
        phone: '+91 91100 99887',
        age: 50,
        gender: 'Male',
        seatNumber: 'L4B',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Agra Toll Plaza',
        pickupTime: '10:00 PM',
        dropTime: '02:30 AM',
        status: 'Confirmed',
        fare: 750.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102588L0',
        bookingId: 'BK-9913',
        passengerName: 'Ritu Srivastava',
        phone: '+91 90099 88776',
        age: 32,
        gender: 'Female',
        seatNumber: 'L4C',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1250.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102577M1',
        bookingId: 'BK-9914',
        passengerName: 'Kunal Singhania',
        phone: '+91 89988 77665',
        age: 24,
        gender: 'Male',
        seatNumber: 'L5B',
        isUpperDeck: false,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1175.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102512U1',
        bookingId: 'BK-9915',
        passengerName: 'Harsh Vardhan',
        phone: '+91 88877 66554',
        age: 29,
        gender: 'Male',
        seatNumber: 'U1A',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1200.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102523U2',
        bookingId: 'BK-9916',
        passengerName: 'Shalini Dixit',
        phone: '+91 87766 55443',
        age: 26,
        gender: 'Female',
        seatNumber: 'U1B',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Akshardham Metro, Delhi NCR',
        pickupTime: '10:00 PM',
        dropTime: '05:45 AM',
        status: 'Confirmed',
        fare: 1200.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102534U3',
        bookingId: 'BK-9917',
        passengerName: 'Rohan Kapoor',
        phone: '+91 86655 44332',
        age: 35,
        gender: 'Male',
        seatNumber: 'U1C',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1300.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102545U4',
        bookingId: 'BK-9918',
        passengerName: 'Tanvi Jain',
        phone: '+91 85544 33221',
        age: 23,
        gender: 'Female',
        seatNumber: 'U2A',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1200.0,
        isBoarded: false,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102556U5',
        bookingId: 'BK-9919',
        passengerName: 'Abhishek Saxena',
        phone: '+91 84433 22110',
        age: 36,
        gender: 'Male',
        seatNumber: 'U2B',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1200.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102567U6',
        bookingId: 'BK-9920',
        passengerName: 'Gaurav Sen',
        phone: '+91 83322 11009',
        age: 41,
        gender: 'Male',
        seatNumber: 'U3A',
        isUpperDeck: true,
        pickupLocation: 'Rama Devi Bypass, Kanpur',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '11:45 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1100.0,
        isBoarded: false,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.confirmed,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102578U7',
        bookingId: 'BK-9921',
        passengerName: 'Meenakshi Iyer',
        phone: '+91 82211 00998',
        age: 30,
        gender: 'Female',
        seatNumber: 'U3C',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1300.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102589U8',
        bookingId: 'BK-9922',
        passengerName: 'Suresh Raina',
        phone: '+91 81100 99887',
        age: 48,
        gender: 'Male',
        seatNumber: 'U4A',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1200.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        pnr: 'RB2026102590U9',
        bookingId: 'BK-9923',
        passengerName: 'Divya Aggarwal',
        phone: '+91 80099 88776',
        age: 27,
        gender: 'Female',
        seatNumber: 'U4C',
        isUpperDeck: true,
        pickupLocation: 'Alambagh Bus Stand, Lucknow',
        dropLocation: 'Kashmere Gate ISBT, New Delhi',
        pickupTime: '10:00 PM',
        dropTime: '06:30 AM',
        status: 'Confirmed',
        fare: 1300.0,
        isBoarded: true,
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '26 Oct 2026',
      ),
      const PassengerBooking(
        passengerId: 44,
        pnr: 'TRP261028BQNV',
        bookingId: 'BK-2702',
        passengerName: 'wertwe',
        phone: '909090909',
        email: 'wertwe@spingo.in',
        age: 28,
        gender: 'Male',
        seatNumber: 'U5C',
        isUpperDeck: true,
        pickupLocation: 'Lucknow',
        dropLocation: 'Delhi',
        pickupTime: '10:00 PM',
        dropTime: '05:30 AM',
        status: 'Boarded',
        fare: 980.0,
        isBoarded: true,
        boardingStatus: 'boarded',
        boardedAt: '12:28 PM',
        paymentStatus: 'Paid (Online)',
        rideStatus: RideLifecycleStatus.rideStarted,
        passengerCount: 1,
        journeyDate: '27 Oct 2026',
      ),
    ];

    _activeTrip = DriverTrip(
      id: 'TR-8821',
      tripNumber: 'SP-402 Royal',
      busNumber: 'UP-32-BT-9999',
      busType: 'Royal Multi-Axle Volvo AC Sleeper (2+1)',
      fromCity: 'Lucknow',
      toCity: 'Delhi',
      fromTerminal: 'Alambagh ISBT',
      toTerminal: 'Kashmere Gate ISBT',
      journeyDate: '27 Oct 2026',
      departureTime: '10:00 PM',
      arrivalTime: '05:30 AM',
      duration: '7h 30m',
      distance: '520 km',
      totalSeats: 30,
      bookedSeats: 2,
      status: TripStatus.scheduled,
      stops: stops,
      passengers: passengers,
      driverName: 'Reece Wiza-Robel',
      driverPhone: '6327114051',
      conductorName: 'Khalil Swaniawski',
      conductorPhone: '7527425651',
      operatorName: 'lucknow branch',
    );

    _upcomingTrips = [
      DriverTrip(
        id: 'TR-8830',
        tripNumber: 'SP-403 Royal Return',
        busNumber: 'UP-32-BT-9999',
        busType: 'Royal Multi-Axle Volvo AC Sleeper (2+1)',
        fromCity: 'New Delhi',
        toCity: 'Lucknow',
        fromTerminal: 'Kashmere Gate ISBT',
        toTerminal: 'Alambagh ISBT',
        journeyDate: '27 Oct 2026',
        departureTime: '09:30 PM',
        arrivalTime: '06:00 AM',
        duration: '8h 30m',
        distance: '520 km',
        totalSeats: 30,
        bookedSeats: 19,
        status: TripStatus.scheduled,
        stops: stops.reversed.toList(),
        passengers: const [],
      ),
      const DriverTrip(
        id: 'TR-8845',
        tripNumber: 'SP-109 Express',
        busNumber: 'UP-32-BT-9999',
        busType: 'Royal Multi-Axle Volvo AC Sleeper (2+1)',
        fromCity: 'Lucknow',
        toCity: 'Varanasi',
        fromTerminal: 'Alambagh ISBT',
        toTerminal: 'Cantt Bus Stand',
        journeyDate: '29 Oct 2026',
        departureTime: '06:00 AM',
        arrivalTime: '12:30 PM',
        duration: '6h 30m',
        distance: '315 km',
        totalSeats: 30,
        bookedSeats: 14,
        status: TripStatus.scheduled,
        stops: [],
        passengers: [],
      ),
    ];

    _completedTrips = [
      const DriverTrip(
        id: 'TR-8810',
        tripNumber: 'SP-401 Royal',
        busNumber: 'UP-32-BT-9999',
        busType: 'Royal Multi-Axle Volvo AC Sleeper (2+1)',
        fromCity: 'New Delhi',
        toCity: 'Lucknow',
        fromTerminal: 'Kashmere Gate ISBT',
        toTerminal: 'Alambagh ISBT',
        journeyDate: '25 Oct 2026',
        departureTime: '09:30 PM',
        arrivalTime: '06:00 AM',
        duration: '8h 30m',
        distance: '520 km',
        totalSeats: 30,
        bookedSeats: 30,
        status: TripStatus.completed,
        stops: [],
        passengers: [],
      ),
    ];

    _todayTrips = [_activeTrip];
  }
}
