import 'package:diana/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RavenDrawer extends StatefulWidget {
  final VoidCallback onNewChat;

  const RavenDrawer({super.key, required this.onNewChat});

  @override
  State<RavenDrawer> createState() => _RavenDrawerState();
}

class _RavenDrawerState extends State<RavenDrawer> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      _user = currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            accountName: Text(
              _user?.displayName ?? 'New User',
              style: const TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              _user?.email ?? 'Email',
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: _user?.photoURL != null
                ? CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(_user!.photoURL!),
                  )
                : const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            title: const Text(
              'New Chat',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.of(context).pop(); // closes the drawer first
              widget.onNewChat(); // notifies parent to clear chat
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              showAboutDialog(
                context: context,
                applicationName: 'Diana AI',
                applicationVersion: '1.0.4',
                children: const [
                  Text('Made by Raven-DevOps'),
                  Text('Powered by Gemini-API'),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Log-Out', style: TextStyle(color: Colors.white)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Log Out"),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                await prefs.remove('userEmail');

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
