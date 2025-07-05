import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:python_compiler_with_flutter/providers/provider.dart';
import 'package:python_compiler_with_flutter/screens/compiler_screen.dart';

class PythonCompilerApp extends StatelessWidget {
  const PythonCompilerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Compiler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PythonCompilerProvider()),
        ],
        child: const PythonCompilerScreen(),
      ),
    );
  }
}
