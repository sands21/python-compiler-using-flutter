import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/code_execution_result.dart';

class PythonExecutionService {
  Future<CodeExecutionResult> executeCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.executionEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      );

      if (response.statusCode == 200) {
        return CodeExecutionResult.fromJson(json.decode(response.body));
      } else {
        return CodeExecutionResult(
          success: false,
          output: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return CodeExecutionResult(
        success: false,
        output: AppConstants.networkErrorMessage,
        error: e.toString(),
      );
    }
  }
}