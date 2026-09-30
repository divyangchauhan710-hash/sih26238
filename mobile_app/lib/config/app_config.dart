class AppConfig {
  // Configurable base API URL for development & production deployment
  static String apiBaseUrl = 'https://ekvidya-backend.onrender.com/api'; // Change to deployed server URL or localhost as needed

  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      apiBaseUrl = url.substring(0, url.length - 1);
    } else {
      apiBaseUrl = url;
    }
  }
}
