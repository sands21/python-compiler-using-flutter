import 'package:flutter/material.dart';
import '../../services/python_execution_service.dart';
import '../../models/code_execution_result.dart';

class PythonCompilerProvider with ChangeNotifier {
  final TextEditingController codeController = TextEditingController();
  final List<CodeExecutionResult> executionHistory = [];
  bool isLoading = false;

  // Theme management
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  final PythonExecutionService _executionService = PythonExecutionService();

  Future<void> executeCode() async {
    if (codeController.text.trim().isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      final result = await _executionService.executeCode(codeController.text);
      executionHistory.insert(0, result);
    } catch (e) {
      executionHistory.insert(
          0,
          CodeExecutionResult(
            success: false,
            output: 'Unexpected error occurred',
            error: e.toString(),
          ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    executionHistory.clear();
    notifyListeners();
  }

  void clearCodeInput() {
    codeController.clear();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}
