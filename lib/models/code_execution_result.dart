class CodeExecutionResult {
  final bool success;
  final String output;
  final String? error;

  const CodeExecutionResult({
    required this.success,
    required this.output,
    this.error,
  });

  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) {
    return CodeExecutionResult(
      success: json['success'] ?? false,
      output: json['output'] ?? '',
      error: json['error'],
    );
  }

  @override
  toString() => success ? 'Output: $output' : 'Error: ${error ?? output}';
}