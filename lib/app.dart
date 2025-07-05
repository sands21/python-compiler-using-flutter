import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:python_compiler_with_flutter/providers/provider.dart';
import 'package:python_compiler_with_flutter/screens/compiler_screen.dart';

class PythonCompilerApp extends StatelessWidget {
  const PythonCompilerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PythonCompilerProvider()),
      ],
      child: Consumer<PythonCompilerProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Python Compiler',
            debugShowCheckedModeBanner: false,
            themeMode: provider.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              cardColor: Colors.white,
              dividerColor: Colors.grey[300],
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1E1E1E),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2D2D30),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              cardColor: const Color(0xFF2D2D30),
              dividerColor: const Color(0xFF3E3E42),
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Color(0xFF2D2D30),
                onSurface: Colors.white,
              ),
            ),
            home: const PythonCompilerScreen(),
          );
        },
      ),
    );
  }
}
