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
      'nav_history': 'History',
      'nav_dashboard': 'Dashboard',
      'nav_profile': 'Profile',
      'documents': 'Documents',
      'verify_documents': 'Verify Documents',
      'verified': 'Verified',
      'not_verified': 'Not Verified',
      'under_review': 'Under Review',
      'verify_under_review_title': 'Verification Under Review',
      'verify_under_review_body':
          'Your documents are being reviewed. Please wait for approval before purchasing a package.',
      'verify_required_title': 'Verification Required',
      'verify_required_body':
          'To rent a motor, please upload your KTP and SIM first.',
      'upload_documents': 'Upload Documents',
      'payment_pending': 'Payment Pending',
      'payment_pending_body':
          'Please complete your payment using the selected method.',
      'payment_processing': 'Payment is being processed. We will update your status shortly.',
      'time_left': 'Time left',
      'amount_to_pay': 'Amount to pay',
      'need_to_pay': 'Need to pay',
      'additional_pay': 'Additional Pay',
      'pay_before': 'Pay before',
      'session_expired_title': 'Session Expired',
      'session_expired_body': 'Please log in again to continue.',
      'login_again': 'Login Again',
      'contact_admin_title': 'Contact Admin',
      'contact_admin_body':
          'Please contact our admin via WhatsApp for password assistance.',
      'contact_admin_button': 'Open WhatsApp',
      'contact_operator_body':
          'Please contact our operator via WhatsApp for motor assistance.',
      'upload_required': 'Please upload both front and back images.',
      'upload_success': 'Documents uploaded successfully.',
      'upload_file_type_error': 'File must be JPG or PNG.',
      'document_verified_title': 'Documents Verified',
      'document_verified_body':
          'Your documents have been verified. No further action is needed.',
      'document_under_review_title': 'Documents Under Review',
      'document_under_review_body':
          'Your documents are being reviewed. Please wait for approval.',
      'document_ktp': 'Identity Card (KTP)',
      'document_sim': 'Driver License (SIM)',
      'upload': 'Upload',
      'upload_front': 'Upload front side',
      'upload_back': 'Upload back side',
      'upload_hint': '*Please upload your {doc} photo.',
      'doc_front_label': 'Front Image {doc}',
      'doc_back_label': 'Back Image {doc}',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'ride_header': 'Ride',
      'view_package': 'View Package >',
      'package_default': 'Package 1 E-Motor',
      'package_expires': 'Valid until',
      'package_remaining': 'Time left:',
      'membership_title': 'E-Motor Packages',
      'membership_subtitle': 'Pick a package to start riding.',
      'buy': 'Buy',
      'confirm_package_title': 'Confirm package purchase?',
      'confirm_package_body':
          'If you are sure, tap Buy to continue the purchase.',
      'insufficient_title': 'Insufficient Balance',
      'insufficient_body':
          'Your balance does not meet the minimum required for this package.',
      'valid_for': 'Valid for',
      'hours': 'hours',
      'day_label': 'day',
      'min_balance_prefix': 'Minimum balance',
      'finding': 'Finding...',
      'change_motor': 'Change Motor',
      'contact_operator': 'Contact Operator',
      'change_motor_title': 'Contact Operator',
      'change_motor_body':
          'If the motor has an issue or you want to switch, contact the operator for quick assistance.',
      'payment_title': 'Payment',
      'payment_amount_due': 'Amount to pay',
      'payment_method': 'Select payment method',
      'pay': 'Pay',
      'continue': 'Continue',
      'confirm_pay_title': 'Proceed with payment?',
      'confirm_pay_body': 'You will pay {amount}.',
      'balance': 'Balance',
      'payment_success': 'Payment Success',
      'payment_failed': 'Payment Failed',
      'insufficient_balance': 'Your balance is not sufficient to make payment.',
      'duration_label': 'Duration',
      'distance_label': 'Distance',
      'emission_label': 'Emission',
      'cost_label': 'Cost',
      'top_up': 'Top Up',
      'package_label': 'Package',
      'range_label': 'Ride Range',
      'speed_label': 'Speed',
      'recharge_title': 'Top Up',
      'recharge_prompt': 'Enter top up amount',
      'bonus': 'Bonus',
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
      'start_ride_title': 'Choose Package',
      'start_ride_body': 'Choose a package to begin your ride.',
      'start_ride_button': 'Get Packages',
      'my_history': 'My History',
      'stats_mileage': 'Mileage',
      'stats_active_days': 'Active Days',
      'days': 'Days',
      'stats_reduced_emission': 'Reduced Emission',
      'history_load_failed': 'Failed to load history.',
      'history_empty': 'No trip history yet.',
      'membership_history_title': 'Membership History',
      'membership_history_detail': 'Membership Detail',
      'membership_status_active': 'Active',
      'membership_status_expired': 'Expired',
      'membership_status_pending': 'Pending',
      'membership_valid_until': 'Valid until',
      'membership_purchased': 'Purchased',
      'view_rides': 'View rides',
      'pay_membership': 'Pay',
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
      'logout_blocked_title': 'Logout is paused',
      'logout_blocked_body':
          'Please end your rental first, then you can log out safely.',
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
      'error_session_expired': 'Session expired. Please login again.',
      'error_history_not_found': 'Trip details not found.',
      'rental_ended_remote': 'Rental has been ended from backend.',
      'end_rental_confirm_title': 'End Rental?',
      'end_rental_confirm_body':
          'Make sure the vehicle is turned off and parked properly before ending the rental.',
      'end_rental_confirm_yes': 'End Rental',
      'end_rental_confirm_no': 'Cancel',
      'loading_ending_rental': 'Ending rental...',
    },
    'id': {
      'nav_history': 'History',
      'nav_dashboard': 'Dashboard',
      'nav_profile': 'Profile',
      'documents': 'Dokumen',
      'verify_documents': 'Verifikasi Dokumen',
      'verified': 'Terverifikasi',
      'not_verified': 'Belum Terverifikasi',
      'under_review': 'Sedang Ditinjau',
      'verify_under_review_title': 'Verifikasi Sedang Ditinjau',
      'verify_under_review_body':
          'Dokumen Anda sedang ditinjau. Mohon tunggu persetujuan sebelum membeli paket.',
      'verify_required_title': 'Verifikasi Diperlukan',
      'verify_required_body':
          'Untuk menyewa motor, mohon unggah KTP dan SIM terlebih dahulu.',
      'upload_documents': 'Unggah Dokumen',
      'payment_pending': 'Pembayaran Tertunda',
      'payment_pending_body':
          'Silakan selesaikan pembayaran melalui metode yang dipilih.',
      'payment_processing':
          'Pembayaran sedang diproses. Status akan diperbarui segera.',
      'time_left': 'Sisa waktu',
      'amount_to_pay': 'Total yang harus dibayar',
      'need_to_pay': 'Perlu dibayar',
      'additional_pay': 'Biaya tambahan',
      'pay_before': 'Bayar sebelum',
      'session_expired_title': 'Sesi Berakhir',
      'session_expired_body': 'Silakan login ulang untuk melanjutkan.',
      'login_again': 'Login Ulang',
      'contact_admin_title': 'Hubungi Admin',
      'contact_admin_body':
          'Silakan hubungi admin via WhatsApp untuk bantuan password.',
      'contact_admin_button': 'Buka WhatsApp',
      'contact_operator_body':
          'Silakan hubungi operator via WhatsApp untuk bantuan motor.',
      'upload_required': 'Mohon unggah gambar depan dan belakang.',
      'upload_success': 'Dokumen berhasil diunggah.',
      'upload_file_type_error': 'File harus JPG atau PNG.',
      'document_verified_title': 'Dokumen Terverifikasi',
      'document_verified_body':
          'Dokumen Anda sudah terverifikasi. Tidak perlu tindakan tambahan.',
      'document_under_review_title': 'Dokumen Sedang Ditinjau',
      'document_under_review_body':
          'Dokumen Anda sedang ditinjau. Mohon tunggu persetujuan.',
      'document_ktp': 'Kartu Tanda Penduduk (KTP)',
      'document_sim': 'Surat Izin Mengemudi (SIM)',
      'upload': 'Unggah',
      'upload_front': 'Unggah sisi depan',
      'upload_back': 'Unggah sisi belakang',
      'upload_hint': '*Silahkan unggah foto {doc} anda.',
      'doc_front_label': 'Gambar Depan {doc}',
      'doc_back_label': 'Gambar Belakang {doc}',
      'camera': 'Kamera',
      'gallery': 'Galeri',
      'ride_header': 'Berkendara',
      'view_package': 'Lihat Paket >',
      'package_default': 'Paket 1 E-Motor',
      'package_expires': 'Berlaku sampai',
      'package_remaining': 'Sisa waktu:',
      'membership_title': 'Paket Reflow E-Motor',
      'membership_subtitle': 'Pilih paket untuk mulai berkendara.',
      'buy': 'Beli',
      'confirm_package_title': 'Yakin mau beli paket ini?',
      'confirm_package_body':
          'Jika anda yakin membeli paket ini, tekan Beli untuk melanjutkan pembelian.',
      'insufficient_title': 'Saldo Anda Tidak Cukup',
      'insufficient_body':
          'Saldo anda tidak memenuhi jumlah minimum untuk membeli paket ini.',
      'valid_for': 'Masa berlaku',
      'hours': 'Jam',
      'day_label': 'hari',
      'min_balance_prefix': 'Minimal Saldo',
      'finding': 'Mencari...',
      'change_motor': 'Ganti Motor',
      'contact_operator': 'Hubungi Operator',
      'change_motor_title': 'Hubungi Operator',
      'change_motor_body':
          'Jika motor bermasalah atau ingin mengganti, hubungi operator untuk bantuan cepat.',
      'payment_title': 'Pembayaran',
      'payment_amount_due': 'Jumlah yang harus dibayar',
      'payment_method': 'Pilih metode pembayaran',
      'pay': 'Bayar',
      'continue': 'Lanjutkan',
      'confirm_pay_title': 'Yakin lanjut bayar?',
      'confirm_pay_body': 'Kamu akan membayar sebesar {amount}.',
      'balance': 'Saldo',
      'payment_success': 'Pembayaran Berhasil',
      'payment_failed': 'Pembayaran Gagal',
      'insufficient_balance':
          'Saldo Anda tidak mencukupi untuk melakukan pembayaran.',
      'duration_label': 'Durasi',
      'distance_label': 'Jarak',
      'emission_label': 'Emisi',
      'cost_label': 'Biaya',
      'top_up': 'Isi Ulang',
      'package_label': 'Paket',
      'range_label': 'Jarak Berkendara',
      'speed_label': 'Speed',
      'recharge_title': 'Isi Ulang',
      'recharge_prompt': 'Masukkan jumlah isi ulang',
      'bonus': 'Bonus',
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
      'start_ride_title': 'Pilih Paket & Mulai Berkendara',
      'start_ride_body': 'Pilih paket untuk mulai berkendara.',
      'start_ride_button': 'Get Packages',
      'my_history': 'Riwayat',
      'stats_mileage': 'Jarak Tempuh',
      'stats_active_days': 'Hari Aktif',
      'days': 'Hari',
      'stats_reduced_emission': 'Pengurangan Emisi',
      'history_load_failed': 'Gagal memuat riwayat.',
      'history_empty': 'Belum ada riwayat perjalanan.',
      'membership_history_title': 'Riwayat Membership',
      'membership_history_detail': 'Detail Membership',
      'membership_status_active': 'Aktif',
      'membership_status_expired': 'Berakhir',
      'membership_status_pending': 'Menunggu',
      'membership_valid_until': 'Berlaku sampai',
      'membership_purchased': 'Dibeli',
      'view_rides': 'Lihat perjalanan',
      'pay_membership': 'Bayar',
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
      'logout_blocked_title': 'Logout ditunda dulu',
      'logout_blocked_body':
          'Mohon end rental dulu sebelum logout, ya.',
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
      'error_session_expired': 'Sesi berakhir. Silakan login ulang.',
      'error_history_not_found': 'Detail history tidak ditemukan.',
      'rental_ended_remote': 'Rental sudah diakhiri dari backend.',
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
  String get membershipHistoryTitle => _t('membership_history_title');
  String get membershipHistoryDetail => _t('membership_history_detail');
  String get membershipStatusActive => _t('membership_status_active');
  String get membershipStatusExpired => _t('membership_status_expired');
  String get membershipStatusPending => _t('membership_status_pending');
  String get membershipValidUntil => _t('membership_valid_until');
  String get membershipPurchased => _t('membership_purchased');
  String get viewRides => _t('view_rides');
  String get payMembership => _t('pay_membership');
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
  String get logoutBlockedTitle => _t('logout_blocked_title');
  String get logoutBlockedBody => _t('logout_blocked_body');
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
  String get navHistory => _t('nav_history');
  String get navDashboard => _t('nav_dashboard');
  String get navProfile => _t('nav_profile');
  String get documents => _t('documents');
  String get verifyDocuments => _t('verify_documents');
  String get verified => _t('verified');
  String get notVerified => _t('not_verified');
  String get underReview => _t('under_review');
  String get verifyUnderReviewTitle => _t('verify_under_review_title');
  String get verifyUnderReviewBody => _t('verify_under_review_body');
  String get verifyRequiredTitle => _t('verify_required_title');
  String get verifyRequiredBody => _t('verify_required_body');
  String get uploadDocuments => _t('upload_documents');
  String get paymentPending => _t('payment_pending');
  String get paymentPendingBody => _t('payment_pending_body');
  String get paymentProcessing => _t('payment_processing');
  String get timeLeft => _t('time_left');
  String get amountToPay => _t('amount_to_pay');
  String get needToPay => _t('need_to_pay');
  String get additionalPay => _t('additional_pay');
  String get payBefore => _t('pay_before');
  String get sessionExpiredTitle => _t('session_expired_title');
  String get sessionExpiredBody => _t('session_expired_body');
  String get loginAgain => _t('login_again');
  String get contactAdminTitle => _t('contact_admin_title');
  String get contactAdminBody => _t('contact_admin_body');
  String get contactAdminButton => _t('contact_admin_button');
  String get contactOperatorBody => _t('contact_operator_body');
  String get uploadRequired => _t('upload_required');
  String get uploadSuccess => _t('upload_success');
  String get uploadFileTypeError => _t('upload_file_type_error');
  String get documentVerifiedTitle => _t('document_verified_title');
  String get documentVerifiedBody => _t('document_verified_body');
  String get documentUnderReviewTitle => _t('document_under_review_title');
  String get documentUnderReviewBody => _t('document_under_review_body');
  String get documentKtp => _t('document_ktp');
  String get documentSim => _t('document_sim');
  String get upload => _t('upload');
  String get uploadFront => _t('upload_front');
  String get uploadBack => _t('upload_back');
  String get uploadHint => _t('upload_hint');
  String get docFrontLabel => _t('doc_front_label');
  String get docBackLabel => _t('doc_back_label');
  String get camera => _t('camera');
  String get gallery => _t('gallery');
  String get rideHeader => _t('ride_header');
  String get viewPackage => _t('view_package');
  String get packageDefault => _t('package_default');
  String get packageExpires => _t('package_expires');
  String get packageRemaining => _t('package_remaining');
  String get membershipTitle => _t('membership_title');
  String get membershipSubtitle => _t('membership_subtitle');
  String get buy => _t('buy');
  String get confirmPackageTitle => _t('confirm_package_title');
  String get confirmPackageBody => _t('confirm_package_body');
  String get insufficientTitle => _t('insufficient_title');
  String get insufficientBody => _t('insufficient_body');
  String get validFor => _t('valid_for');
  String get hours => _t('hours');
  String get dayLabel => _t('day_label');
  String get minBalancePrefix => _t('min_balance_prefix');
  String get finding => _t('finding');
  String get changeMotor => _t('change_motor');
  String get contactOperator => _t('contact_operator');
  String get changeMotorTitle => _t('change_motor_title');
  String get changeMotorBody => _t('change_motor_body');
  String get paymentTitle => _t('payment_title');
  String get paymentAmountDue => _t('payment_amount_due');
  String get paymentMethod => _t('payment_method');
  String get pay => _t('pay');
  String get continueLabel => _t('continue');
  String get confirmPayTitle => _t('confirm_pay_title');
  String get confirmPayBody => _t('confirm_pay_body');
  String get balance => _t('balance');
  String get paymentSuccess => _t('payment_success');
  String get paymentFailed => _t('payment_failed');
  String get insufficientBalance => _t('insufficient_balance');
  String get durationLabel => _t('duration_label');
  String get distanceLabel => _t('distance_label');
  String get emissionLabel => _t('emission_label');
  String get costLabel => _t('cost_label');
  String get topUp => _t('top_up');
  String get packageLabel => _t('package_label');
  String get rangeLabel => _t('range_label');
  String get speedLabel => _t('speed_label');
  String get rechargeTitle => _t('recharge_title');
  String get rechargePrompt => _t('recharge_prompt');
  String get bonus => _t('bonus');
  String get errorNetworkGeneric => _t('error_network_generic');
  String get errorSessionExpired => _t('error_session_expired');
  String get errorHistoryNotFound => _t('error_history_not_found');
  String get rentalEndedRemote => _t('rental_ended_remote');
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
