import 'package:flutter/material.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/core/widgets/driver_app_bar.dart';
import 'package:bus_driver/driver/core/widgets/empty_state_widget.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';
import 'package:bus_driver/driver/presentation/screens/my_trips/widgets/trip_card.dart';
import 'package:bus_driver/driver/presentation/screens/trip_details/trip_details_screen.dart';
import 'package:bus_driver/driver/core/widgets/crew_drawer.dart';

/// My Trips Screen
///
/// Features:
/// - Tabbed view for Active Trips, Upcoming Trips, and Completed Trips
/// - Detailed trip card with route, departure time, bus, and status
/// - Responsive list with pull-to-refresh and empty states
/// - Navigation to Trip Details screen
class MyTripsScreen extends StatefulWidget {
  final ValueChanged<DriverTrip>? onSelectTrip;

  const MyTripsScreen({super.key, this.onSelectTrip});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  final DriverRepository _repository = DriverRepository();
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _repository.addListener(_onRepositoryUpdated);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _repository.fetchAssignedTrips(filter: 'today'),
      _repository.fetchAssignedTrips(filter: 'upcoming'),
      _repository.refreshDashboardFromApi(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _repository.removeListener(_onRepositoryUpdated);
    super.dispose();
  }

  void _onRepositoryUpdated() {
    if (mounted) setState(() {});
  }

  void _navigateToTripDetails(DriverTrip trip) {
    if (widget.onSelectTrip != null) {
      widget.onSelectTrip!(trip);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailsScreen(trip: trip),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayTrips = _repository.todayTrips;
    final upcomingTrips = _repository.upcomingTrips;
    final activeTrip = _repository.activeTrip;
    final completedTrips = _repository.completedTrips;

    // Active trips list (currently active trip if not completed)
    final activeTrips = activeTrip.status != TripStatus.completed ? [activeTrip] : <DriverTrip>[];

    return Scaffold(
      backgroundColor: DriverColors.background,
      drawer: const CrewDrawer(
        currentTabIndex: 1,
        isConductorView: false,
      ),
      appBar: DriverAppBar(
        automaticallyImplyLeading: false,
        title: 'My Trips',
        subtitle: 'Assigned Schedule & Trip History',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: DriverColors.textOnDarkMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Today (${todayTrips.length})'),
            Tab(text: 'Upcoming (${upcomingTrips.length})'),
            Tab(text: 'Active (${activeTrips.length})'),
            Tab(text: 'Completed (${completedTrips.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(DriverColors.primary),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Today's Trips Tab (?filter=today)
                _buildTripList(
                  trips: todayTrips,
                  filter: 'today',
                  emptyTitle: 'No Trips Today',
                  emptyMessage: 'You do not have any trips scheduled for today.',
                ),

                // 2. Upcoming Trips Tab (?filter=upcoming)
                _buildTripList(
                  trips: upcomingTrips,
                  filter: 'upcoming',
                  emptyTitle: 'No Upcoming Trips',
                  emptyMessage: 'No scheduled future trips found in your dispatch roster.',
                ),

                // 3. Active En Route Tab
                _buildTripList(
                  trips: activeTrips,
                  filter: 'active',
                  emptyTitle: 'No Active Trips',
                  emptyMessage: 'You do not have any trip currently en route or boarding.',
                ),

                // 4. Completed History Tab (?filter=completed)
                _buildTripList(
                  trips: completedTrips,
                  filter: 'completed',
                  emptyTitle: 'No Completed Trips',
                  emptyMessage: 'Your completed trip records will appear here.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList({
    required List<DriverTrip> trips,
    required String filter,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    Future<void> onRefresh() async {
      if (filter == 'today') {
        await _repository.fetchAssignedTrips(filter: 'today');
      } else if (filter == 'upcoming') {
        await _repository.fetchAssignedTrips(filter: 'upcoming');
      } else if (filter == 'completed') {
        await _repository.fetchAssignedTrips(filter: 'completed');
      } else {
        await _repository.refreshDashboardFromApi();
      }
      if (mounted) setState(() {});
    }

    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            alignment: Alignment.center,
            child: EmptyStateWidget(
              icon: Icons.alt_route_rounded,
              title: emptyTitle,
              message: emptyMessage,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripCard(
            trip: trip,
            onTap: () => _navigateToTripDetails(trip),
            quickActionLabel: trip.status == TripStatus.inProgress ? 'Live Trip →' : 'View Trip Details →',
          );
        },
      ),
    );
  }
}
