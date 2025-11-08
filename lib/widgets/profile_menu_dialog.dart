import 'package:flutter/material.dart';

class ProfileMenuDialog extends StatelessWidget {
  const ProfileMenuDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7, // Lebar 70%
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Sesuaikan tinggi dengan konten
          children: [
            // Info User (Fitur 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                        'https://placehold.co/100x100/E0E0E0/000000?text=User'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VAREUU', // User Name
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'user.account@mail.com', // Akun
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Menu Items
            _buildMenuTile(
              context: context,
              icon: Icons.person_add_alt_1, // Ganti ikon
              text: 'add account',
              onTap: () {},
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.settings, // Ganti ikon
              text: 'settings',
              onTap: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pushNamed(context, '/settings'); // Buka settings
              },
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.help_outline, // Ganti ikon
              text: 'help',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk item menu
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.iconTheme.color?.withAlpha((255 * 0.7).round())),
            const SizedBox(width: 16),
            Text(text, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
