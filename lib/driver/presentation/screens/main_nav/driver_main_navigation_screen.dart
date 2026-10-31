import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/presentation/screens/bus_layout/bus_seat_layout_screen.dart';
import 'package:bus_driver/driver/presentation/screens/dashboard/driver_dashboard_screen.dart';
import 'package:bus_driver/driver/presentation/screens/my_trips/my_trips_screen.dart';
import 'package:bus_driver/driver/presentation/screens/passengers/passenger_list_screen.dart';
import 'package:bus_driver/driver/presentation/screens/profile/driver_profile_screen.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';
import 'package:bus_driver/driver/presentation/screens/trip_details/trip_details_screen.dart';

/// Driver Main Navigation Shell
///
/// Implements bottom navigation for:
/// 1. Home (Driver Dashboard)
/// 2. My Trips (Active, Upcoming, Completed)
/// 3. Passengers (Manifest & Check-in)
/// 4. My Bus (Interactive Seat Layout)
/// 5. Profile (Driver Info & Fleet Details)
class DriverMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const DriverMainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DriverMainNavigationScreen> createState() => _DriverMainNavigationScreenState();
}

class _DriverMainNavigationScreenState extends State<DriverMainNavigationScreen> {
  late int _currentIndex;

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
      DriverDashboardScreen(
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
        isConductorView: false,
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
          selectedItemColor: DriverColors.primary,
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
              label: 'My Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Passengers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.airline_seat_recline_extra_outlined),
              activeIcon: Icon(Icons.airline_seat_recline_extra_rounded),
              label: 'My Bus',
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
