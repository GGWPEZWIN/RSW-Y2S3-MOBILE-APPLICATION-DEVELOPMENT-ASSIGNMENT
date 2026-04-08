import 'package:flutter/material.dart';
import 'Jobseeker/MainScreen/jobseeker_home.dart';

class EmailLoginPage extends StatefulWidget {
  @override
  _EmailLoginPageState createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  // 1. Create a GlobalKey for the form
  final _formKey = GlobalKey<FormState>();

  // 2. Controllers to retrieve text values
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 3. Email Validation Logic using Regex
  String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)";
    final regex = RegExp(pattern);

    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, // 4. Wrap Column in a Form
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail, // Link the validator
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) =>
                value!.length < 6 ? "Password must be 6+ chars" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // 5. Check if the form is valid before navigating
                  if (_formKey.currentState!.validate()) {
                    // Logic for Firebase login would go here
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}