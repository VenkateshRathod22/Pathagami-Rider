/// Global API Configuration Constants for SPINGO Bus Driver & Conductor Portal
class ApiConstants {
  ApiConstants._();

  /// Production Base URL
  static const String baseUrl = 'https://spingoride.com/api/v1';

  /// Crew Endpoints (Driver & Conductor)
  static const String crewLoginEndpoint = '/crew/login';
  static const String crewProfileEndpoint = '/crew/me';
  static const String crewMeEndpoint = '/crew/me';
  static const String crewDashboardEndpoint = '/crew/dashboard';
  static const String crewDutySummaryEndpoint = '/crew/duty-summary';
  static const String crewActiveTripEndpoint = '/crew/active-trip';
  static const String crewTripsEndpoint = '/crew/trips';
  static String crewTripsWithFilterEndpoint({String? filter, int? page}) {
    final params = <String>[];
    if (filter != null && filter.isNotEmpty) params.add('filter=$filter');
    if (page != null && page > 0) params.add('page=$page');
    if (params.isEmpty) return crewTripsEndpoint;
    return '$crewTripsEndpoint?${params.join('&')}';
  }
  static String crewTripDetailsEndpoint(dynamic tripId) => '/crew/trips/$tripId';
  static String crewTripStatusEndpoint(dynamic tripId) => '/crew/trips/$tripId/status';
  static String crewTripVacantSeatsEndpoint(dynamic tripId) => '/crew/trips/$tripId/vacant-seats';
  static String crewPassengerBoardingEndpoint(dynamic passengerId) =>
      '/crew/passengers/$passengerId/boarding';
  static String crewTripSpotBookingEndpoint(dynamic scheduleId) =>
      '/crew/trips/$scheduleId/spot-booking';
  static String crewTripSpotPaymentInitiateEndpoint(dynamic scheduleId) =>
      '/crew/trip/$scheduleId/spot-payment/initiate';
  static String crewTripSpotPaymentVerifyEndpoint(dynamic scheduleId) =>
      '/crew/trip/$scheduleId/spot-payment/verify';
  static const String crewLogoutEndpoint = '/crew/logout';

  /// Request Timeouts
  static const Duration timeoutDuration = Duration(seconds: 20);

  /// Standard Headers
  static Map<String, String> defaultHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
