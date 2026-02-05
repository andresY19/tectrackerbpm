class Env {
  // Cambia esta URL a tu host (https://tu-dominio.com o http://10.0.2.2:61120)
  static const String baseUrl = "http://localhost:61120";

  // Auth
  static const String loginPath = "/api/auth/login";

  // Manual (Unique)
  static const String adminUniqueInit = "/api/AdminUniqueApi/init";
  static const String adminUniqueUpsert = "/api/AdminUniqueApi/upsert";
  static const String adminUniqueRows = "/api/AdminUniqueApi/rows";

  // Daily (coloca los nombres reales de tu API Daily)
  static const String adminDailyInit = "/api/AdminDailyApi/init";
  static const String adminDailySave = "/api/AdminDailyApi/save";

  // Selección de actividades (ajústalo a tu controlador)
  static const String activitiesList = "/api/Activities/selected"; // ejemplo

  // Configuración del periodo (si lo necesitas separado)
  static const String configPath = "/api/Config/current";

  // Productividad automática (ubicación)
  static const String autoGeoPath = "/api/productivity/geo";
}
