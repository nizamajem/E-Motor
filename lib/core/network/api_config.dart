import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// Base URL to hit backend services.
  /// Override at build time with --dart-define API_BASE_URL=https://your-api
  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!dotenv.isInitialized) {
      return 'https://reflowapp.ptms3.com/api';
    }
    final fromDotenv = dotenv.env['API_BASE_URL'];
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;
    return 'https://reflowapp.ptms3.com/api';
  }

  /// eMotor ID bound to the logged-in user. Set via --dart-define=EMOTOR_ID=...
  static const String emotorId = String.fromEnvironment(
    'EMOTOR_ID',
    defaultValue: '',
  );

  /// Login session lifetime in seconds, sent as "detik".
  /// Set to 0 to omit and let backend use its default (e.g., unlimited).
  static const int loginSessionSeconds = int.fromEnvironment(
    'LOGIN_SESSION_SECONDS',
    defaultValue: 0,
  );

  /// Paths grouped here to keep usage consistent across the app.
  static const String loginPath = '/auth/login-emotor';
  static const String refreshMobilePath = '/auth/refresh-mobile';
  static const String logoutPath = '/auth/logout';
  static const String emotorListPath = '/emotors';
  static const String emotorByIdPath = '/emotors/get-by-id';
  static const String refreshDashboardPath = '/emotors/refresh-dashboard';
  static const String additionalInfoPath = '/emotors/get-additional-info';
  static const String startRentalPath = '/emotors/rides/start';
  static const String endRentalPath = '/emotors/rides/end';
  static const String forceEndRentalPath = '/emotor/rides/force-end';
  static const String accCommandPath = '/emotors/command/acc';
  static const String findCommandPath = '/emotors/command/find';
  static const String historyByIdPath = '/user-cycling-history/get-by-id';
  static const String historyByUserPath =
      '/user-cycling-history/all-e-motors/by-user';
  static const String historyByMembershipPath =
      '/user-cycling-history/membershipHistory';
  static const String membershipHistoryByCustomerPath =
      '/membership-history/findByCustomer';
  static const String feedbacksPath = '/feedbacks';
  static const String membershipsForEmotorPath = '/membership/for-emotor';
  static const String payRideWalletPath = '/customer-payments/pay-ride';
  static const String payRideMidtransPath =
      '/customer-payments/pay-ride-midtrans';
  static const String buyMembershipPath = '/membership/buy-emotor';
  static const String checkMembershipPath = '/customers/check-membership';
  static const String topupSnapPath = '/customer-topups/snap';
  static const String userByIdPath = '/users';

  /// Midtrans SDK configuration (set via --dart-define).
  static String get midtransClientKey {
    const fromEnv = String.fromEnvironment(
      'MIDTRANS_CLIENT_KEY',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!dotenv.isInitialized) return '';
    return dotenv.env['MIDTRANS_CLIENT_KEY'] ?? '';
  }

  static String get midtransMerchantBaseUrl {
    const fromEnv = String.fromEnvironment(
      'MIDTRANS_MERCHANT_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (!dotenv.isInitialized) return baseUrl;
    return dotenv.env['MIDTRANS_MERCHANT_BASE_URL'] ?? baseUrl;
  }
}
