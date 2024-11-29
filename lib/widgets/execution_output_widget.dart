import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';

class ExecutionOutputWidget extends StatelessWidget {
  const ExecutionOutputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        if (provider.executionHistory.isEmpty) {
          return const Center(
            child: Text(
              'No execution history',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.executionHistory.length,
          itemBuilder: (context, index) {
            final result = provider.executionHistory[index];
            return ListTile(
              title: Text(
                result.toString(),
                style: TextStyle(
                  color: result.success ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }
}