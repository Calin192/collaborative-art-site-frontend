import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'main.dart'; // Import the new screen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String message = "";


  Future<void> register() async {
    final response = await http.post(
      Uri.parse('$default_url/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': usernameController.text,
        'password': passwordController.text,
      }),
    );
    setState(() {
      message = response.body;
    });
  }

  Future<void> login() async {
    final response = await http.post(
      Uri.parse('$default_url/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': usernameController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Navigate to HomeScreen on successful login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(username: usernameController.text)),
      );
    } else if (response.statusCode == 401) {
      // Display error message for invalid credentials
      setState(() {
        message = 'Login failed: Invalid credentials';
      });
    } else {
      // Handle other errors
      setState(() {
        message = 'Login failed: ${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth System')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: register, child: const Text("Register")),
            ElevatedButton(onPressed: login, child: const Text("Login")),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}