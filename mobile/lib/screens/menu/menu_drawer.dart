import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/providers/theme_provider.dart'; // Add this import

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + 20, // Account for status bar
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // borderRadius: const BorderRadius.only(
        //   topRight: Radius.circular(20),
        //   bottomRight: Radius.circular(20),
        // ),
        // boxShadow: [
        //   BoxShadow(
        //     color: const Color.fromARGB(255, 82, 82, 82).withOpacity(0.2),
        //     blurRadius: 10,
        //     spreadRadius: 5,
        //   )
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuHeader(context),
          const SizedBox(height: 20), // Add this instead of Divider
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDBCredentials(context),
                  _buildThemeSelector(context, ref, currentTheme),
                ],
              ),
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildMenuHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color.fromARGB(255, 103, 103, 103),
        ),
        const SizedBox(width: 10),
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildDBCredentials(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: const Text('Credentials'),
      trailing: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: 'Manage database connection settings',
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showDbInfo(context),
          ),
        ),
      ),
      onTap: () =>
          launchUrl(Uri.parse('https://genie.applicare.io/genie/#/login')),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, WidgetRef ref, ThemeMode currentTheme) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      trailing: DropdownButton<ThemeMode>(
        icon: Icon(
          Icons.unfold_more, // Changed from default arrow
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        value: currentTheme,
        items: const [
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text('Light'),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text('Dark'),
          ),
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text('System'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            ref.read(themeProvider.notifier).setTheme(value);
            // Show confirmation in current context
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text(
            //         'Theme changed to ${value.toString().split('.').last}'),
            //     duration: const Duration(seconds: 1),
            //   ),
            // );
          }
        },
        dropdownColor: Theme.of(context).dialogBackgroundColor,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.of(context).pushReplacementNamed('/login');
        },
        child: const Text('Log out'),
      ),
    );
  }

  void _showDbInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Credentials'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(
                text:
                    'You can manage your database connection settings, including the host, port, username, password, '
                    'and table structure, within the Genie web application. You can click on ',
              ),
              TextSpan(
                text: 'Genie web application',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    const url = 'https://genie.applicare.io/genie/#/login';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
              ),
              const TextSpan(
                text: ' to navigate to the web application.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
