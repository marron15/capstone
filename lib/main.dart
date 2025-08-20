import 'package:flutter/material.dart';
import 'landing_page_components/landing_page.dart';
import 'services/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize auth state from stored tokens
  await authState.initializeFromStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RNR App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AnimatedBuilder(
        animation: authState,
        builder: (context, child) {
          if (!authState.isInitialized) {
            // Show loading screen while initializing auth
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          }
          // Auth is initialized, show the main app
          return const LandingPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
