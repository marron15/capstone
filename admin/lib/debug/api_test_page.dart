import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({Key? key}) : super(key: key);

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing API connection...';
    });

    try {
      final isConnected = await ApiService.checkApiConnection();

      setState(() {
        _testResult = isConnected
            ? '✅ API Connection: SUCCESS\nServer is reachable'
            : '❌ API Connection: FAILED\nServer is not reachable';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ API Connection: ERROR\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignupEndpoint() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing signup endpoint...';
    });

    try {
      final result = await ApiService.testSignupEndpoint();

      setState(() {
        _testResult = '''
🔍 SIGNUP ENDPOINT TEST
Endpoint: ${result['endpoint']}
Status Code: ${result['status_code']}
Response: ${result['response_body']}
${result['error'] != null ? '\nError: ${result['error']}' : ''}
        '''
            .trim();
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Signup Endpoint: ERROR\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testActualSignup() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing actual signup...';
    });

    try {
      final result = await ApiService.signupUser(
        firstName: 'Test',
        lastName: 'User',
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpassword123',
        street: '123 Test Street',
        city: 'Test City',
        state: 'Test State',
        postalCode: '12345',
        country: 'Test Country',
      );

      setState(() {
        _testResult = '''
🧪 ACTUAL SIGNUP TEST
Success: ${result['success']}
Message: ${result['message']}
${result['user'] != null ? 'User ID: ${result['user']['id']}' : ''}
${result['access_token'] != null ? 'Token Generated: YES' : 'Token Generated: NO'}
        '''
            .trim();
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Actual Signup: ERROR\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetAllUsers() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing get all users...';
    });

    try {
      final result = await ApiService.getAllUsers();

      setState(() {
        _testResult = '''
👥 GET ALL USERS TEST
Success: ${result['success']}
Message: ${result['message']}
${result['data'] != null ? 'Users Found: ${result['data'].length}' : ''}
${result['data'] != null && result['data'].isNotEmpty ? 'First User: ${result['data'][0]['full_name']} (${result['data'][0]['email']})' : ''}
        '''
            .trim();
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Get All Users: ERROR\n$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Testing'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'API Integration Tests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApiConnection,
              child: const Text('Test API Connection'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSignupEndpoint,
              child: const Text('Test Signup Endpoint'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testActualSignup,
              child: const Text('Test Actual Signup'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testGetAllUsers,
              child: const Text('Test Get All Users'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? 'No tests run yet.' : _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Make sure XAMPP is running\n'
              '2. Ensure sample_api is in htdocs\n'
              '3. Test connection first\n'
              '4. If connection works, test the signup',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
