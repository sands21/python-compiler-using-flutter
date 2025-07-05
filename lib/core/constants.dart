class AppConstants {
  // Backend API configuration
  static const bool useLocalBackend =
      false; // Set to true for local development

  static const String localExecutionEndpoint = 'http://localhost:5000/execute';
  static const String productionExecutionEndpoint = '/api/execute';

  // Automatically use the correct endpoint
  static const String executionEndpoint =
      useLocalBackend ? localExecutionEndpoint : productionExecutionEndpoint;

  // Error messages
  static const String networkErrorMessage = 'Network connection failed';
  static const String executionErrorMessage = 'Code execution failed';
}
