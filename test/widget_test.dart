import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/trip_details/trip_details_screen.dart';
import 'package:bus_driver/driver/presentation/screens/my_trips/my_trips_screen.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/bus_seat_layout_screen.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/passenger_list_screen.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/spot_booking_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/widgets/passenger_details_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/bus_departed_sheet.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/widgets/station_halt_sheet.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';
import 'package:bus_driver/driver/presentation/screens/profile/driver_profile_screen.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/driver_dashboard_screen.dart';
import 'package:bus_driver/conductor/presentation/screens/dashboard/conductor_dashboard_screen.dart';
import 'package:bus_driver/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CrewLoginResponse parses sample JSON correctly and updates DriverRepository', () {
    final Map<String, dynamic> sampleJson = {
      "success": true,
      "message": "Logged in successfully. Welcome aboard!",
      "data": {
        "token": "52|lGZEhSFSHdzlBJk0bfG3PcehktSACwNs4ip6nzl098b82eac",
        "token_type": "Bearer",
        "role": "driver",
        "profile": {
          "id": 34,
          "name": "Reece Wiza-Robel",
          "email": "conductor@gmail.com",
          "phone": "6327114051",
          "role": "bus_driver",
          "status": "active",
          "profile_photo": null,
          "crew_details": {
            "id": 2,
            "crew_id": "DRV00001",
            "role": "driver",
            "role_label": "Bus Driver",
            "name": "Reece Wiza-Robel",
            "email": "conductor@gmail.com",
            "phone": "6327114051",
            "alternate_phone": null,
            "gender": "female",
            "blood_group": "A+",
            "dob": "2024-02-07",
            "license_number": "377",
            "license_expiry": "2027-01-16",
            "experience_years": 27,
            "address": "666 Helen Circle",
            "emergency_contact_name": null,
            "emergency_contact_phone": null,
            "status": "active"
          },
          "operator": {
            "id": 1,
            "operator_name": "lucknow branch",
            "contact_number": null,
            "email": "branch@gmail.com",
            "address": "asdfas asdfa"
          },
          "duty_summary": {
            "today_date": "2026-10-26",
            "total_trips_today": 1,
            "active_trip": {
              "schedule_id": 19,
              "status": "scheduled",
              "delay_minutes": 0,
              "departure_date": "2026-10-26",
              "departure_time": "22:00:00",
              "arrival_time": "05:30:00",
              "bus": {
                "id": 1,
                "bus_name": null,
                "registration_number": "UP-32-BT-9999",
                "bus_type": "AC Sleeper (2+1)",
                "total_seats": 30
              },
              "route": {
                "id": 1,
                "source_city": "Lucknow",
                "destination_city": "Delhi",
                "distance_km": 520,
                "duration_hours": null
              }
            }
          }
        }
      }
    };

    final response = CrewLoginResponse.fromJson(sampleJson);
    expect(response.success, isTrue);
    expect(response.message, 'Logged in successfully. Welcome aboard!');
    expect(response.data?.token, '52|lGZEhSFSHdzlBJk0bfG3PcehktSACwNs4ip6nzl098b82eac');
    expect(response.data?.role, 'driver');
    expect(response.data?.profile?.name, 'Reece Wiza-Robel');
    expect(response.data?.profile?.crewDetails?.crewId, 'DRV00001');

    final repo = DriverRepository();
    repo.updateFromCrewLogin(response);
    expect(repo.profile.name, 'Reece Wiza-Robel');
    expect(repo.profile.id, 'DRV00001');
    expect(repo.profile.depotName, 'lucknow branch');
    expect(repo.activeTrip.busNumber, 'UP-32-BT-9999');
    expect(repo.activeTrip.fromCity, 'Lucknow');
    expect(repo.activeTrip.toCity, 'Delhi');
  });

  test('CrewProfileResponse parses /crew/me JSON payload and updates all profile fields', () {
    final Map<String, dynamic> crewMeJson = {
      "success": true,
      "message": "Crew profile retrieved successfully.",
      "data": {
        "id": 34,
        "name": "Reece Wiza-Robel",
        "email": "conductor@gmail.com",
        "phone": "6327114051",
        "role": "bus_driver",
        "status": "active",
        "profile_photo": null,
        "crew_details": {
          "id": 2,
          "crew_id": "DRV00001",
          "role": "driver",
          "role_label": "Bus Driver",
          "name": "Reece Wiza-Robel",
          "email": "conductor@gmail.com",
          "phone": "6327114051",
          "alternate_phone": null,
          "gender": "female",
          "blood_group": "A+",
          "dob": "2024-02-07",
          "license_number": "377",
          "license_expiry": "2027-01-16",
          "experience_years": 27,
          "address": "666 Helen Circle",
          "emergency_contact_name": null,
          "emergency_contact_phone": null,
          "status": "active"
        },
        "operator": {
          "id": 1,
          "operator_name": "lucknow branch",
          "contact_number": null,
          "email": "branch@gmail.com",
          "address": "asdfas asdfa"
        },
        "duty_summary": {
          "today_date": "2026-10-26",
          "total_trips_today": 1,
          "active_trip": {
            "schedule_id": 19,
            "status": "scheduled",
            "delay_minutes": 0,
            "departure_date": "2026-10-26",
            "departure_time": "22:00:00",
            "arrival_time": "05:30:00",
            "bus": {
              "id": 1,
              "bus_name": null,
              "registration_number": "UP-32-BT-9999",
              "bus_type": "AC Sleeper (2+1)",
              "total_seats": 30
            },
            "route": {
              "id": 1,
              "source_city": "Lucknow",
              "destination_city": "Delhi",
              "distance_km": 520,
              "duration_hours": null
            }
          }
        }
      }
    };

    final profileResponse = CrewProfileResponse.fromJson(crewMeJson);
    expect(profileResponse.success, isTrue);
    expect(profileResponse.message, 'Crew profile retrieved successfully.');
    expect(profileResponse.data?.name, 'Reece Wiza-Robel');
    expect(profileResponse.data?.email, 'conductor@gmail.com');
    expect(profileResponse.data?.phone, '6327114051');
    expect(profileResponse.data?.crewDetails?.bloodGroup, 'A+');
    expect(profileResponse.data?.crewDetails?.licenseNumber, '377');
    expect(profileResponse.data?.crewDetails?.experienceYears, 27);
    expect(profileResponse.data?.crewDetails?.address, '666 Helen Circle');
    expect(profileResponse.data?.operator?.operatorName, 'lucknow branch');
    expect(profileResponse.data?.dutySummary?.activeTrip?.bus?.registrationNumber, 'UP-32-BT-9999');

    final repo = DriverRepository();
    repo.updateFromProfile(profileResponse.data!);
    expect(repo.profile.name, 'Reece Wiza-Robel');
    expect(repo.profile.licenseNumber, '377');
    expect(repo.profile.depotName, 'lucknow branch');
    expect(repo.crewProfile?.crewDetails?.bloodGroup, 'A+');
    expect(repo.crewProfile?.crewDetails?.address, '666 Helen Circle');
  });

  test('CrewDashboardResponse parses /crew/dashboard API JSON and updates DriverRepository', () {
    final Map<String, dynamic> dashboardJson = {
      "success": true,
      "message": "Crew dashboard retrieved successfully.",
      "data": {
        "crew": {
          "id": 2,
          "crew_id": "DRV00001",
          "name": "Reece Wiza-Robel",
          "role": "driver",
          "role_label": "Bus Driver",
          "status": "active"
        },
        "metrics": {
          "today_date": "2026-10-27",
          "total_today": 1,
          "in_transit_today": 1,
          "completed_today": 0,
          "scheduled_today": 0
        },
        "active_trip": {
          "id": 21,
          "status": "in_transit",
          "delay_minutes": 0,
          "operational_notes": "Departed from main depot on time",
          "departure_date": "2026-10-27",
          "departure_time": "22:00:00",
          "arrival_date": "2026-10-28",
          "arrival_time": "05:30:00",
          "route": {
            "id": 1,
            "source_city": "Lucknow",
            "destination_city": "Delhi",
            "distance_km": 520,
            "duration_hours": null
          },
          "bus": {
            "id": 1,
            "bus_name": null,
            "registration_number": "UP-32-BT-9999",
            "bus_type": "AC Sleeper (2+1)",
            "total_seats": 30
          },
          "operator": {
            "id": 1,
            "operator_name": "lucknow branch",
            "contact_number": null
          },
          "seating": {
            "total_seats": 30,
            "booked_seats": 0,
            "available_seats": 30
          },
          "driver": {
            "id": 2,
            "name": "Reece Wiza-Robel",
            "phone": "6327114051"
          },
          "conductor": {
            "id": 1,
            "name": "Khalil Swaniawski",
            "phone": "7527425651"
          }
        },
        "today_trips": [
          {
            "id": 21,
            "status": "in_transit",
            "delay_minutes": 0,
            "operational_notes": "Departed from main depot on time",
            "departure_date": "2026-10-27",
            "departure_time": "22:00:00",
            "arrival_date": "2026-10-28",
            "arrival_time": "05:30:00",
            "route": {
              "id": 1,
              "source_city": "Lucknow",
              "destination_city": "Delhi",
              "distance_km": 520,
              "duration_hours": null
            },
            "bus": {
              "id": 1,
              "bus_name": null,
              "registration_number": "UP-32-BT-9999",
              "bus_type": "AC Sleeper (2+1)",
              "total_seats": 30
            },
            "operator": {
              "id": 1,
              "operator_name": "lucknow branch",
              "contact_number": null
            },
            "seating": {
              "total_seats": 30,
              "booked_seats": 0,
              "available_seats": 30
            },
            "driver": {
              "id": 2,
              "name": "Reece Wiza-Robel",
              "phone": "6327114051"
            },
            "conductor": {
              "id": 1,
              "name": "Khalil Swaniawski",
              "phone": "7527425651"
            }
          }
        ],
        "upcoming_trips": [
          {
            "id": 23,
            "status": "scheduled",
            "delay_minutes": 0,
            "operational_notes": null,
            "departure_date": "2026-10-28",
            "departure_time": "22:00:00",
            "arrival_date": "2026-10-29",
            "arrival_time": "05:30:00",
            "route": {
              "id": 1,
              "source_city": "Lucknow",
              "destination_city": "Delhi",
              "distance_km": 520,
              "duration_hours": null
            },
            "bus": {
              "id": 1,
              "bus_name": null,
              "registration_number": "UP-32-BT-9999",
              "bus_type": "AC Sleeper (2+1)",
              "total_seats": 30
            },
            "operator": {
              "id": 1,
              "operator_name": "lucknow branch",
              "contact_number": null
            },
            "seating": {
              "total_seats": 30,
              "booked_seats": 1,
              "available_seats": 29
            },
            "driver": {
              "id": 2,
              "name": "Reece Wiza-Robel",
              "phone": "6327114051"
            },
            "conductor": {
              "id": 1,
              "name": "Khalil Swaniawski",
              "phone": "7527425651"
            }
          }
        ]
      }
    };

    final dashboardResponse = CrewDashboardResponse.fromJson(dashboardJson);
    expect(dashboardResponse.success, isTrue);
    expect(dashboardResponse.message, 'Crew dashboard retrieved successfully.');
    expect(dashboardResponse.data?.crew?.name, 'Reece Wiza-Robel');
    expect(dashboardResponse.data?.crew?.crewId, 'DRV00001');
    expect(dashboardResponse.data?.metrics?.todayDate, '2026-10-27');
    expect(dashboardResponse.data?.metrics?.totalToday, 1);
    expect(dashboardResponse.data?.metrics?.inTransitToday, 1);
    expect(dashboardResponse.data?.activeTrip?.id, 21);
    expect(dashboardResponse.data?.activeTrip?.status, 'in_transit');
    expect(dashboardResponse.data?.activeTrip?.operationalNotes, 'Departed from main depot on time');
    expect(dashboardResponse.data?.activeTrip?.driver?.name, 'Reece Wiza-Robel');
    expect(dashboardResponse.data?.activeTrip?.conductor?.name, 'Khalil Swaniawski');
    expect(dashboardResponse.data?.activeTrip?.conductor?.phone, '7527425651');
    expect(dashboardResponse.data?.activeTrip?.seating?.totalSeats, 30);
    expect(dashboardResponse.data?.activeTrip?.seating?.availableSeats, 30);
    expect(dashboardResponse.data?.upcomingTrips.length, 1);
    expect(dashboardResponse.data?.upcomingTrips.first.id, 23);

    final repo = DriverRepository();
    repo.updateFromDashboard(dashboardResponse.data!);
    expect(repo.profile.name, 'Reece Wiza-Robel');
    expect(repo.profile.id, 'DRV00001');
    expect(repo.profile.badgeType, 'Bus Driver');
    expect(repo.profile.assignedBusNumber, 'UP-32-BT-9999');
    expect(repo.profile.depotName, 'lucknow branch');
    expect(repo.activeTrip.busNumber, 'UP-32-BT-9999');
    expect(repo.activeTrip.fromCity, 'Lucknow');
    expect(repo.activeTrip.toCity, 'Delhi');
    expect(repo.activeTrip.distance, '520 km');
    expect(repo.totalSeats, 30);
    expect(repo.bookedSeats, 0);
    expect(repo.availableSeats, 30);
    expect(repo.dashboardData?.activeTrip?.operationalNotes, 'Departed from main depot on time');
  });

  testWidgets('Driver & Conductor Portal login screen UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Driver & Conductor Portal'), findsOneWidget);
    expect(find.text('Login to Portal'), findsOneWidget);
  });

  testWidgets('Driver Main Navigation displays Dashboard tab name', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Passengers'), findsOneWidget);
    expect(find.text('My Bus'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  test('CrewTripDetailsResponse parses /crew/trips/19 JSON payload and updates DriverRepository', () {
    final Map<String, dynamic> tripDetailsJson = {
      "success": true,
      "message": "Trip details retrieved successfully.",
      "data": {
        "schedule": {
          "id": 19,
          "status": "scheduled",
          "delay_minutes": 0,
          "operational_notes": null,
          "departure_date": "2026-10-26",
          "departure_time": "22:00:00",
          "arrival_date": "2026-10-27",
          "arrival_time": "05:30:00",
          "base_fare": 950
        },
        "bus": {
          "id": 1,
          "bus_name": null,
          "registration_number": "UP-32-BT-9999",
          "bus_type": "AC Sleeper (2+1)",
          "total_seats": 30
        },
        "route": {
          "id": 1,
          "source_city": "Lucknow",
          "destination_city": "Delhi",
          "distance_km": 520,
          "duration_hours": null
        },
        "operator": {
          "id": 1,
          "operator_name": "lucknow branch",
          "contact_number": null,
          "email": "branch@gmail.com"
        },
        "driver": {
          "id": 2,
          "crew_id": "DRV00001",
          "name": "Reece Wiza-Robel",
          "phone": "6327114051"
        },
        "conductor": {
          "id": 1,
          "crew_id": "CND00001",
          "name": "Khalil Swaniawski",
          "phone": "7527425651"
        },
        "seating_summary": {
          "total_seats": 30,
          "booked_seats_count": 0,
          "vacant_seats_count": 30,
          "boarded_count": 0,
          "pending_boarding_count": 0,
          "no_show_count": 0
        },
        "manifest": null
      }
    };

    final tripResponse = CrewTripDetailsResponse.fromJson(tripDetailsJson);
    expect(tripResponse.success, isTrue);
    expect(tripResponse.message, 'Trip details retrieved successfully.');

    final data = tripResponse.data;
    expect(data, isNotNull);
    expect(data!.schedule?.id, 19);
    expect(data.schedule?.status, 'scheduled');
    expect(data.schedule?.baseFare, 950);
    expect(data.schedule?.departureDate, '2026-10-26');
    expect(data.schedule?.departureTime, '22:00:00');
    expect(data.schedule?.arrivalDate, '2026-10-27');
    expect(data.schedule?.arrivalTime, '05:30:00');

    expect(data.bus?.registrationNumber, 'UP-32-BT-9999');
    expect(data.bus?.busType, 'AC Sleeper (2+1)');
    expect(data.bus?.totalSeats, 30);

    expect(data.route?.sourceCity, 'Lucknow');
    expect(data.route?.destinationCity, 'Delhi');
    expect(data.route?.distanceKm, 520);

    expect(data.operator?.operatorName, 'lucknow branch');
    expect(data.operator?.email, 'branch@gmail.com');

    expect(data.driver?.id, 2);
    expect(data.driver?.crewId, 'DRV00001');
    expect(data.driver?.name, 'Reece Wiza-Robel');
    expect(data.driver?.phone, '6327114051');

    expect(data.conductor?.id, 1);
    expect(data.conductor?.crewId, 'CND00001');
    expect(data.conductor?.name, 'Khalil Swaniawski');
    expect(data.conductor?.phone, '7527425651');

    expect(data.seatingSummary?.totalSeats, 30);
    expect(data.seatingSummary?.bookedSeatsCount, 0);
    expect(data.seatingSummary?.vacantSeatsCount, 30);
    expect(data.seatingSummary?.boardedCount, 0);
    expect(data.seatingSummary?.pendingBoardingCount, 0);
    expect(data.seatingSummary?.noShowCount, 0);
    expect(data.manifest, isNull);

    final repo = DriverRepository();
    repo.updateFromTripDetails(data);
    expect(repo.profile.name, 'Reece Wiza-Robel');
    expect(repo.profile.id, 'DRV00001');
    expect(repo.profile.phone, '6327114051');
    expect(repo.profile.assignedBusNumber, 'UP-32-BT-9999');
    expect(repo.profile.depotName, 'lucknow branch');
    expect(repo.selectedTripDetails?.schedule?.id, 19);
    expect(repo.selectedTripDetails?.schedule?.baseFare, 950);
    expect(repo.selectedTripDetails?.driver?.name, 'Reece Wiza-Robel');
    expect(repo.selectedTripDetails?.conductor?.name, 'Khalil Swaniawski');
  });

  testWidgets('TripDetailsScreen renders all trip, driver, conductor, and seating elements', (WidgetTester tester) async {
    final repo = DriverRepository();
    final sampleTrip = repo.activeTrip;

    await tester.pumpWidget(
      MaterialApp(
        home: TripDetailsScreen(trip: sampleTrip),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Trip Details'), findsOneWidget);
    expect(find.text('Assigned Bus Driver'), findsOneWidget);
    expect(find.text('Assigned Bus Conductor'), findsOneWidget);
    expect(find.text('Seating & Boarding Summary'), findsOneWidget);
    expect(find.text('Assigned Bus Information'), findsOneWidget);
    expect(find.text('Branch & Operator Particulars'), findsOneWidget);
    expect(find.text('Passenger Manifest'), findsOneWidget);
    expect(find.text('Bus Seat Layout'), findsOneWidget);
  });

  test('CrewAssignedTripsResponse parses /crew/trips?filter=today JSON and updates todayTrips in DriverRepository', () {
    final Map<String, dynamic> todayTripsJson = {
      "success": true,
      "message": "Assigned trips retrieved successfully.",
      "data": {
        "trips": [
          {
            "id": 19,
            "status": "scheduled",
            "delay_minutes": 0,
            "operational_notes": null,
            "departure_date": "2026-10-26",
            "departure_time": "22:00:00",
            "arrival_date": "2026-10-27",
            "arrival_time": "05:30:00",
            "route": {
              "id": 1,
              "source_city": "Lucknow",
              "destination_city": "Delhi",
              "distance_km": 520,
              "duration_hours": null
            },
            "bus": {
              "id": 1,
              "bus_name": null,
              "registration_number": "UP-32-BT-9999",
              "bus_type": "AC Sleeper (2+1)",
              "total_seats": 30
            },
            "operator": {
              "id": 1,
              "operator_name": "lucknow branch",
              "contact_number": null
            },
            "seating": {
              "total_seats": 30,
              "booked_seats": 0,
              "available_seats": 30
            },
            "driver": {
              "id": 2,
              "name": "Reece Wiza-Robel",
              "phone": "6327114051"
            },
            "conductor": {
              "id": 1,
              "name": "Khalil Swaniawski",
              "phone": "7527425651"
            }
          }
        ],
        "pagination": {
          "current_page": 1,
          "last_page": 1,
          "per_page": 15,
          "total": 1
        }
      }
    };

    final response = CrewAssignedTripsResponse.fromJson(todayTripsJson);
    expect(response.success, isTrue);
    expect(response.message, 'Assigned trips retrieved successfully.');
    expect(response.data?.trips.length, 1);

    final tripItem = response.data!.trips.first;
    expect(tripItem.id, 19);
    expect(tripItem.status, 'scheduled');
    expect(tripItem.route?.sourceCity, 'Lucknow');
    expect(tripItem.route?.destinationCity, 'Delhi');
    expect(tripItem.bus?.registrationNumber, 'UP-32-BT-9999');
    expect(tripItem.seating?.totalSeats, 30);
    expect(tripItem.seating?.bookedSeats, 0);
    expect(tripItem.seating?.availableSeats, 30);
    expect(tripItem.driver?.name, 'Reece Wiza-Robel');
    expect(tripItem.conductor?.name, 'Khalil Swaniawski');
    expect(response.data?.pagination?.currentPage, 1);
    expect(response.data?.pagination?.total, 1);

    final repo = DriverRepository();
    repo.updateFromAssignedTrips(response.data!, filter: 'today');
    expect(repo.todayTrips.isNotEmpty, isTrue);
    expect(repo.todayTrips.first.busNumber, 'UP-32-BT-9999');
    expect(repo.todayTrips.first.fromCity, 'Lucknow');
    expect(repo.todayTrips.first.toCity, 'Delhi');
    expect(repo.todayTrips.first.driverName, 'Reece Wiza-Robel');
    expect(repo.todayTrips.first.conductorName, 'Khalil Swaniawski');
    expect(repo.todayTrips.first.operatorName, 'lucknow branch');
  });

  test('CrewAssignedTripsResponse parses /crew/trips?filter=upcoming JSON and updates upcomingTrips in DriverRepository', () {
    final Map<String, dynamic> upcomingTripsJson = {
      "success": true,
      "message": "Assigned trips retrieved successfully.",
      "data": {
        "trips": [
          {
            "id": 23,
            "status": "scheduled",
            "delay_minutes": 0,
            "operational_notes": null,
            "departure_date": "2026-10-28",
            "departure_time": "22:00:00",
            "arrival_date": "2026-10-29",
            "arrival_time": "05:30:00",
            "route": {
              "id": 1,
              "source_city": "Lucknow",
              "destination_city": "Delhi",
              "distance_km": 520,
              "duration_hours": null
            },
            "bus": {
              "id": 1,
              "bus_name": null,
              "registration_number": "UP-32-BT-9999",
              "bus_type": "AC Sleeper (2+1)",
              "total_seats": 30
            },
            "operator": {
              "id": 1,
              "operator_name": "lucknow branch",
              "contact_number": null
            },
            "seating": {
              "total_seats": 30,
              "booked_seats": 1,
              "available_seats": 29
            },
            "driver": {
              "id": 2,
              "name": "Reece Wiza-Robel",
              "phone": "6327114051"
            },
            "conductor": {
              "id": 1,
              "name": "Khalil Swaniawski",
              "phone": "7527425651"
            }
          }
        ],
        "pagination": {
          "current_page": 1,
          "last_page": 1,
          "per_page": 15,
          "total": 1
        }
      }
    };

    final response = CrewAssignedTripsResponse.fromJson(upcomingTripsJson);
    expect(response.success, isTrue);
    expect(response.data?.trips.length, 1);

    final tripItem = response.data!.trips.first;
    expect(tripItem.id, 23);
    expect(tripItem.departureDate, '2026-10-28');
    expect(tripItem.seating?.bookedSeats, 1);
    expect(tripItem.seating?.availableSeats, 29);

    final repo = DriverRepository();
    repo.updateFromAssignedTrips(response.data!, filter: 'upcoming');
    expect(repo.upcomingTrips.isNotEmpty, isTrue);
    expect(repo.upcomingTrips.first.id, 'TR-23');
    expect(repo.upcomingTrips.first.bookedSeats, 1);
    expect(repo.upcomingTrips.first.driverName, 'Reece Wiza-Robel');
  });

  testWidgets('MyTripsScreen renders 4 tabs (Today, Upcoming, Active, Completed) and trip list', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MyTripsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Trips'), findsOneWidget);
    expect(find.textContaining('Today ('), findsOneWidget);
    expect(find.textContaining('Upcoming ('), findsOneWidget);
    expect(find.textContaining('Active ('), findsOneWidget);
    expect(find.textContaining('Completed ('), findsOneWidget);
  });

  test('CrewTripStatusResponse parses status update JSON and updates DriverRepository trip state', () {
    final Map<String, dynamic> statusJson = {
      "success": true,
      "message": "Bus marked as DEPARTED & On Road!",
      "data": {
        "schedule_id": 19,
        "status": "in_transit",
        "delay_minutes": 0,
        "operational_notes": "Departed from main depot on time",
        "updated_at": "2026-10-27T07:12:26+00:00"
      }
    };

    final response = CrewTripStatusResponse.fromJson(statusJson);
    expect(response.success, isTrue);
    expect(response.message, 'Bus marked as DEPARTED & On Road!');
    expect(response.data, isNotNull);
    expect(response.data?.scheduleId, 19);
    expect(response.data?.status, 'in_transit');
    expect(response.data?.delayMinutes, 0);
    expect(response.data?.operationalNotes, 'Departed from main depot on time');
    expect(response.data?.updatedAt, '2026-10-27T07:12:26+00:00');

    final repo = DriverRepository();
    repo.updateFromTripStatus(response.data!);

    expect(repo.activeTrip.status, TripStatus.inProgress);
    expect(repo.activeTrip.operationalNotes, 'Departed from main depot on time');
    expect(repo.activeTrip.delayMinutes, 0);
  });

  test('CrewVacantSeatsResponse parses /crew/trips/19/vacant-seats JSON correctly and populates DriverRepository', () {
    final Map<String, dynamic> vacantJson = {
      "success": true,
      "message": "Vacant seats retrieved successfully.",
      "data": {
        "schedule_id": 19,
        "total_vacant_seats": 30,
        "vacant_seats": [
          {
            "id": 451,
            "seat_number": "L1A",
            "deck": "lower",
            "seat_type": "sleeper",
            "fare": 1000
          },
          {
            "id": 452,
            "seat_number": "L1B",
            "deck": "lower",
            "seat_type": "sleeper",
            "fare": 950
          },
          {
            "id": 453,
            "seat_number": "L1C",
            "deck": "lower",
            "seat_type": "sleeper",
            "fare": 1000
          },
          {
            "id": 466,
            "seat_number": "U1A",
            "deck": "upper",
            "seat_type": "sleeper",
            "fare": 980
          }
        ]
      }
    };

    final response = CrewVacantSeatsResponse.fromJson(vacantJson);
    expect(response.success, isTrue);
    expect(response.message, 'Vacant seats retrieved successfully.');
    expect(response.data, isNotNull);
    expect(response.data?.scheduleId, 19);
    expect(response.data?.totalVacantSeats, 30);
    expect(response.data?.vacantSeats.length, 4);

    final l1a = response.data?.findBySeatNumber('L1A');
    expect(l1a, isNotNull);
    expect(l1a?.id, 451);
    expect(l1a?.deck, 'lower');
    expect(l1a?.seatType, 'sleeper');
    expect(l1a?.fare, 1000);

    final u1a = response.data?.findBySeatNumber('U1A');
    expect(u1a, isNotNull);
    expect(u1a?.id, 466);
    expect(u1a?.isUpperDeck, isTrue);
    expect(u1a?.fare, 980);

    final repo = DriverRepository();
    repo.updateFromVacantSeats(response.data!);
    expect(repo.vacantSeatsData?.scheduleId, 19);

    final lowerSeats = repo.getSeatsForDeck(isUpperDeck: false);
    final seatL1A = lowerSeats.firstWhere((s) => s.seatNumber == 'L1A');
    expect(seatL1A.seatId, 451);
    expect(seatL1A.fare, 1000);
    expect(seatL1A.seatType, 'sleeper');
    expect(seatL1A.deckName, 'lower');
  });

  testWidgets('BusSeatLayoutScreen renders live vacant berths banner and opens SeatInspectorSheet on seat tap', (WidgetTester tester) async {
    final repo = DriverRepository();
    repo.updateFromVacantSeats(
      CrewVacantSeatsData(
        scheduleId: 19,
        totalVacantSeats: 30,
        vacantSeats: [
          const VacantSeatItem(id: 451, seatNumber: 'L1A', deck: 'lower', seatType: 'sleeper', fare: 1000),
          const VacantSeatItem(id: 452, seatNumber: 'L1B', deck: 'lower', seatType: 'sleeper', fare: 950),
          const VacantSeatItem(id: 453, seatNumber: 'L1C', deck: 'lower', seatType: 'sleeper', fare: 1000),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: BusSeatLayoutScreen(
          busNumber: 'UP-32-BT-9999',
          busType: 'AC Sleeper (2+1)',
          tripId: 19,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bus Seat Layout'), findsOneWidget);
    expect(find.textContaining('30 Vacant Berths'), findsOneWidget);
    expect(find.text('LIVE API'), findsOneWidget);
    expect(find.text('Lower Deck (15 Berths)'), findsOneWidget);
    expect(find.text('Upper Deck (15 Berths)'), findsOneWidget);
    expect(find.text('L1A'), findsOneWidget);

    // Tap seat L1A to inspect
    await tester.tap(find.text('L1A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Inspector BottomSheet opened with complete details
    expect(find.text('Berth L1A'), findsOneWidget);
    expect(find.text('#451'), findsOneWidget);
    expect(find.text('Live Fare'), findsOneWidget);
    expect(find.text('₹1000'), findsAtLeastNWidgets(1));
    expect(find.text('VACANT & AVAILABLE'), findsOneWidget);
    expect(find.text('Close Inspector'), findsOneWidget);
  });

  test('CrewPassengerBoardingResponse parses sample boarding confirmation JSON and updates DriverRepository', () {
    final Map<String, dynamic> boardingJson = {
      "success": true,
      "message": "Passenger 'Rahul Verma' marked as BOARDED",
      "data": {
        "passenger_id": 45,
        "passenger_name": "Rahul Verma",
        "seat_number": "U-12",
        "boarding_status": "boarded",
        "boarded_at": "10:15 PM"
      }
    };

    final response = CrewPassengerBoardingResponse.fromJson(boardingJson);
    expect(response.success, isTrue);
    expect(response.message, "Passenger 'Rahul Verma' marked as BOARDED");
    expect(response.data, isNotNull);
    expect(response.data?.passengerId, 45);
    expect(response.data?.passengerName, 'Rahul Verma');
    expect(response.data?.seatNumber, 'U-12');
    expect(response.data?.boardingStatus, 'boarded');
    expect(response.data?.boardedAt, '10:15 PM');
    expect(response.data?.isBoarded, isTrue);
    expect(response.data?.isNoShow, isFalse);
    expect(response.data?.isPending, isFalse);

    final repo = DriverRepository();
    repo.updateFromPassengerBoarding(response.data!);

    final rahul = repo.activeTrip.passengers.firstWhere((p) => p.passengerName == 'Rahul Verma');
    expect(rahul.isBoarded, isTrue);
    expect(rahul.boardingStatus, 'boarded');
    expect(rahul.boardedAt, '10:15 PM');
  });

  testWidgets('PassengerListScreen renders Conductor Boarding Desk and displays passenger card details', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PassengerListScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Passenger Manifest'), findsOneWidget);
    expect(find.textContaining('Conductor Desk'), findsOneWidget);
    expect(find.textContaining('Pending'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Boarded'), findsAtLeastNWidgets(1));
    expect(find.text('Rahul Verma'), findsOneWidget);
    expect(find.text('U-12'), findsOneWidget);
    expect(find.text('ID: #45'), findsOneWidget);
  });

  testWidgets('PassengerListScreen renders top banner, dispatch actions, and switches to Seating Layout Coach Map', (WidgetTester tester) async {
    final repo = DriverRepository();
    repo.updateFromVacantSeats(
      CrewVacantSeatsData(
        scheduleId: 19,
        totalVacantSeats: 30,
        vacantSeats: [
          const VacantSeatItem(id: 451, seatNumber: 'L1A', deck: 'lower', seatType: 'sleeper', fare: 1000),
          const VacantSeatItem(id: 452, seatNumber: 'L1B', deck: 'lower', seatType: 'sleeper', fare: 950),
          const VacantSeatItem(id: 453, seatNumber: 'L1C', deck: 'lower', seatType: 'sleeper', fare: 1000),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PassengerListScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify Top Green Banner & Dispatch Actions
    expect(find.text('DEPARTURE TIME'), findsOneWidget);
    expect(find.text('ESTIMATED ARRIVAL'), findsOneWidget);
    expect(find.text('PASSENGER LOAD'), findsOneWidget);
    expect(find.text('BUS DEPARTED'), findsOneWidget);
    expect(find.text('STATION HALT'), findsOneWidget);
    expect(find.text('REPORT DELAY'), findsOneWidget);
    expect(find.text('TRIP COMPLETE'), findsOneWidget);

    // 2. Verify Dual Master Tabs (Tab 1: Boarding Manifest, Tab 2: Bus Seating Layout)
    expect(find.text('Boarding Manifest'), findsOneWidget);
    expect(find.text('Bus Seating Layout'), findsOneWidget);

    // 3. Switch to Tab 2 (Bus Seating Layout)
    await tester.tap(find.text('Bus Seating Layout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verify Coach Map elements from web panel screenshot
    expect(find.text('Live Bus Seating Layout (Coach Map)'), findsOneWidget);
    expect(find.text('Spot Booking'), findsOneWidget);
    expect(find.text('Lower Deck Coach (15 Seats)'), findsOneWidget);
    expect(find.text('Upper Deck Coach (15 Berths)'), findsOneWidget);
    expect(find.text('-> ENTRY / DOOR'), findsOneWidget);
    expect(find.text('Front / Driver Cabin'), findsOneWidget);
    expect(find.text('L1A'), findsOneWidget);

    // 5. Tap vacant seat L1A and inspect live details (#451, ₹1000, VACANT & AVAILABLE)
    await tester.tap(find.text('L1A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Berth L1A'), findsOneWidget);
    expect(find.text('#451'), findsOneWidget);
    expect(find.text('VACANT & AVAILABLE'), findsOneWidget);
    expect(find.text('Close Inspector'), findsOneWidget);
  });

  test('CrewSpotBookingResponse parses spot booking API response and updates DriverRepository', () {
    final Map<String, dynamic> sampleSpotBookingJson = {
      "success": true,
      "message": "Spot Ticket Booked! PNR: TRP261026X9Y2 - Seat U-05 issued for Manoj Kumar.",
      "data": {
        "booking_id": 89,
        "pnr": "TRP261026X9Y2",
        "seat_number": "U-05",
        "passenger_name": "Manoj Kumar",
        "fare": 750.00,
        "payment_method": "cash",
        "payment_status": "paid",
        "boarding_status": "boarded"
      }
    };

    final response = CrewSpotBookingResponse.fromJson(sampleSpotBookingJson);
    expect(response.success, isTrue);
    expect(response.message, contains('Spot Ticket Booked!'));
    expect(response.data?.bookingId, 89);
    expect(response.data?.pnr, 'TRP261026X9Y2');
    expect(response.data?.seatNumber, 'U-05');
    expect(response.data?.passengerName, 'Manoj Kumar');
    expect(response.data?.fare, 750.00);
    expect(response.data?.paymentMethod, 'cash');
    expect(response.data?.paymentStatus, 'paid');
    expect(response.data?.boardingStatus, 'boarded');
    expect(response.data?.isBoarded, isTrue);
    expect(response.data?.isPaid, isTrue);

    final repo = DriverRepository();
    final initialPassengerCount = repo.activeTrip.passengers.length;

    repo.updateFromSpotBooking(
      response.data!,
      scheduleSeatId: 142,
      boardingLocation: 'Kanpur Bypass',
      droppingLocation: 'Delhi Anand Vihar',
      age: 32,
      gender: 'male',
      phone: '9812345678',
    );

    expect(repo.activeTrip.passengers.length, initialPassengerCount + 1);
    final bookedPassenger = repo.activeTrip.passengers.firstWhere((p) => p.pnr == 'TRP261026X9Y2');
    expect(bookedPassenger.passengerName, 'Manoj Kumar');
    expect(bookedPassenger.seatNumber, 'U-05');
    expect(bookedPassenger.isBoarded, isTrue);
    expect(bookedPassenger.boardingStatus, 'boarded');
    expect(bookedPassenger.pickupLocation, 'Kanpur Bypass');
    expect(bookedPassenger.dropLocation, 'Delhi Anand Vihar');
    expect(bookedPassenger.fare, 750.00);
    expect(bookedPassenger.age, 32);
    expect(bookedPassenger.gender, 'Male');
    expect(bookedPassenger.paymentStatus, 'Paid (CASH)');
  });

  testWidgets('SpotBookingSheet UI renders form fields and confirms on-boarding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpotBookingSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OnBoarding / Spot Booking'), findsOneWidget);
    expect(find.text('Conductor & Driver Live Spot Ticketing'), findsOneWidget);
    expect(find.text('Passenger Full Name *'), findsOneWidget);
    expect(find.text('Phone Number *'), findsOneWidget);
    expect(find.text('Kanpur Bypass'), findsOneWidget);
    expect(find.text('Delhi Anand Vihar'), findsOneWidget);
    expect(find.text('CASH'), findsOneWidget);
    expect(find.text('Confirm Spot Booking & Board Berth'), findsOneWidget);
  });

  testWidgets('PassengerDetailsSheet UI displays complete ticket, PNR, route, and fare info', (WidgetTester tester) async {
    const passenger = PassengerBooking(
      passengerId: 89,
      pnr: 'TRP261026X9Y2',
      bookingId: 'BK-89',
      passengerName: 'Manoj Kumar',
      phone: '9812345678',
      age: 32,
      gender: 'Male',
      seatNumber: 'U-05',
      isUpperDeck: true,
      pickupLocation: 'Kanpur Bypass',
      dropLocation: 'Delhi Anand Vihar',
      pickupTime: '10:00 PM',
      dropTime: '05:30 AM',
      status: 'Boarded',
      fare: 750.00,
      isBoarded: true,
      boardingStatus: 'boarded',
      boardedAt: '10:15 PM',
      paymentStatus: 'Paid (Cash)',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PassengerDetailsSheet(passenger: passenger),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('seat U-05'), findsOneWidget);
    expect(find.text('Manoj Kumar'), findsOneWidget);
    expect(find.text('PNR: TRP261026X9Y2'), findsOneWidget);
    expect(find.text('Booking ID: #89'), findsOneWidget);
    expect(find.text('Kanpur Bypass'), findsOneWidget);
    expect(find.text('Delhi Anand Vihar'), findsOneWidget);
    expect(find.text('₹750.00'), findsOneWidget);
    expect(find.text('PAID (CASH)'), findsOneWidget);
    expect(find.text('9812345678'), findsOneWidget);
  });

  testWidgets('StationHaltSheet UI displays all route stations, halt reasons, and duration', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StationHaltSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Station Halt / Intermediate Stop'), findsOneWidget);
    expect(find.text('5 Route Stops'), findsOneWidget);
    expect(find.text('Alambagh Bus Terminal'), findsOneWidget);
    expect(find.text('Kanpur Bypass (Rama Devi)'), findsOneWidget);
    expect(find.text('Agra-Lucknow Expressway Toll'), findsOneWidget);
    expect(find.text('Akshardham Metro Station'), findsOneWidget);
    expect(find.text('Kashmere Gate ISBT'), findsOneWidget);
    expect(find.text('Reason for Station Halt'), findsOneWidget);
    expect(find.text('Passenger Boarding'), findsOneWidget);
    expect(find.text('Refreshment / Break'), findsOneWidget);
  });

  testWidgets('BusDepartedSheet UI displays departure stations, bus reg, timings, and notes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BusDepartedSheet(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bus Departed & On Road'), findsOneWidget);
    expect(find.text('Select Departure Station'), findsOneWidget);
    expect(find.text('Alambagh Bus Terminal'), findsOneWidget);
    expect(find.text('ORIGIN DEPOT'), findsOneWidget);
    expect(find.text('Kanpur Bypass (Rama Devi)'), findsOneWidget);
    expect(find.text('Operational Notes (API Broadcast)'), findsOneWidget);
  });

  testWidgets('CrewDrawer renders Tripride branding, crew member identity, role items, and logout', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: CrewDrawer(currentTabIndex: 0, isConductorView: false),
          body: Center(child: Text('Testing Drawer')),
        ),
      ),
    );

    // Open Drawer via scaffold state
    final scaffoldFinder = find.byType(Scaffold);
    final scaffoldState = tester.firstState<ScaffoldState>(scaffoldFinder);
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tripride'), findsOneWidget);
    expect(find.text('CREW OPERATIONS PORTAL'), findsOneWidget);
    expect(find.text('Driver Dashboard'), findsOneWidget);
    expect(find.text('Conductor Dashboard'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Passengers'), findsOneWidget);
    expect(find.text('My Bus'), findsOneWidget);
    expect(find.text('Crew Profile'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('Crew Profile screen renders Duty & Active Schedule, Assigned Bus Roster, and Crew Pairing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Crew Profile'), findsOneWidget);
    expect(find.text('Duty & Active Schedule'), findsOneWidget);
    expect(find.text('Today Date'), findsOneWidget);
    expect(find.text('Schedule ID'), findsOneWidget);
    expect(find.text('Assigned Bus Roster'), findsOneWidget);
    expect(find.text('Registration Number'), findsOneWidget);
    expect(find.text('Depot Fleet SOS'), findsOneWidget);
    expect(find.text('Assigned Crew Pairing'), findsOneWidget);
    expect(find.text('Assigned Driver'), findsOneWidget);
  });

  testWidgets('Driver Dashboard renders full Screenshot 1 cockpit UI', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('ON DUTY'), findsOneWidget);
    expect(find.text('DRIVER'), findsAtLeastNWidgets(1));
    expect(find.text('CONDUCTOR'), findsAtLeastNWidgets(1));
    expect(find.text('DEPARTURE'), findsOneWidget);
    expect(find.text('EST. ARRIVAL'), findsOneWidget);
    expect(find.text('BUS DEPARTED'), findsOneWidget);
    expect(find.text('STATION HALT'), findsOneWidget);
    expect(find.text('REPORT DELAY'), findsOneWidget);
    expect(find.text('TRIP COMPLETE'), findsOneWidget);
    expect(find.text("Today's Operations"), findsOneWidget);
    expect(find.text('Total Today'), findsOneWidget);
    expect(find.text('In Transit'), findsOneWidget);
  });

  testWidgets('Conductor Dashboard renders conductor cockpit UI', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConductorDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('CONDUCTOR PORTAL'), findsOneWidget);
    expect(find.text('ON DUTY'), findsOneWidget);
    expect(find.text('On-Spot Ticket Issue'), findsOneWidget);
    expect(find.text('BUS DEPARTED'), findsOneWidget);
    expect(find.text('STATION HALT'), findsOneWidget);
    expect(find.text('Passenger Manifest & Boarding'), findsOneWidget);
  });

  testWidgets('CrewDrawer.open opens the sidebar from any screen or page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => CrewDrawer.open(ctx),
                child: const Text('Open Sidebar Now'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap button to call sidebar
    await tester.tap(find.text('Open Sidebar Now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify sidebar data is visible
    expect(find.text('Tripride'), findsOneWidget);
    expect(find.text('CREW OPERATIONS PORTAL'), findsOneWidget);
    expect(find.text('Driver Dashboard'), findsOneWidget);
    expect(find.text('Conductor Dashboard'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Passengers'), findsOneWidget);
    expect(find.text('My Bus'), findsOneWidget);
    expect(find.text('Crew Profile'), findsOneWidget);
  });
}



