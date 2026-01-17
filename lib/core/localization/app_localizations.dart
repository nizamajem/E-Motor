import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('id')];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    return localizations ?? AppLocalizations(const Locale('en'));
  }

  static AppLocalizations current = AppLocalizations(const Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get _lang => locale.languageCode.toLowerCase();

  String _t(String key) {
    final map = _strings[_lang] ?? _strings['en']!;
    return map[key] ?? _strings['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'welcome_back': 'Welcome back!',
      'login_subtitle': 'Sign in to continue your ride with Gridwiz E-Motor.',
      'username': 'Username',
      'username_hint': 'Enter your username',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'no_account': "Don't have account? ",
      'contact_admin': 'Contact Admin',
      'login_required': 'Username and password are required',
      'welcome': 'Welcome ',
      'tagline': 'A seamless electric mobility powered by real-time technology',
      'locked': 'Locked',
      'battery': 'Battery',
      'status_on': 'ON',
      'status_off': 'OFF',
      'carbon_emission': 'Carbon Emission',
      'ping': 'Ping',
      'rental_time': 'Rental Time',
      'on': 'On',
      'off': 'Off',
      'slide_to_lock': 'Slide to Lock',
      'slide_to_unlock': 'Slide to Unlock',
      'end_rental': 'End Rental',
      'ending': 'Ending...',
      'live': 'Live',
      'turn_off_before_end': 'Please turn off the e-motor before end rental.',
      'turn_off_before_end_title': 'Turn off e-motor first',
      'turn_off_before_end_body':
          'Please switch off the e-motor before ending the rental.',
      'checking_emotor_title': 'Checking e-motor status',
      'checking_emotor_body': 'Wait, we are still checking the e-motor status.',
      'ok': 'OK',
      'end_rental_failed': 'End rental failed: ',
      'start_ride_failed': 'Start ride failed: ',
      'acc_failed': 'ACC command failed.',
      'send_failed': 'Failed to send command: ',
      'find_emotor': 'Find',
      'find_emotor_success': 'Find command sent.',
      'find_emotor_failed': 'Find command failed.',
      'find_emotor_title': 'Find me',
      'find_emotor_body':
          'Your e-motor is pinging now. Follow the sound or indicator to locate it.',
      'find_emotor_cta': 'Got it',
      'start_ride_title': 'Start Ride?',
      'start_ride_body': 'Start a ride to use the dashboard.',
      'start_ride_button': 'Start Ride',
      'my_history': 'My History',
      'stats_mileage': 'Mileage',
      'stats_active_days': 'Active Days',
      'days': 'Days',
      'stats_reduced_emission': 'Reduced Emission',
      'history_load_failed': 'Failed to load history.',
      'history_empty': 'No trip history yet.',
      'no_ride_id': 'No ride history yet. Start rental first.',
      'detail_trip': 'Trip Details',
      'distance': 'Distance',
      'rental_duration': 'Rental Duration',
      'emission_reduction': 'Emission Reduction',
      'start': 'Start',
      'date': 'Date',
      'start_time': 'Start Time',
      'start_position': 'Start Position',
      'end': 'End',
      'end_time': 'End Time',
      'end_position': 'End Position',
      'ride_cost': 'Ride Cost',
      'idle_cost': 'Idle Cost',
      'total_cost': 'Total Cost',
      'feedback': 'Feedback',
      'give_feedback': 'Give Feedback',
      'feedback_hint': 'Help us improve your ride experience.',
      'feedback_input': 'Write your feedback',
      'feedback_success_title': 'Thanks for the feedback!',
      'feedback_success_body':
          'Your feedback is in. It helps us make every ride better.',
      'feedback_success_cta': 'Got it',
      'cancel': 'Cancel',
      'send': 'Send',
      'done': 'Done',
      'my_profile': 'My Profile',
      'display_name': 'Display Name',
      'name': 'Name',
      'email': 'E-Mail',
      'phone': 'Phone Number',
      'gender': 'Gender',
      'birthday': 'Birthday',
      'id_card': 'ID Card Number',
      'height': 'Height',
      'weight': 'Weight',
      'logout': 'Log Out',
      'logout_confirm': 'Are you sure want to log out?',
      'no': 'No',
      'yes': 'Yes',
      'skip': 'Skip',
      'get_started': 'Get Started',
      'next': 'Next',
      'onboard_title_1': 'Welcome Gridwiz E-Motor',
      'onboard_subtitle_1':
          'A seamless electric mobility powered by real-time technology.',
      'onboard_title_2': 'Smart & Connected',
      'onboard_subtitle_2':
          'Monitor speed, battery level, and vehicle status in real time.',
      'onboard_title_3': 'Unlock, Ride, Go',
      'onboard_subtitle_3':
          'Unlock your e-motor easily and begin your ride instantly, just tap, ride, and go.',
      'duration_hour': 'hr',
      'duration_minute': 'min',
      'turn_off_confirm_title': 'Turn off e-motor?',
      'turn_off_confirm_body':
          'Make sure the vehicle has stopped before turning it off.',
      'turn_off': 'Turn Off',
      'loading_connecting_vehicle': 'Connecting to vehicle...',
      'loading_sending_command': 'Sending command to vehicle...',
      'loading_finding_vehicle': 'Finding vehicle...',
      'loading_processing': 'Processing...',
      'error_no_internet': 'No internet connection. Please check your network.',
      'no_internet_description':
          'Check your network.\nThe app will automatically resume when connection is available.',
      'error_send_command_failed':
          'Failed to send command to vehicle. Please try again.',
      'error_vehicle_not_responding':
          'Connection is slow. The vehicle is not responding.',
      'error_network_generic': 'Network error occurred. Please try again.',
      'error_history_not_found': 'Trip details not found.',
      'end_rental_confirm_title': 'End Rental?',
      'end_rental_confirm_body':
          'Make sure the vehicle is turned off and parked properly before ending the rental.',
      'end_rental_confirm_yes': 'End Rental',
      'end_rental_confirm_no': 'Cancel',
      'loading_ending_rental': 'Ending rental...',
    },
    'id': {
      'welcome_back': 'Selamat datang!',
      'login_subtitle':
          'Masuk untuk melanjutkan perjalanan Anda dengan Gridwiz E-Motor.',
      'username': 'Username',
      'username_hint': 'Masukkan username',
      'password': 'Kata Sandi',
      'password_hint': 'Masukkan kata sandi',
      'forgot_password': 'Lupa Kata Sandi?',
      'sign_in': 'Masuk',
      'no_account': 'Belum punya akun? ',
      'contact_admin': 'Hubungi Admin',
      'login_required': 'Username dan password harus diisi',
      'welcome': 'Selamat datang ',
      'tagline': 'Mobilitas listrik yang mulus dengan teknologi real-time',
      'locked': 'Terkunci',
      'battery': 'Baterai',
      'status_on': 'ON',
      'status_off': 'OFF',
      'carbon_emission': 'Emisi Karbon',
      'ping': 'Ping',
      'rental_time': 'Waktu Rental',
      'on': 'On',
      'off': 'Off',
      'slide_to_lock': 'Geser untuk Lock',
      'slide_to_unlock': 'Geser untuk Unlock',
      'end_rental': 'Selesai Rental',
      'ending': 'Mengakhiri...',
      'live': 'Live',
      'turn_off_before_end':
          'Matikan e-motor terlebih dahulu sebelum end rental.',
      'turn_off_before_end_title': 'Matikan e-motor dulu',
      'turn_off_before_end_body':
          'Mohon matikan e-motor sebelum mengakhiri rental.',
      'checking_emotor_title': 'Cek status e-motor',
      'checking_emotor_body': 'Tunggu, kami masih cek status e-motor.',
      'ok': 'OK',
      'end_rental_failed': 'End rental gagal: ',
      'start_ride_failed': 'Start ride gagal: ',
      'acc_failed': 'Perintah ACC gagal diproses.',
      'send_failed': 'Gagal mengirim perintah: ',
      'find_emotor': 'Cari',
      'find_emotor_success': 'Perintah find berhasil dikirim.',
      'find_emotor_failed': 'Perintah find gagal.',
      'find_emotor_title': 'Temukan aku',
      'find_emotor_body':
          'E-motor sedang berbunyi. Ikuti bunyi atau indikator untuk menemukannya.',
      'find_emotor_cta': 'Mengerti',
      'start_ride_title': 'Mulai Ride?',
      'start_ride_body': 'Untuk menggunakan dashboard, mulai ride dulu.',
      'start_ride_button': 'Mulai Ride',
      'my_history': 'Riwayat',
      'stats_mileage': 'Jarak Tempuh',
      'stats_active_days': 'Hari Aktif',
      'days': 'Hari',
      'stats_reduced_emission': 'Pengurangan Emisi',
      'history_load_failed': 'Gagal memuat riwayat.',
      'history_empty': 'Belum ada riwayat perjalanan.',
      'no_ride_id': 'Belum ada ride history. Mulai rental dulu.',
      'detail_trip': 'Detail Perjalanan',
      'distance': 'Jarak Tempuh',
      'rental_duration': 'Waktu Rental',
      'emission_reduction': 'Pengurangan Emisi',
      'start': 'Mulai',
      'date': 'Tanggal',
      'start_time': 'Waktu Mulai',
      'start_position': 'Posisi Mulai',
      'end': 'Akhir',
      'end_time': 'Waktu Akhir',
      'end_position': 'Posisi Akhir',
      'ride_cost': 'Biaya Berkendara',
      'idle_cost': 'Biaya Jeda',
      'total_cost': 'Total Biaya',
      'feedback': 'Umpan Balik',
      'give_feedback': 'Beri Umpan Balik',
      'feedback_hint': 'Bantu kami meningkatkan pengalaman berkendara Anda.',
      'feedback_input': 'Tulis feedback Anda',
      'feedback_success_title': 'Terima kasih!',
      'feedback_success_body':
          'Feedback kamu sudah kami terima. Ini membantu kami membuat perjalanan makin nyaman.',
      'feedback_success_cta': 'Sip, mengerti',
      'cancel': 'Batal',
      'send': 'Kirim',
      'done': 'Selesai',
      'my_profile': 'Profil',
      'display_name': 'Nama Tampilan',
      'name': 'Nama',
      'email': 'Email',
      'phone': 'Nomor Telepon',
      'gender': 'Jenis Kelamin',
      'birthday': 'Tanggal Lahir',
      'id_card': 'Nomor KTP',
      'height': 'Tinggi',
      'weight': 'Berat',
      'logout': 'Keluar',
      'logout_confirm': 'Yakin ingin keluar?',
      'no': 'Tidak',
      'yes': 'Ya',
      'skip': 'Lewati',
      'get_started': 'Mulai',
      'next': 'Lanjut',
      'onboard_title_1': 'Selamat Datang Gridwiz E-Motor',
      'onboard_subtitle_1':
          'Mobilitas listrik yang mulus dengan teknologi real-time.',
      'onboard_title_2': 'Cerdas & Terkoneksi',
      'onboard_subtitle_2':
          'Pantau kecepatan, baterai, dan status kendaraan secara real-time.',
      'onboard_title_3': 'Unlock, Ride, Go',
      'onboard_subtitle_3':
          'Buka e-motor dengan mudah dan mulai perjalananmu, cukup tap, ride, lalu jalan.',
      'duration_hour': 'jam',
      'duration_minute': 'menit',
      'turn_off_confirm_title': 'Matikan e-motor?',
      'turn_off_confirm_body':
          'Pastikan kendaraan sudah berhenti sebelum dimatikan.',
      'turn_off': 'Matikan',
      'loading_connecting_vehicle': 'Menghubungkan ke kendaraan...',
      'loading_sending_command': 'Mengirim perintah ke kendaraan...',
      'loading_finding_vehicle': 'Mencari kendaraan...',
      'loading_processing': 'Memproses...',
      'error_no_internet': 'Tidak ada koneksi internet. Periksa jaringan Anda.',
      'error_send_command_failed':
          'Gagal mengirim perintah ke kendaraan. Coba lagi.',
      'error_vehicle_not_responding':
          'Koneksi lambat. Kendaraan tidak merespons.',
      'error_network_generic': 'Terjadi gangguan jaringan. Silakan coba lagi.',
      'error_history_not_found': 'Detail history tidak ditemukan.',
      'no_internet_description':
          'Periksa jaringan Anda.\nAplikasi akan otomatis melanjutkan saat koneksi tersedia.',
      'end_rental_confirm_title': 'End Rental?',
      'end_rental_confirm_body':
          'Make sure the vehicle is turned off and parked properly before ending the rental.',
      'end_rental_confirm_yes': 'End Rental',
      'end_rental_confirm_no': 'Cancel',
      'loading_ending_rental': 'Ending rental...',
    },
  };

  String get welcomeBack => _t('welcome_back');
  String get loginSubtitle => _t('login_subtitle');
  String get username => _t('username');
  String get usernameHint => _t('username_hint');
  String get password => _t('password');
  String get passwordHint => _t('password_hint');
  String get forgotPassword => _t('forgot_password');
  String get signIn => _t('sign_in');
  String get noAccount => _t('no_account');
  String get contactAdmin => _t('contact_admin');
  String get loginRequired => _t('login_required');
  String get welcome => _t('welcome');
  String get tagline => _t('tagline');
  String get locked => _t('locked');
  String get battery => _t('battery');
  String get statusOn => _t('status_on');
  String get statusOff => _t('status_off');
  String get carbonEmission => _t('carbon_emission');
  String get ping => _t('ping');
  String get rentalTime => _t('rental_time');
  String get on => _t('on');
  String get off => _t('off');
  String get slideToLock => _t('slide_to_lock');
  String get slideToUnlock => _t('slide_to_unlock');
  String get endRental => _t('end_rental');
  String get ending => _t('ending');
  String get live => _t('live');
  String get turnOffBeforeEnd => _t('turn_off_before_end');
  String get turnOffBeforeEndTitle => _t('turn_off_before_end_title');
  String get turnOffBeforeEndBody => _t('turn_off_before_end_body');
  String get checkingEmotorTitle => _t('checking_emotor_title');
  String get checkingEmotorBody => _t('checking_emotor_body');
  String get ok => _t('ok');
  String get endRentalFailed => _t('end_rental_failed');
  String get startRideFailed => _t('start_ride_failed');
  String get accFailed => _t('acc_failed');
  String get sendFailed => _t('send_failed');
  String get findEmotor => _t('find_emotor');
  String get findEmotorSuccess => _t('find_emotor_success');
  String get findEmotorFailed => _t('find_emotor_failed');
  String get findEmotorTitle => _t('find_emotor_title');
  String get findEmotorBody => _t('find_emotor_body');
  String get findEmotorCta => _t('find_emotor_cta');
  String get startRideTitle => _t('start_ride_title');
  String get startRideBody => _t('start_ride_body');
  String get startRideButton => _t('start_ride_button');
  String get myHistory => _t('my_history');
  String get statsMileage => _t('stats_mileage');
  String get statsActiveDays => _t('stats_active_days');
  String get days => _t('days');
  String get statsReducedEmission => _t('stats_reduced_emission');
  String get historyLoadFailed => _t('history_load_failed');
  String get historyEmpty => _t('history_empty');
  String get noRideId => _t('no_ride_id');
  String get detailTrip => _t('detail_trip');
  String get distance => _t('distance');
  String get rentalDuration => _t('rental_duration');
  String get emissionReduction => _t('emission_reduction');
  String get start => _t('start');
  String get date => _t('date');
  String get startTime => _t('start_time');
  String get startPosition => _t('start_position');
  String get end => _t('end');
  String get endTime => _t('end_time');
  String get endPosition => _t('end_position');
  String get rideCost => _t('ride_cost');
  String get idleCost => _t('idle_cost');
  String get totalCost => _t('total_cost');
  String get feedback => _t('feedback');
  String get giveFeedback => _t('give_feedback');
  String get feedbackHint => _t('feedback_hint');
  String get feedbackInput => _t('feedback_input');
  String get feedbackSuccessTitle => _t('feedback_success_title');
  String get feedbackSuccessBody => _t('feedback_success_body');
  String get feedbackSuccessCta => _t('feedback_success_cta');
  String get cancel => _t('cancel');
  String get send => _t('send');
  String get done => _t('done');
  String get myProfile => _t('my_profile');
  String get displayName => _t('display_name');
  String get name => _t('name');
  String get email => _t('email');
  String get phone => _t('phone');
  String get gender => _t('gender');
  String get birthday => _t('birthday');
  String get idCard => _t('id_card');
  String get height => _t('height');
  String get weight => _t('weight');
  String get logout => _t('logout');
  String get logoutConfirm => _t('logout_confirm');
  String get no => _t('no');
  String get yes => _t('yes');
  String get skip => _t('skip');
  String get getStarted => _t('get_started');
  String get next => _t('next');
  String get onboardTitle1 => _t('onboard_title_1');
  String get onboardSubtitle1 => _t('onboard_subtitle_1');
  String get onboardTitle2 => _t('onboard_title_2');
  String get onboardSubtitle2 => _t('onboard_subtitle_2');
  String get onboardTitle3 => _t('onboard_title_3');
  String get onboardSubtitle3 => _t('onboard_subtitle_3');
  String get durationHour => _t('duration_hour');
  String get durationMinute => _t('duration_minute');
  String get turnOffConfirmTitle => _t('turn_off_confirm_title');
  String get turnOffConfirmBody => _t('turn_off_confirm_body');
  String get turnOff => _t('turn_off');
  String get loadingConnectingVehicle => _t('loading_connecting_vehicle');
  String get loadingSendingCommand => _t('loading_sending_command');
  String get loadingFindingVehicle => _t('loading_finding_vehicle');
  String get loadingProcessing => _t('loading_processing');
  String get errorNoInternet => _t('error_no_internet');
  String get errorSendCommandFailed => _t('error_send_command_failed');
  String get errorVehicleNotResponding => _t('error_vehicle_not_responding');
  String get errorNetworkGeneric => _t('error_network_generic');
  String get errorHistoryNotFound => _t('error_history_not_found');
  String get noInternetConnection => _t('no_internet_connection');
  String get noInternetDescription => _t('no_internet_description');
  String get endRentalConfirmTitle => _t('end_rental_confirm_title');
  String get endRentalConfirmBody => _t('end_rental_confirm_body');
  String get endRentalConfirmYes => _t('end_rental_confirm_yes');
  String get endRentalConfirmNo => _t('end_rental_confirm_no');
  String get loadingEndingRental => _t('loading_ending_rental');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations.current = AppLocalizations(locale);
    return AppLocalizations.current;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
