import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import '../widgets/code_input_widget.dart';
import '../widgets/execution_output_widget.dart';

class PythonCompilerScreen extends StatelessWidget {
  const PythonCompilerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Code Compiler'),
        actions: [
          Consumer<PythonCompilerProvider>(
            builder: (context, provider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(provider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode),
                    onPressed: provider.toggleTheme,
                    tooltip: provider.isDarkMode
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: provider.clearHistory,
                    tooltip: 'Clear History',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<PythonCompilerProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CodeInputWidget(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed:
                          provider.isLoading ? null : provider.executeCode,
                      child: provider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Run Code'),
                    ),
                    ElevatedButton(
                      onPressed: provider.clearCodeInput,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isDarkMode
                            ? Colors.red[800]
                            : Colors.red.shade100,
                        foregroundColor: provider.isDarkMode
                            ? Colors.red[100]
                            : Colors.red[800],
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ExecutionOutputWidget(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
