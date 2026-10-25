import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/models.dart';
import '../models/settings_models.dart';

class BackendNotConnected implements Exception {
  final String action;
  const BackendNotConnected(this.action);
  String get message => 'Not connected to a backend yet ($action).';
  @override
  String toString() => message;
}

/// A real error from Supabase. Extends BackendNotConnected only so the
/// existing `on BackendNotConnected catch` blocks in the screens show it.
class ApiError extends BackendNotConnected {
  final String text;
  const ApiError(this.text) : super('error');
  @override
  String get message => text;
}

class AuthResult {
  final String token;
  final bool isNewAccount;
  const AuthResult({required this.token, required this.isNewAccount});
}

class Api {
  static SupabaseClient get _sb => Supabase.instance.client;
  static Never _todo(String action) => throw BackendNotConnected(action);

  /// [phone] is E.164, e.g. +18765550123.
  static Future<void> sendOtp(String phone) async {
    try {
      await _sb.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e) {
      throw ApiError(e.message);
    }
  }

  static Future<AuthResult> verifyOtp(String phone, String code) async {
    try {
      final res = await _sb.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
      final session = res.session;
      final user = res.user;
      if (session == null || user == null) throw const ApiError('Could not verify that code.');
      return AuthResult(
        token: session.accessToken,
        // Set when the user finishes email + password in completeAccount below.
        isNewAccount: user.userMetadata?['account_complete'] != true,
      );
    } on AuthException catch (e) {
      throw ApiError(e.message);
    }
  }

  static Future<void> completeAccount({required String email, required String password}) async {
    try {
      await _sb.auth.updateUser(UserAttributes(
        email: email,
        password: password,
        data: {'account_complete': true},
      ));
    } on AuthException catch (e) {
      throw ApiError(e.message);
    }
  }

  static Future<void> sendTicket({required String orderId, required String toPhone}) async =>
      _todo('send ticket');
  static Future<void> listForResale({required String orderId, required int price}) async =>
      _todo('resell ticket');
  static Future<void> submitVerification(
          {required String accountType, String? website, required String proofFileName}) async =>
      _todo('submit verification');
  static Future<void> saveDraft() async => _todo('save draft');

  static Future<void> setFollow(String hostId, bool follow) async => _todo('follow');

  static Future<Highlight> createHighlight({required String title, Uint8List? cover}) async =>
      _todo('create highlight');

  /// True if no other account uses this handle (case-insensitive).
  static Future<bool> isHandleAvailable(String handle) async => _todo('check handle');

  /// Saves the profile and returns the saved version.
  static Future<UserProfile> updateProfile({
    required String name,
    required String handle,
    String? bio,
    String? website,
    Uint8List? avatar,
    Uint8List? banner,
  }) async =>
      _todo('update profile');

  // ----- settings -----
  static Future<AppSettings> loadSettings() async => _todo('load settings');
  static Future<void> saveSettings(AppSettings s) async => _todo('save settings');

  // ----- people -----
  static Future<List<PersonSummary>> searchPeople(String query) async => _todo('search people');
  static Future<void> setCloseFriend(String userId, bool close) async => _todo('close friends');
  static Future<void> setBlocked(String userId, bool blocked) async => _todo('unblock');

  // ----- saved / archive -----
  static Future<void> setSaved(String eventId, bool saved) async => _todo('save event');
  static Future<void> setArchived(String eventId, bool archived) async => _todo('archive event');

  // ----- payment cards -----
  /// Must send the card straight to your payment provider and return only safe display info.
  static Future<PaymentCard> addCard(CardInput input) async => _todo('add card');
  static Future<void> removeCard(String cardId) async => _todo('remove card');
  static Future<void> setDefaultCard(String cardId) async => _todo('default card');
}