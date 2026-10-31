import 'dart:developer' as developer;
import 'package:bus_driver/api/api_client.dart';
import 'package:bus_driver/api/api_constants.dart';
import 'package:bus_driver/api/auth_storage.dart';
import 'package:bus_driver/api/models/crew_login_response.dart';
import 'package:bus_driver/api/models/crew_dashboard_response.dart';
import 'package:bus_driver/api/models/crew_trip_details_response.dart';
import 'package:bus_driver/api/models/crew_assigned_trips_response.dart';
import 'package:bus_driver/api/models/crew_trip_status_response.dart';
import 'package:bus_driver/api/models/crew_vacant_seats_response.dart';
import 'package:bus_driver/api/models/crew_passenger_boarding_response.dart';
import 'package:bus_driver/api/models/crew_spot_booking_response.dart';
import 'package:bus_driver/api/models/crew_spot_payment_initiate_response.dart';
import 'package:bus_driver/api/models/crew_spot_payment_verify_response.dart';

/// Authentication Service for Bus Driver and Conductor
class AuthApiService {
  final ApiClient _client;

  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Authenticate Driver or Conductor via /crew/login
  ///
  /// [identifier]: Driver/Conductor Email, Phone Number, or Badge ID (e.g. DRV00001, CND00001)
  /// [password]: Account password
  Future<ApiResponse<CrewLoginResponse>> login({
    required String identifier,
    required String password,
  }) async {
    final cleanLogin = identifier.trim();
    final cleanPass = password.trim();

    if (cleanLogin.isEmpty) {
      return ApiResponse.error(
        message: 'Please enter your registered Email, Phone, or Crew Badge ID.',
        statusCode: 422,
      );
    }

    if (cleanPass.isEmpty) {
      return ApiResponse.error(
        message: 'Please enter your password.',
        statusCode: 422,
      );
    }

    // Build payload matching API specifications:
    // API accepts `login` which covers Email, Phone, or Crew ID
    final body = <String, dynamic>{
      'login': cleanLogin,
      'password': cleanPass,
    };

    // If identifier is an email, also include 'email' for full compatibility
    if (cleanLogin.contains('@')) {
      body['email'] = cleanLogin;
    } else if (RegExp(r'^[0-9+ ]{8,15}$').hasMatch(cleanLogin)) {
      body['phone'] = cleanLogin.replaceAll(RegExp(r'[^0-9]'), '');
    } else if (cleanLogin.toUpperCase().startsWith('DRV') ||
        cleanLogin.toUpperCase().startsWith('CND')) {
      body['crew_id'] = cleanLogin.toUpperCase();
    }

    developer.log('Submitting crew login for: $cleanLogin', name: 'AuthApiService');

    final response = await _client.post(
      ApiConstants.crewLoginEndpoint,
      body: body,
      attachAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final loginResponse = CrewLoginResponse.fromJson(response.data!);

        if (loginResponse.success && loginResponse.data != null) {
          // Persist session to local storage
          await AuthStorage.saveSession(loginResponse);

          return ApiResponse.success(
            data: loginResponse,
            message: loginResponse.message.isNotEmpty
                ? loginResponse.message
                : 'Logged in successfully. Welcome aboard!',
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        } else {
          return ApiResponse.error(
            message: loginResponse.firstErrorMessage,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        }
      } catch (e, stack) {
        developer.log('Failed to parse login response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing login data. Please try again.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Authentication failed. Please check your credentials.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Log out Driver or Conductor via /crew/logout and revoke access token
  ///
  /// Endpoint: https://spingoride.com/api/v1/crew/logout
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    ApiResponse<Map<String, dynamic>> response;
    try {
      response = await _client.post(
        ApiConstants.crewLogoutEndpoint,
        attachAuth: true,
      );
      developer.log(
        'Server crew logout response [${response.statusCode}]: ${response.message}',
        name: 'AuthApiService',
      );
    } catch (e) {
      developer.log('Server logout error: $e', name: 'AuthApiService');
      response = ApiResponse.error(
        message: 'Network error during logout: ${e.toString()}',
      );
    } finally {
      await AuthStorage.clearSession();
    }
    return response;
  }

  /// Fetch live Crew Profile from /crew/me
  Future<ApiResponse<CrewProfileResponse>> getProfile() async {
    final response = await _client.get(
      ApiConstants.crewMeEndpoint,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final profileResponse = CrewProfileResponse.fromJson(response.data!);
        if (profileResponse.success && profileResponse.data != null) {
          // Update cached profile in storage
          await AuthStorage.updateCachedProfile(profileResponse.data!);
          return ApiResponse.success(
            data: profileResponse,
            message: profileResponse.message,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        } else {
          return ApiResponse.error(
            message: profileResponse.firstErrorMessage,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        }
      } catch (e, stack) {
        developer.log('Failed to parse crew/me response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing crew profile data.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not fetch profile from server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Fetch live Crew Dashboard from /crew/dashboard
  Future<ApiResponse<CrewDashboardResponse>> getDashboard() async {
    final response = await _client.get(
      ApiConstants.crewDashboardEndpoint,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final dashboardResponse = CrewDashboardResponse.fromJson(response.data!);
        if (dashboardResponse.success && dashboardResponse.data != null) {
          return ApiResponse.success(
            data: dashboardResponse,
            message: dashboardResponse.message,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        } else {
          return ApiResponse.error(
            message: dashboardResponse.firstErrorMessage,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        }
      } catch (e, stack) {
        developer.log('Failed to parse crew/dashboard response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing crew dashboard data.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not fetch dashboard from server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Fetch live Trip Details from /crew/trips/{tripId}
  Future<ApiResponse<CrewTripDetailsResponse>> getTripDetails(dynamic tripId) async {
    // Sanitize tripId: e.g. "TR-19" -> "19", "SCH-19" -> "19"
    String cleanId = tripId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) {
      cleanId = match.group(0)!;
    } else {
      cleanId = '19';
    }

    final endpoint = ApiConstants.crewTripDetailsEndpoint(cleanId);

    final response = await _client.get(
      endpoint,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final tripDetailsResponse = CrewTripDetailsResponse.fromJson(response.data!);
        if (tripDetailsResponse.success && tripDetailsResponse.data != null) {
          return ApiResponse.success(
            data: tripDetailsResponse,
            message: tripDetailsResponse.message,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        } else {
          return ApiResponse.error(
            message: tripDetailsResponse.firstErrorMessage,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        }
      } catch (e, stack) {
        developer.log('Failed to parse crew/trips/$cleanId response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing trip details data.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not fetch trip details from server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Fetch assigned trips with optional filter (e.g. 'today', 'upcoming', 'completed') and pagination
  Future<ApiResponse<CrewAssignedTripsResponse>> getAssignedTrips({
    String? filter,
    int? page,
  }) async {
    final endpoint = ApiConstants.crewTripsWithFilterEndpoint(
      filter: filter,
      page: page,
    );

    final response = await _client.get(
      endpoint,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final assignedTripsResponse = CrewAssignedTripsResponse.fromJson(response.data!);
        if (assignedTripsResponse.success && assignedTripsResponse.data != null) {
          return ApiResponse.success(
            data: assignedTripsResponse,
            message: assignedTripsResponse.message,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        } else {
          return ApiResponse.error(
            message: assignedTripsResponse.firstErrorMessage,
            statusCode: response.statusCode,
            rawJson: response.rawJson,
          );
        }
      } catch (e, stack) {
        developer.log('Failed to parse crew/trips response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing assigned trips data.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not fetch assigned trips from server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Update Trip Status on server (/crew/trips/{tripId}/status)
  /// e.g. status: "in_transit", delay_minutes: 0, operational_notes: "Departed from main depot on time"
  Future<ApiResponse<CrewTripStatusResponse>> updateTripStatus({
    required dynamic tripId,
    required String status,
    int delayMinutes = 0,
    String? operationalNotes,
  }) async {
    // Sanitize tripId
    String cleanId = tripId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) {
      cleanId = match.group(0)!;
    } else {
      cleanId = '19';
    }

    final endpoint = ApiConstants.crewTripStatusEndpoint(cleanId);

    final payload = <String, dynamic>{
      'status': status,
      'delay_minutes': delayMinutes,
      'operational_notes': ?operationalNotes,
    };

    var response = await _client.post(
      endpoint,
      body: payload,
      attachAuth: true,
    );

    // If method not allowed for post, fallback to put
    if (response.statusCode == 405) {
      response = await _client.put(
        endpoint,
        body: payload,
        attachAuth: true,
      );
    }

    if (response.isSuccess && response.data != null) {
      try {
        final statusResponse = CrewTripStatusResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: statusResponse,
          message: statusResponse.message.isNotEmpty
              ? statusResponse.message
              : 'Trip status updated successfully.',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse trip status response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing trip status response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not update trip status on server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Fetch Vacant Seats for trip from server (/crew/trips/{tripId}/vacant-seats)
  Future<ApiResponse<CrewVacantSeatsResponse>> getVacantSeats(dynamic tripId) async {
    String cleanId = tripId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) {
      cleanId = match.group(0)!;
    } else {
      cleanId = '19';
    }

    final endpoint = ApiConstants.crewTripVacantSeatsEndpoint(cleanId);
    final response = await _client.get(
      endpoint,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final vacantSeatsResponse = CrewVacantSeatsResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: vacantSeatsResponse,
          message: vacantSeatsResponse.message.isNotEmpty
              ? vacantSeatsResponse.message
              : 'Vacant seats retrieved successfully.',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse vacant seats response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing vacant seats response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not fetch vacant seats from server.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Confirm Passenger Boarding status on server (/crew/passengers/{passengerId}/boarding)
  /// [status]: 'boarded', 'no_show', 'pending'
  Future<ApiResponse<CrewPassengerBoardingResponse>> confirmPassengerBoarding({
    required dynamic passengerId,
    required String status,
  }) async {
    String cleanId = passengerId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) {
      cleanId = match.group(0)!;
    } else {
      cleanId = '45';
    }

    final endpoint = ApiConstants.crewPassengerBoardingEndpoint(cleanId);
    final payload = <String, dynamic>{
      'status': status,
    };

    final response = await _client.post(
      endpoint,
      body: payload,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final boardingResponse = CrewPassengerBoardingResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: boardingResponse,
          message: boardingResponse.message.isNotEmpty
              ? boardingResponse.message
              : 'Passenger status marked as ${status.toUpperCase()}',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse passenger boarding response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing boarding response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not update passenger boarding status.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Spot Booking / OnBoarding Booking for Conductor & Driver
  /// POST /crew/trips/{schedule_id}/spot-booking
  Future<ApiResponse<CrewSpotBookingResponse>> bookSpotTicket({
    required dynamic scheduleId,
    required dynamic scheduleSeatId,
    required String passengerName,
    required String passengerPhone,
    required String passengerGender,
    required int passengerAge,
    required String paymentMethod,
    required String boardingLocation,
    required String droppingLocation,
  }) async {
    String cleanScheduleId = scheduleId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanScheduleId);
    if (match != null) {
      cleanScheduleId = match.group(0)!;
    } else {
      cleanScheduleId = '19';
    }

    int seatIdInt = scheduleSeatId is int
        ? scheduleSeatId
        : (int.tryParse(scheduleSeatId.toString()) ?? 142);

    final endpoint = ApiConstants.crewTripSpotBookingEndpoint(cleanScheduleId);
    final payload = <String, dynamic>{
      'schedule_seat_id': seatIdInt,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'passenger_gender': passengerGender.toLowerCase(),
      'passenger_age': passengerAge,
      'payment_method': paymentMethod.toLowerCase(),
      'boarding_location': boardingLocation,
      'dropping_location': droppingLocation,
    };

    final response = await _client.post(
      endpoint,
      body: payload,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final bookingResponse = CrewSpotBookingResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: bookingResponse,
          message: bookingResponse.message.isNotEmpty
              ? bookingResponse.message
              : 'Spot Ticket Booked successfully.',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse spot booking response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing spot booking response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not book spot ticket.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Initiate online spot payment for onboarding passenger
  /// Endpoint: POST /crew/trip/{schedule_id}/spot-payment/initiate
  Future<ApiResponse<CrewSpotPaymentInitiateResponse>> initiateSpotPayment({
    required dynamic scheduleId,
    required dynamic scheduleSeatId,
    required String passengerName,
    required String passengerPhone,
    required String passengerGender,
    required int passengerAge,
    required String boardingLocation,
    required String droppingLocation,
    String gateway = 'razorpay',
  }) async {
    String cleanScheduleId = scheduleId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanScheduleId);
    if (match != null) {
      cleanScheduleId = match.group(0)!;
    } else {
      cleanScheduleId = '19';
    }

    int seatIdInt = scheduleSeatId is int
        ? scheduleSeatId
        : (int.tryParse(scheduleSeatId.toString()) ?? 653);

    final endpoint = ApiConstants.crewTripSpotPaymentInitiateEndpoint(cleanScheduleId);
    final payload = <String, dynamic>{
      'schedule_seat_id': seatIdInt,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'passenger_gender': passengerGender.toLowerCase(),
      'passenger_age': passengerAge,
      'boarding_location': boardingLocation,
      'dropping_location': droppingLocation,
      'gateway': gateway.toLowerCase(),
    };

    developer.log(
      'Initiating spot payment on $endpoint with payload: $payload',
      name: 'AuthApiService',
    );

    final response = await _client.post(
      endpoint,
      body: payload,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final paymentResponse = CrewSpotPaymentInitiateResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: paymentResponse,
          message: paymentResponse.message.isNotEmpty
              ? paymentResponse.message
              : 'Payment initiated successfully.',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse spot-payment initiate response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing online payment response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not initiate online payment.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Verify online spot payment for onboarding passenger
  /// Endpoint: POST /crew/trip/{schedule_id}/spot-payment/verify
  Future<ApiResponse<CrewSpotPaymentVerifyResponse>> verifySpotPayment({
    required dynamic scheduleId,
    required dynamic scheduleSeatId,
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
  }) async {
    String cleanScheduleId = scheduleId.toString();
    final match = RegExp(r'\d+').firstMatch(cleanScheduleId);
    if (match != null) {
      cleanScheduleId = match.group(0)!;
    } else {
      cleanScheduleId = '19';
    }

    int seatIdInt = scheduleSeatId is int
        ? scheduleSeatId
        : (int.tryParse(scheduleSeatId.toString()) ?? 653);

    final endpoint = ApiConstants.crewTripSpotPaymentVerifyEndpoint(cleanScheduleId);
    final payload = <String, dynamic>{
      'schedule_seat_id': seatIdInt,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'passenger_gender': passengerGender.toLowerCase(),
      'passenger_age': passengerAge,
      'boarding_location': boardingLocation,
      'dropping_location': droppingLocation,
      'gateway': gateway.toLowerCase(),
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };

    developer.log(
      'Verifying spot payment on $endpoint with payload: $payload',
      name: 'AuthApiService',
    );

    final response = await _client.post(
      endpoint,
      body: payload,
      attachAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      try {
        final verifyResponse = CrewSpotPaymentVerifyResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: verifyResponse,
          message: verifyResponse.message.isNotEmpty
              ? verifyResponse.message
              : 'Payment verified and ticket issued.',
          statusCode: response.statusCode,
          rawJson: response.rawJson,
        );
      } catch (e, stack) {
        developer.log('Failed to parse spot-payment verify response: $e', stackTrace: stack, name: 'AuthApiService');
        return ApiResponse.error(
          message: 'Error processing payment verification response.',
          statusCode: 500,
        );
      }
    } else {
      return ApiResponse.error(
        message: response.message.isNotEmpty
            ? response.message
            : 'Could not verify payment.',
        statusCode: response.statusCode,
        rawJson: response.rawJson,
      );
    }
  }

  /// Check if user is logged in
  Future<bool> isAuthenticated() async {
    return AuthStorage.isLoggedIn();
  }
}
