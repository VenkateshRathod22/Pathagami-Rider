import 'package:flutter/material.dart';

/// Driver side color palette matching TripRied design language
/// with high-contrast, professional driver cockpit accents.
class DriverColors {
  DriverColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color primaryDark = Color(0xFF0F172A); // Dark Slate Cockpit
  static const Color primaryLight = Color(0xFF3B82F6); // Vibrant Blue
  static const Color primaryGradientStart = Color(0xFF0F172A);
  static const Color primaryGradientEnd = Color(0xFF1E293B);

  // Accent Colors
  static const Color accent = Color(0xFF0284C7); // Sky Blue
  static const Color brandRed = Color(0xFFD83A3A); // TripRied Bus Red

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green (Online/Confirmed)
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B); // Amber (Boarding/Pending)
  static const Color warningDark = Color(0xFFD97706);
  static const Color error = Color(0xFFEF4444); // Red (Offline/Cancelled)
  static const Color info = Color(0xFF3B82F6); // Blue (Information)

  // Seat Status Colors
  static const Color seatAvailable = Color(0xFF10B981); // Green border/text
  static const Color seatBooked = Color(0xFF2563EB); // Royal Blue
  static const Color seatUnavailable = Color(0xFF94A3B8); // Muted Slate
  static const Color seatSelected = Color(0xFFF59E0B); // Amber highlight

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Very light slate
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color cardDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Near black
  static const Color textSecondary = Color(0xFF475569); // Slate gray
  static const Color textMuted = Color(0xFF94A3B8); // Light slate
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkMuted = Color(0xFFCBD5E1);

  // Border & Divider Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF334155);

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueAccentGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenSuccessGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
