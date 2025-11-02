import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _area = true;
  bool _quest = true;
  bool _is3DView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              // Info User
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                          'https://placehold.co/100x100/E0E0E0/000000?text=User'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAREUU',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'user.account@gmail.com',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Pilihan Tema
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Tema'),
                trailing: DropdownButton<ThemeMode>(
                  value: themeProvider.themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      themeProvider.setThemeMode(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('Sistem'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Terang'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Gelap'),
                    ),
                  ],
                ),
              ),
              // Fitur 1: Notifikasi
              SwitchListTile(
                secondary: const Icon(Icons.notifications), // Ganti ikon
                title: const Text('Notifications'),
                value: _notifications,
                onChanged: (bool value) {
                  setState(() {
                    _notifications = value;
                  });
                },
              ),
              // Fitur 2: Area
              SwitchListTile(
                secondary: const Icon(Icons.map_outlined), // Ganti ikon
                title: const Text('Area'),
                value: _area,
                onChanged: (bool value) {
                  setState(() {
                    _area = value;
                  });
                },
              ),
              // Fitur 3: Lapisan (2D/3D)
              SwitchListTile(
                secondary: const Icon(Icons.layers_outlined), // Ganti ikon
                title: const Text('Tampilan Peta 3D (Lapisan)'),
                value: _is3DView,
                onChanged: (bool value) {
                  setState(() {
                    _is3DView = value;
                  });
                },
              ),
              // Fitur 4: Quest
              SwitchListTile(
                secondary: const Icon(Icons.redeem), // Ganti ikon
                title: const Text('Quest'),
                value: _quest,
                onChanged: (bool value) {
                  setState(() {
                    _quest = value;
                  });
                },
              ),
              const Divider(),
              // Tombol Log Out
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red), // Ganti ikon
                title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login', (Route<dynamic> route) => false);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
