import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bus_driver/api/models/crew_login_response.dart';

/// Storage helper to persist Crew Session, Token, and Profile in SharedPreferences
class AuthStorage {
  static const String _keyToken = 'auth_token';
  static const String _keyTokenType = 'auth_token_type';
  static const String _keyRole = 'crew_role';
  static const String _keyCrewId = 'crew_badge_id';
  static const String _keyCrewName = 'crew_name';
  static const String _keyProfileJson = 'crew_profile_json';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Save authenticated session data
  static Future<void> saveSession(CrewLoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final data = loginResponse.data;
    if (data == null) return;

    await prefs.setString(_keyToken, data.token);
    await prefs.setString(_keyTokenType, data.tokenType);
    await prefs.setString(_keyRole, data.role);
    await prefs.setBool(_keyIsLoggedIn, true);

    if (data.profile != null) {
      final profile = data.profile!;
      await prefs.setString(_keyCrewName, profile.name);
      if (profile.crewDetails != null) {
        await prefs.setString(_keyCrewId, profile.crewDetails!.crewId);
      }
      await prefs.setString(_keyProfileJson, jsonEncode(loginResponse.toJson()));
    }
  }

  /// Retrieve bearer token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Retrieve crew role ('driver', 'conductor')
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  /// Persist active crew role ('driver', 'conductor')
  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role.toLowerCase());
  }

  /// Retrieve crew badge ID (e.g. 'DRV00001', 'CND00001')
  static Future<String?> getCrewId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCrewId);
  }

  /// Retrieve crew member's name
  static Future<String?> getCrewName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCrewName);
  }

  /// Check if session is currently active
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString(_keyToken)?.isNotEmpty ?? false;
    final loggedInFlag = prefs.getBool(_keyIsLoggedIn) ?? false;
    return hasToken && loggedInFlag;
  }

  /// Retrieve cached full profile response
  static Future<CrewLoginResponse?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyProfileJson);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return CrewLoginResponse.fromJson(decoded);
      }
    } catch (_) {
      // Corrupt cache
    }
    return null;
  }

  /// Update cached crew profile data when retrieved from /crew/me
  static Future<void> updateCachedProfile(CrewProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCrewName, profile.name);
    if (profile.crewDetails != null) {
      await prefs.setString(_keyCrewId, profile.crewDetails!.crewId);
      await prefs.setString(_keyRole, profile.crewDetails!.role);
    }

    final saved = await getSavedSession();
    if (saved != null && saved.data != null) {
      final updatedData = CrewData(
        token: saved.data!.token,
        tokenType: saved.data!.tokenType,
        role: profile.crewDetails?.role ?? saved.data!.role,
        profile: profile,
      );
      final updatedResponse = CrewLoginResponse(
        success: true,
        message: 'Profile updated',
        data: updatedData,
      );
      await prefs.setString(_keyProfileJson, jsonEncode(updatedResponse.toJson()));
    }
  }

  /// Clear all saved session data on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTokenType);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyCrewId);
    await prefs.remove(_keyCrewName);
    await prefs.remove(_keyProfileJson);
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
