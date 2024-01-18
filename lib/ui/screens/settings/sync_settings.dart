import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/user_notifier.dart';
import 'package:tipitaka_pali/services/repositories/fire_user_repository.dart';

import '../../widgets/colored_text.dart';

class SyncSettingsView extends StatefulWidget {
  const SyncSettingsView({super.key});

  @override
  State<SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<SyncSettingsView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = Prefs.email; // Set initial value
    // Check if the old password is available and the email matches
    if (Prefs.oldPassword.isNotEmpty && Prefs.email == Prefs.oldUsername) {
      _passwordController.text = Prefs.oldPassword;
    }
  }

  _loadPreferences() {
    setState(() {
      _emailController.text = Prefs.email;
      // Check if the old password is available and the email matches
      if (Prefs.oldPassword.isNotEmpty && Prefs.email == Prefs.oldUsername) {
        _passwordController.text = Prefs.oldPassword;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, notifier, child) {
      if (!Prefs.isSignedIn) {
        _emailController.clear();
        _passwordController.clear();
      }
      return Card(
        child: ExpansionTile(
          leading: const Icon(Icons.sync),
          title: Text(
            "Sync Settings",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          children: [
            const SizedBox(height: 10),
            _inputFields(notifier),
          ],
        ),
      );
    });
  }

  Widget _getSignUpTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: const Icon(Icons.refresh),
        title: const ColoredText("Sign In"), // Changed "Sign Up" to "Sign In"
        focusColor: Theme.of(context).focusColor,
        hoverColor: Theme.of(context).hoverColor,
        onTap: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _inputFields(UserNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              icon: Icon(Icons.person),
            ),
            onChanged: (value) {
              // Save the email to prefs and check for oldUsername match
              Prefs.email = value;
              if (value == Prefs.oldUsername && Prefs.oldPassword.isNotEmpty) {
                _passwordController.text = Prefs.oldPassword;
              } else {
                _passwordController.clear(); // Clear if it does not match
              }
            },
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              icon: Icon(Icons.lock),
            ),
            obscureText: true,
            onChanged: (value) async {
              Prefs.password = value;
            },
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: Prefs.isSignedIn
                ? () async {
                    // Create a FireUserRepository instance
                    FireUserRepository userRepository =
                        FireUserRepository(notifier: notifier);
                    await userRepository.signOut();
                  }
                : () async {
                    // Create a FireUserRepository instance
                    FireUserRepository userRepository =
                        FireUserRepository(notifier: notifier);
                    bool loginSuccess = await userRepository.signIn(
                      _emailController.text,
                      _passwordController.text,
                    );

                    if (loginSuccess) {
                      // Prompt user to save password
                      // check to see if the old password and new one are the same
                      if (Prefs.oldPassword != _passwordController.text) {
                        await _showSavePasswordDialog();
                      }
                    }
                  },
            child: Text(Prefs.isSignedIn ? 'Sign Out' : 'Sign In'),
          ),
          const SizedBox(height: 16.0),
          (Prefs.isSignedIn)
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: () async {
                    FireUserRepository userRepository =
                        FireUserRepository(notifier: notifier);
                    await userRepository.register(
                        _emailController.text, _passwordController.text);
                  },
                  child: const Text('Register'),
                ),
          const SizedBox(height: 16.0),
          (Prefs.isSignedIn)
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: () async {
                    FireUserRepository userRepository =
                        FireUserRepository(notifier: notifier);
                    await userRepository.resetPassword(_emailController.text);
                  },
                  child: const Text('Request Password Reset'),
                ),
        ],
      ),
    );
  }

  Future<void> _showSavePasswordDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog.
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Would you like to save this password for future logins?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Prefs.oldUsername =
                    _emailController.text; // Save the current username
                Prefs.oldPassword =
                    _passwordController.text; // Save the current password
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
