import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/provider/user_notifier.dart';
import 'package:tipitaka_pali/services/repositories/fire_user_repository.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SyncSettingsView extends StatefulWidget {
  const SyncSettingsView({super.key});

  @override
  State<SyncSettingsView> createState() => _SyncSettingsViewState();
}

class _SyncSettingsViewState extends State<SyncSettingsView> {
  TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedEmail = ''; // To store the selected email

  @override
  void initState() {
    super.initState();
    _emailController.text = Prefs.email;
    if (Prefs.oldPassword.isNotEmpty && Prefs.email == Prefs.oldUsername) {
      _passwordController.text = Prefs.oldPassword;
    }
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
            AppLocalizations.of(context)!.cloudSettings,
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

  Widget _inputFields(UserNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return [Prefs.oldUsername].where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            optionsViewBuilder: (BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: SizedBox(
                    width: 350, // Set the width of the suggestions box
                    height:
                        100, // Set the height of the suggestions box, optional
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10.0),
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return GestureDetector(
                          onTap: () {
                            onSelected(option);
                          },
                          child: ListTile(
                            title: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController controller,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted,
            ) {
              _emailController = controller; // Syncing with _emailController
              return TextFormField(
                controller: _emailController,
                focusNode: focusNode,
                onChanged: (value) {
                  Prefs.email = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Email',
                  icon: Icon(Icons.email),
                ),
              );
            },
            onSelected: (String selection) {
              selectedEmail = selection;
              _emailController.text = selectedEmail;
              _passwordController.text = Prefs.oldPassword;
            },
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              icon: const Icon(Icons.lock),
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
            child: Text(Prefs.isSignedIn
                ? AppLocalizations.of(context)!.signOut
                : AppLocalizations.of(context)!.signIn),
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
                  child: Text(AppLocalizations.of(context)!.register),
                ),
          const SizedBox(height: 16.0),
          (Prefs.isSignedIn)
              ? const SizedBox.shrink()
              : ElevatedButton(
                  onPressed: () async {
                    await _showResetPasswordDialog(notifier);
                  },
                  child: Text(AppLocalizations.of(context)!.resetPassword),
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
          title: Text(AppLocalizations.of(context)!.savePassword),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.savePasswordMessage),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.no),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.yes),
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

  Future<void> _showResetPasswordDialog(UserNotifier notifier) async {
    TextEditingController resetEmailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog.
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.resetPassword),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.resetPasswordMessage),
                TextFormField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.submit),
              onPressed: () async {
                if (resetEmailController.text.isNotEmpty) {
                  // Perform password reset
                  FireUserRepository userRepository =
                      FireUserRepository(notifier: notifier);
                  await userRepository.resetPassword(resetEmailController.text);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
