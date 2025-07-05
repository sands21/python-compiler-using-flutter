import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import 'code_editor_widget.dart';

class CodeInputWidget extends StatelessWidget {
  const CodeInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        return CodeEditorWidget(
          controller: provider.codeController,
          hintText: 'Enter your Python code here...',
        );
      },
    );
  }
}
