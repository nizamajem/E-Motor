class ApiConfig {
  /// Base URL to hit backend services.
  /// Override at build time with --dart-define API_BASE_URL=https://your-api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://reflowapp.ptms3.com/api',
  );

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
  static const String startRentalPath = '/emotors/rides/start';
  static const String endRentalPath = '/emotors/rides/end';
  static const String forceEndRentalPath = '/emotor/rides/force-end';
  static const String accCommandPath = '/emotors/command/acc';
  static const String findCommandPath = '/emotors/command/find';
  static const String historyByIdPath = '/user-cycling-history/get-by-id';
  static const String historyByUserPath =
      '/user-cycling-history/all-e-motors/by-user';
  static const String feedbacksPath = '/feedbacks';
}
