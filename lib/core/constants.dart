class AppConstants {
  // Backend API configuration
  static const String backendBaseUrl = 'http://10.0.2.2:5000';
  static const String executionEndpoint = '$backendBaseUrl/execute';

  // Error messages
  static const String networkErrorMessage = 'Network connection failed';
  static const String executionErrorMessage = 'Code execution failed';
}