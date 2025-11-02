import 'package:flutter/material.dart';

class GroupBottomSheet extends StatelessWidget {
  const GroupBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
                'Grup Keluarga',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Tombol Tambah Anggota (Fitur 2)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add, size: 18), // Ganti ikon
                  label: const Text('Tambah Anggota'),
                  onPressed: () {
                    // Logika untuk menambah anggota
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Daftar Anggota
              Expanded(
                child: ListView.builder(
                  controller: controller, // Agar bisa scroll
                  itemCount: 5, // Data dummy
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            'https://placehold.co/100x100/E0E0E0/000000?text=S${index + 1}'),
                      ),
                      title: Text('Anggota Keluarga ${index + 1}'),
                      subtitle: const Text('Lokasi real-time...'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Logika untuk fokus ke anggota
                      },
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
