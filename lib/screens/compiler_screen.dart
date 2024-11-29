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
              return IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: provider.clearHistory,
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
                      onPressed: provider.isLoading ? null : provider.executeCode,
                      child: provider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Run Code'),
                    ),
                    ElevatedButton(
                      onPressed: provider.clearCodeInput,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
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