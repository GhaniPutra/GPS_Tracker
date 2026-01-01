import 'package:flutter/material.dart';
import 'package:gps_tracker_app/providers/bluetooth_provider.dart';
import 'package:gps_tracker_app/screens/bluetooth_scan_screen.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';

class DeviceBottomSheet extends StatefulWidget {
  const DeviceBottomSheet({super.key});

  @override
  State<DeviceBottomSheet> createState() => _DeviceBottomSheetState();
}

class _DeviceBottomSheetState extends State<DeviceBottomSheet> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _animation.value),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.xl),
          ),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            _buildHandle(),
            
            // Header
            _buildHeader(theme),
            
            // Add device button
            _buildAddDeviceButton(theme),
            
            // Content
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppBorderRadius.full),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              Icons.devices,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perangkat',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Kelola perangkat terhubung',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDeviceButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Tambah Perangkat'),
          onPressed: () => _showAddMethodSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        final connected = bt.connectedDevices;
        final known = bt.knownDevices;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connected devices section
              if (connected.isNotEmpty) ...[
                _buildSectionHeader(theme, 'Terhubung (${connected.length})'),
                const SizedBox(height: AppSpacing.sm),
                ...connected.map((conn) => _buildConnectedDeviceCard(conn, theme)),
                const SizedBox(height: AppSpacing.lg),
              ],
              
              // Stored devices section
              _buildSectionHeader(theme, 'Tersimpan (${known.length})'),
              const SizedBox(height: AppSpacing.sm),
              
              if (known.isEmpty)
                _buildEmptyState(theme)
              else
                _buildStoredDevicesList(bt, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard(dynamic conn, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final device = conn.device;
    final deviceName = conn.name;
    final hasPos = conn.lastPosition != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hasPos ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Icon(
            Icons.bluetooth_connected,
            color: hasPos ? AppColors.success : AppColors.warning,
            size: 24,
          ),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              device.remoteId.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
            if (hasPos)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Lokasi aktif',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final provider = Provider.of<BluetoothProvider>(context, listen: false);
            if (value == 'disconnect') {
              await provider.disconnectDevice(device);
              _showSnackBar('Terputus dari $deviceName');
            } else if (value == 'forget') {
              await provider.forgetDeviceById(device.remoteId.toString());
              _showSnackBar('$deviceName dihapus');
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'disconnect', child: Text('Putuskan')),
            const PopupMenuItem(value: 'forget', child: Text('Hapus')),
          ],
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.5)),
        ),
        onTap: () {
          final provider = Provider.of<BluetoothProvider>(context, listen: false);
          provider.selectDevice(device);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildStoredDevicesList(BluetoothProvider bt, ThemeData theme) {
    final known = bt.knownDevices;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: known.map((d) {
        final hasPos = d.lastLat != null && d.lastLon != null;
        final isConnected = bt.connectedDevices.any((c) => c.id == d.id);
        
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.42,
          child: _buildStoredDeviceCard(d, theme, hasPos, isConnected),
        );
      }).toList(),
    );
  }

  Widget _buildStoredDeviceCard(dynamic d, ThemeData theme, bool hasPos, bool isConnected) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isConnected 
            ? AppGradients.primary 
            : null,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isConnected 
              ? AppColors.primary 
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.devices_other,
                  size: 18,
                  color: isConnected ? Colors.white : theme.iconTheme.color,
                ),
                const Spacer(),
                if (hasPos)
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: isConnected ? Colors.white70 : AppColors.success,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              d.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isConnected ? Colors.white : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasPos)
              Text(
                'Pos terakhir: ${d.lastLat!.toStringAsFixed(4)}, ${d.lastLon!.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isConnected ? Colors.white70 : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: isConnected
                      ? TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            ),
                          ),
                          child: const Text(
                            'Terhubung',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final provider = Provider.of<BluetoothProvider>(context, listen: false);
                            final activeIndex = provider.connectedDevices.indexWhere((c) => c.id == d.id);
                            if (activeIndex != -1) {
                              provider.selectDevice(provider.connectedDevices[activeIndex].device);
                              Navigator.pop(context);
                            } else if (hasPos) {
                              provider.selectStoredDevicePosition(d);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Hubungkan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Delete button for stored device
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    color: isConnected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                  ),
                  child: IconButton(
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: isConnected ? Colors.white70 : AppColors.error,
                    ),
                    onPressed: () async {
                      // Confirm before deleting
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus perangkat'),
                          content: Text('Hapus perangkat "${d.name}" dari daftar tersimpan?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final provider = Provider.of<BluetoothProvider>(context, listen: false);
                        try {
                          await provider.forgetDeviceById(d.id);
                          _showSnackBar('Perangkat "${d.name}" dihapus');
                        } catch (e) {
                          _showSnackBar('Gagal menghapus perangkat');
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.devices_other,
              size: 48,
              color: theme.iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada perangkat tersimpan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tambahkan perangkat untuk memulai',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMethodSheet(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDeviceMethodSheet(),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }
}

class _AddDeviceMethodSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Text(
            'Tambah Perangkat',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Methods
          _buildMethodTile(
            context,
            icon: Icons.bluetooth,
            title: 'Bluetooth',
            subtitle: 'Cari perangkat terdekat via Bluetooth',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
              );
            },
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          _buildMethodTile(
            context,
            icon: Icons.wifi,
            title: 'Wi-Fi',
            subtitle: 'Hubungkan via jaringan Wi-Fi',
            color: AppColors.secondary,
            onTap: () {
              Navigator.pop(context);
              // Handle Wi-Fi connection
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMethodTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

