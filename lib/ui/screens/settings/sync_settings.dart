import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assuming SharedPreferences for storing user info.
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/user_notifier.dart';
import 'package:tipitaka_pali/services/repositories/fire_user_repository.dart';
import '../../widgets/colored_text.dart';

class SyncSettingsView extends StatefulWidget {
  const SyncSettingsView({Key? key}) : super(key: key);

  @override
  State<SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<SyncSettingsView> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  _loadPreferences() async {
    setState(() {
      _emailController.text = Prefs.email;
      _passwordController.text = Prefs.password;
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
        elevation: 8,
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
        title: ColoredText("Sign In"), // Changed "Sign Up" to "Sign In"
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
            decoration: InputDecoration(
              labelText: 'Email',
              icon: Icon(Icons.person),
            ),
            onChanged: (value) async {
              Prefs.email = value;
            },
          ),
          SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              icon: Icon(Icons.lock),
            ),
            obscureText: true,
            onChanged: (value) async {
              Prefs.password = value;
            },
          ),
          SizedBox(height: 16.0),
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
                    await userRepository.signIn(
                      _emailController.text,
                      _passwordController.text,
                    );
                  },
            child: Text(Prefs.isSignedIn ? 'Sign Out' : 'Sign In'),
          ),
          SizedBox(height: 16.0),
          (Prefs.isSignedIn)
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: () async {
                    FireUserRepository userRepository =
                        FireUserRepository(notifier: notifier);
                    await userRepository.register(
                        _emailController.text, _passwordController.text);
                  },
                  child: Text('Register'),
                )
        ],
      ),
    );
  }
}
