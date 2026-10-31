import 'package:flutter/material.dart';
import 'package:bus_driver/conductor/presentation/screens/dashboard/conductor_dashboard_screen.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/bus_seat_layout_screen.dart';
import 'package:bus_driver/driver/presentation/screens/my_trips/my_trips_screen.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/passenger_list_screen.dart';
import 'package:bus_driver/driver/presentation/screens/profile/driver_profile_screen.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';
import 'package:bus_driver/driver/presentation/screens/trip_details/trip_details_screen.dart';

/// Conductor Main Navigation Shell
///
/// Implements bottom navigation for Bus Conductors:
/// 1. Conductor Dashboard (Shift Overview & Quick Ticketing)
/// 2. Assigned Trips (Trips Roster & Schedules)
/// 3. Passengers (Boarding Manifest & Check-in)
/// 4. Bus Layout (Seat Inspection & Vacant Seats)
/// 5. Crew Profile (Conductor Info & Operator Details)
class ConductorMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const ConductorMainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ConductorMainNavigationScreen> createState() => _ConductorMainNavigationScreenState();
}

class _ConductorMainNavigationScreenState extends State<ConductorMainNavigationScreen> {
  late int _currentIndex;

  static const Color conductorAccent = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToTripDetails(DriverTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ConductorDashboardScreen(
        onNavigateTab: _onTabSelected,
        onOpenTripDetails: _navigateToTripDetails,
      ),
      MyTripsScreen(
        onSelectTrip: _navigateToTripDetails,
      ),
      const PassengerListScreen(),
      const BusSeatLayoutScreen(),
      const DriverProfileScreen(),
    ];

    return Scaffold(
      drawer: CrewDrawer(
        currentTabIndex: _currentIndex,
        onSelectTab: _onTabSelected,
        isConductorView: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: DriverColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: conductorAccent,
          unselectedItemColor: DriverColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_outlined),
              activeIcon: Icon(Icons.alt_route_rounded),
              label: 'Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Passengers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.airline_seat_recline_extra_outlined),
              activeIcon: Icon(Icons.airline_seat_recline_extra_rounded),
              label: 'Seating',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
