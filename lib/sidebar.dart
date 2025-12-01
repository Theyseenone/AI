
import 'package:ai/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Sidebar extends StatefulWidget {
  final VoidCallback onNewChat;
  final List<String> projects;
  final List<String> recentChats;
  final VoidCallback onSelectProject;
  final Function(String) onSelectChat;

  const Sidebar({
    super.key,
    required this.onNewChat,
    required this.projects,
    required this.recentChats,
    required this.onSelectProject,
    required this.onSelectChat,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // Top: New Chat button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.onNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('New Chat'),
            ),
          ),

          // Project section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Project',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Column(
            children: widget.projects.map((project) {
              return ListTile(
                onTap: widget.onSelectProject,
                hoverColor: const Color.fromARGB(255, 182, 202, 216),
                splashColor: const Color.fromARGB(255, 145, 178, 201),
                leading: const Icon(Icons.folder, color: Color.fromARGB(255, 95, 88, 88)),
                title: Text(
                  project,
                  style: const TextStyle(color: Color.fromARGB(255, 95, 88, 88)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
          ),

          // My Chats section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Chats',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: widget.recentChats.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () => widget.onSelectChat(widget.recentChats[index]),
                  hoverColor: const Color.fromARGB(255, 182, 202, 216),
                  splashColor: const Color.fromARGB(255, 145, 178, 201),
                  leading: const Icon(Icons.chat, color: Color.fromARGB(255, 95, 88, 88)),
                  title: Text(
                    widget.recentChats[index],
                    style: const TextStyle(color: Color.fromARGB(255, 95, 88, 88)),
                  ),
                );
              },
            ),
          ),

          // Spacer to push profile to bottom
          const Spacer(),

          // Divider for profile
          const Divider(),

          // Bottom: Account profile
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: const PopupMenuThemeData(
                      color: Colors.white,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'settings') {
                        _showSettingsDialog(context);
                      } else if (value == 'logout') {
                        _showLogoutDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Settings', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0].toUpperCase()
                            : user?.email?.isNotEmpty == true
                                ? user!.email![0].toUpperCase()
                                : 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user?.displayName ?? user?.email ?? 'User',
                    style: const TextStyle(color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Settings',
            style: TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.black),
                title: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to profile settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile settings coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.black),
                title: const Text(
                  'Theme',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to theme settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme settings coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.black),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Navigate to notification settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon')),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
