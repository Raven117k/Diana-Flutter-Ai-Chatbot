import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? toggleTheme;

  const SettingsPage({super.key, this.toggleTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('isDarkTheme') ?? true;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', !_isDark);
    setState(() => _isDark = !_isDark);
    if (widget.toggleTheme != null) widget.toggleTheme!();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Toggle between light and dark theme"),
            value: _isDark,
            onChanged: (val) => _toggleTheme(),
            secondary: Icon(
              _isDark ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text("About Diana"),
            subtitle: const Text("AI companion powered by Gemini"),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Diana",
                applicationVersion: "v1.0.0",
                applicationLegalese: "© 2025 Raven DevOps",
              );
            },
          ),
        ],
      ),
    );
  }
}
