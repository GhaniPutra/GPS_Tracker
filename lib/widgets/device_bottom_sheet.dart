import 'package:flutter/material.dart';

class DeviceBottomSheet extends StatelessWidget {
  const DeviceBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle (garis abu-abu di atas)
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Judul
              Text(
                'Perangkat Terhubung',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Daftar Device (Fitur 1)
              Expanded(
                child: ListView.builder(
                  controller: controller, // Agar bisa scroll
                  itemCount: 2, // Data dummy
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      color: theme.cardColor,
                      child: ListTile(
                        leading: const Icon(Icons.gps_fixed, size: 30), // Ganti ikon
                        title: Text('Perangkat ${index + 1} (Misal: Mobil)'),
                        subtitle: const Text('Online - 10 menit lalu'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Logika untuk fokus ke perangkat
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
