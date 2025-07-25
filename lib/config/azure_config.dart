/// Azure Configuration
/// 
/// Replace these values with your actual Azure deployment details
class AzureConfig {
  // Azure Function App URL
  static const String functionAppUrl = 'https://your-function-app.azurewebsites.net';
  
  // Azure Function Key (get this from Azure Portal)
  static const String functionKey = 'your-function-key-here';
  
  // SAM2 Function endpoint
  static const String sam2Endpoint = '/api/sam2-segment';
  
  // Health check endpoint
  static const String healthEndpoint = '/api/health';
  
  // Timeout settings
  static const Duration requestTimeout = Duration(minutes: 2);
  
  // Maximum file size (in bytes) - 10MB
  static const int maxFileSize = 10 * 1024 * 1024;
  
  /// Validate configuration
  static bool isConfigured() {
    return functionAppUrl != 'https://your-function-app.azurewebsites.net' &&
           functionKey != 'your-function-key-here';
  }
}