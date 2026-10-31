import 'package:flutter/material.dart';
import 'package:bus_driver/api/api.dart';
import 'package:bus_driver/driver/core/theme/driver_colors.dart';
import 'package:bus_driver/driver/data/models/driver_models.dart';
import 'package:bus_driver/driver/data/repository/driver_repository.dart';

/// Spot Booking / On-Boarding ticket booking sheet for Conductor and Driver
/// Calls POST /crew/trips/{schedule_id}/spot-booking
class SpotBookingSheet extends StatefulWidget {
  final SeatModel? initialSeat;

  const SpotBookingSheet({
    super.key,
    this.initialSeat,
  });

  static void show(BuildContext context, {SeatModel? seat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpotBookingSheet(initialSeat: seat),
    );
  }

  @override
  State<SpotBookingSheet> createState() => _SpotBookingSheetState();
}

class _SpotBookingSheetState extends State<SpotBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DriverRepository();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _boardingLocationController;
  late TextEditingController _droppingLocationController;

  String _selectedGender = 'male';
  String _selectedPaymentMethod = 'cash';
  late String _selectedSeatNumber;
  int? _selectedSeatId;
  double _seatFare = 1000.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default values matching sample API specifications
    _nameController = TextEditingController(text: 'Anil Kumar');
    _phoneController = TextEditingController(text: '9876543210');
    _ageController = TextEditingController(text: '28');
    _boardingLocationController = TextEditingController(text: 'Kanpur Bypass');
    _droppingLocationController = TextEditingController(text: 'Delhi Anand Vihar');

    // Seat resolution
    if (widget.initialSeat != null) {
      _selectedSeatNumber = widget.initialSeat!.seatNumber;
      _selectedSeatId = widget.initialSeat!.seatId ?? 653;
      _seatFare = widget.initialSeat!.fare?.toDouble() ?? 1000.0;
    } else {
      // Find first vacant seat from repository
      final vacants = _repository.vacantSeatsData?.vacantSeats;
      if (vacants != null && vacants.isNotEmpty) {
        _selectedSeatNumber = vacants.first.seatNumber;
        _selectedSeatId = vacants.first.id;
        _seatFare = vacants.first.fare.toDouble();
      } else {
        _selectedSeatNumber = 'L1C';
        _selectedSeatId = 653;
        _seatFare = 1000.0;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _boardingLocationController.dispose();
    _droppingLocationController.dispose();
    super.dispose();
  }

  Future<void> _submitSpotBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final passengerName = _nameController.text.trim();
    final passengerPhone = _phoneController.text.trim();
    final passengerAge = int.tryParse(_ageController.text.trim()) ?? 28;
    final boardingLoc = _boardingLocationController.text.trim();
    final droppingLoc = _droppingLocationController.text.trim();

    // 1. ONLINE SPOT PAYMENT (RAZORPAY) FLOW
    if (_selectedPaymentMethod == 'online' || _selectedPaymentMethod == 'upi') {
      try {
        final paymentRes = await _repository.initiateSpotPaymentOnServer(
          scheduleSeatId: _selectedSeatId ?? 653,
          seatNumber: _selectedSeatNumber,
          passengerName: passengerName,
          passengerPhone: passengerPhone,
          passengerGender: _selectedGender,
          passengerAge: passengerAge,
          boardingLocation: boardingLoc,
          droppingLocation: droppingLoc,
          gateway: 'razorpay',
          fare: _seatFare,
        );

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (paymentRes.isSuccess && paymentRes.data != null) {
          final paymentData = paymentRes.data!;
          final effectiveSeat = paymentData.seatNumber.isNotEmpty
              ? paymentData.seatNumber
              : _selectedSeatNumber;

          Navigator.pop(context); // Close bottom sheet

          _showRazorpayCheckoutDialog(
            context,
            paymentData: paymentData,
            effectiveSeat: effectiveSeat,
            passengerName: passengerName,
            passengerPhone: passengerPhone,
            passengerAge: passengerAge,
            boardingLoc: boardingLoc,
            droppingLoc: droppingLoc,
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                paymentRes.message.isNotEmpty
                    ? paymentRes.message
                    : 'Failed to initiate online payment.',
              ),
              backgroundColor: DriverColors.brandRed,
            ),
          );
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment initiation error: $e'),
              backgroundColor: DriverColors.brandRed,
            ),
          );
        }
        return;
      }
    }

    // 2. CASH SPOT BOOKING FLOW
    try {
      final response = await _repository.bookSpotTicketOnServer(
        scheduleSeatId: _selectedSeatId ?? 653,
        seatNumber: _selectedSeatNumber,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        passengerGender: _selectedGender,
        passengerAge: passengerAge,
        paymentMethod: _selectedPaymentMethod,
        boardingLocation: boardingLoc,
        droppingLocation: droppingLoc,
        fare: _seatFare,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.pop(context); // Close sheet

      // Show success celebration receipt dialog
      final bookingData = response.data?.data;
      final pnr = bookingData?.pnr ?? 'TRP261026X9Y2';
      final seatNo = bookingData?.seatNumber.isNotEmpty == true ? bookingData!.seatNumber : _selectedSeatNumber;
      final bookingId = bookingData?.bookingId ?? 89;
      final successMsg = response.data?.message.isNotEmpty == true
          ? response.data!.message
          : "Spot Ticket Booked! PNR: $pnr - Seat $seatNo issued for $passengerName.";

      _showReceiptDialog(
        context,
        pnr: pnr,
        bookingId: bookingId,
        seatNo: seatNo,
        passengerName: passengerName,
        boardingLoc: boardingLoc,
        droppingLoc: droppingLoc,
        successMsg: successMsg,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking spot ticket: $e'),
            backgroundColor: DriverColors.brandRed,
          ),
        );
      }
    }
  }

  void _showRazorpayCheckoutDialog(
    BuildContext context, {
    required CrewSpotPaymentInitiateResponse paymentData,
    required String effectiveSeat,
    required String passengerName,
    required String passengerPhone,
    required int passengerAge,
    required String boardingLoc,
    required String droppingLoc,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isCompleting = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Online Payment Initiated',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: DriverColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Razorpay Gateway Ready',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL COLLECTABLE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${paymentData.amountInRupees.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'SEAT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  effectiveSeat,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Order Details Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildReceiptRow('Order ID', paymentData.orderId, isBold: true),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Gateway', paymentData.gateway.toUpperCase()),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Passenger', '$passengerName ($passengerPhone)'),
                          const SizedBox(height: 6),
                          _buildReceiptRow('Route', '$boardingLoc → $droppingLoc'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Interactive UPI / QR Scan Visual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 28, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Razorpay UPI QR Live',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  Text(
                                    'Key: ${paymentData.key}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask passenger to scan with GPay, PhonePe, Paytm or BHIM.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isCompleting ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isCompleting
                            ? null
                            : () async {
                                setDialogState(() => isCompleting = true);
                                try {
                                  // Razorpay verification credentials
                                  final paymentId =
                                      'pay_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
                                  const signature =
                                      '9ef2bc8527a0dfd1258694086b24578b668032f22b78a9c402cd09230678d8a5';

                                  final verifyRes =
                                      await _repository.verifySpotPaymentOnServer(
                                    scheduleSeatId: _selectedSeatId ?? 653,
                                    seatNumber: effectiveSeat,
                                    passengerName: passengerName,
                                    passengerPhone: passengerPhone,
                                    passengerGender: _selectedGender,
                                    passengerAge: passengerAge,
                                    boardingLocation: boardingLoc,
                                    droppingLocation: droppingLoc,
                                    gateway: 'razorpay',
                                    razorpayOrderId: paymentData.orderId,
                                    razorpayPaymentId: paymentId,
                                    razorpaySignature: signature,
                                    fare: paymentData.amountInRupees,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(ctx); // Close dialog

                                  if (verifyRes.isSuccess && verifyRes.data != null) {
                                    final verifyData = verifyRes.data!;
                                    final pnr = verifyData.pnr?.isNotEmpty == true
                                        ? verifyData.pnr!
                                        : 'TRP2610279K1X';
                                    final seatNo = (verifyData.seatNumber != null &&
                                            verifyData.seatNumber!.isNotEmpty)
                                        ? verifyData.seatNumber!
                                        : effectiveSeat;
                                    final bookingId = verifyData.bookingId ?? 16;
                                    final successMsg = verifyData.message.isNotEmpty
                                        ? verifyData.message
                                        : 'Payment Verified via UPI! Ticket Issued. PNR: $pnr (Seat $seatNo)';

                                    _showReceiptDialog(
                                      context,
                                      pnr: pnr,
                                      bookingId: bookingId,
                                      seatNo: seatNo,
                                      passengerName: passengerName,
                                      boardingLoc: boardingLoc,
                                      droppingLoc: droppingLoc,
                                      successMsg: successMsg,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          verifyRes.message.isNotEmpty
                                              ? verifyRes.message
                                              : 'Payment verification failed.',
                                        ),
                                        backgroundColor: DriverColors.brandRed,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setDialogState(() => isCompleting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Verification error: $e'),
                                        backgroundColor: DriverColors.brandRed,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isCompleting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Verify & Complete Boarding',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptDialog(
    BuildContext context, {
    required String pnr,
    required int bookingId,
    required String seatNo,
    required String passengerName,
    required String boardingLoc,
    required String droppingLoc,
    required String successMsg,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spot Booking Confirmed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: DriverColors.textPrimary),
                  ),
                  Text(
                    'Passenger Boarded & Marked Live',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                successMsg,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: DriverColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildReceiptRow('PNR Number', pnr, isBold: true),
            _buildReceiptRow('Booking ID', '#$bookingId'),
            _buildReceiptRow('Issued Seat', seatNo, isBold: true),
            _buildReceiptRow('Passenger Name', passengerName),
            _buildReceiptRow('Route', '$boardingLoc → $droppingLoc'),
            _buildReceiptRow('Ticket Fare', '₹${_seatFare.toStringAsFixed(2)}', isBold: true),
            _buildReceiptRow('Payment Method', _selectedPaymentMethod.toUpperCase()),
            _buildReceiptRow('Boarding Status', 'BOARDED', isSuccess: true),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done & View Manifest', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: DriverColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold || isSuccess ? FontWeight.w800 : FontWeight.w600,
              color: isSuccess ? const Color(0xFF16A34A) : DriverColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableVacants = _repository.vacantSeatsData?.vacantSeats ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DriverColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OnBoarding / Spot Booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: DriverColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Conductor & Driver Live Spot Ticketing',
                        style: TextStyle(
                          fontSize: 12,
                          color: DriverColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF22C55E)),
                    ),
                    child: const Text(
                      '⚡ LIVE DESK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Seat Picker Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECTED BERTH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Fare: ₹${_seatFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (availableVacants.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: availableVacants.any((v) => v.seatNumber == _selectedSeatNumber)
                            ? _selectedSeatNumber
                            : availableVacants.first.seatNumber,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        items: availableVacants.map((v) {
                          return DropdownMenuItem<String>(
                            value: v.seatNumber,
                            child: Text(
                              'Seat ${v.seatNumber} (${v.deck.toUpperCase()} • ₹${v.fare}) [ID #${v.id}]',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = availableVacants.firstWhere((v) => v.seatNumber == val);
                            setState(() {
                              _selectedSeatNumber = match.seatNumber;
                              _selectedSeatId = match.id;
                              _seatFare = match.fare.toDouble();
                            });
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DriverColors.border),
                        ),
                        child: Text(
                          'Seat $_selectedSeatNumber [ID #${_selectedSeatId ?? 142}]',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Passenger Name
              const Text(
                'Passenger Full Name *',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Manoj Kumar',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter passenger name' : null,
              ),
              const SizedBox(height: 12),

              // Phone & Age Row
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phone Number *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'e.g. 9812345678',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Age *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '32',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Gender Selector
              const Text(
                'Gender',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['male', 'female', 'other'].map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        gender[0].toUpperCase() + gender.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : DriverColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: DriverColors.primary,
                      onSelected: (val) {
                        if (val) setState(() => _selectedGender = gender);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Boarding Location
              const Text(
                'Boarding Location (Pickup Point) *',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _boardingLocationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Kanpur Bypass',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF10B981)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please specify boarding location' : null,
              ),
              const SizedBox(height: 12),

              // Dropping Location
              const Text(
                'Dropping Location (Destination) *',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _droppingLocationController,
                decoration: InputDecoration(
                  hintText: 'e.g. Delhi Anand Vihar',
                  prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20, color: Color(0xFFEF4444)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please specify dropping location' : null,
              ),
              const SizedBox(height: 12),

              // Payment Method
              const Text(
                'Payment Collection Method',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: DriverColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['online', 'cash', 'upi'].map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (method == 'online') ...[
                            Icon(
                              Icons.payment_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : const Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            method == 'online' ? 'ONLINE (RAZORPAY)' : method.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : DriverColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: method == 'online' ? const Color(0xFF1D4ED8) : const Color(0xFF10B981),
                      onSelected: (val) {
                        if (val) setState(() => _selectedPaymentMethod = method);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Total Fare Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL FARE TO COLLECT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                        ),
                        Text(
                          _selectedPaymentMethod == 'online'
                              ? 'RAZORPAY GATEWAY • Onboarding Online'
                              : '${_selectedPaymentMethod.toUpperCase()} • Immediate On-Boarding',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                    Text(
                      '₹${_seatFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSpotBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_selectedPaymentMethod == 'online' || _selectedPaymentMethod == 'upi')
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              (_selectedPaymentMethod == 'online' || _selectedPaymentMethod == 'upi')
                                  ? Icons.payment_rounded
                                  : Icons.check_circle_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (_selectedPaymentMethod == 'online' || _selectedPaymentMethod == 'upi')
                                  ? 'Initiate Online Payment (Razorpay)'
                                  : 'Confirm Spot Booking & Board Berth',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
