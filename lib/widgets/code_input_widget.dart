import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';

class CodeInputWidget extends StatelessWidget {
  const CodeInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        return TextField(
          controller: provider.codeController,
          maxLines: null,
          minLines: 5,
          decoration: InputDecoration(
            hintText: 'Enter your Python code here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
    );
  }
}