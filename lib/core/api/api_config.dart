class ApiConfig {
  // Cambia esto por tu URL real
  static const String baseUrl = "http://tec-bpm.tecsersas.com:8008";

   // === Auth ===
  static const String authLogin = '/api/auth/login';

  // === Productivity – Manual ===
  static const String selectedActivities = '/api/selected-activities-admins';
  static const String adminDaily = '/api/admin-daily';     // tu AdminDailyApiController
  static const String adminUnique = '/api/admin-unique';   // tu AdminUniqueApiController

  // === Productivity – Automática ===
  static const String sendLocation = '/api/auto-productivity/send-location';
}
