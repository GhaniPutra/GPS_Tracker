import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gps_tracker_app/screens/bluetooth_scan_screen.dart';
import 'package:gps_tracker_app/services/bluetooth_manager.dart';
import 'package:gps_tracker_app/services/tracker_model.dart';
import '../utils/theme.dart';

class VerifiedDeviceBottomSheet extends StatefulWidget {
  const VerifiedDeviceBottomSheet({super.key});

  @override
  State<VerifiedDeviceBottomSheet> createState() => _VerifiedDeviceBottomSheetState();
}

class _VerifiedDeviceBottomSheetState extends State<VerifiedDeviceBottomSheet> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  
  final BluetoothManager _mgr = BluetoothManager();
  StreamSubscription<TrackerDiscovery>? _confirmedSub;
  final List<TrackerDiscovery> _confirmed = [];

  // Per-device validation state
  final Map<String, bool> _inProgress = {};
  final Map<String, bool?> _lastResult = {};
  final Map<String, DateTime?> _lastChecked = {};

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
    
    _confirmedSub = _mgr.confirmedDiscoveries.listen((d) {
      setState(() {
        _confirmed.removeWhere((e) => e.shortId == d.shortId);
        _confirmed.add(d);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confirmedSub?.cancel();
    super.dispose();
  }

  void _refreshScan() async {
    await _mgr.startScan(timeout: const Duration(seconds: 8));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
              child: _buildContent(theme, isDark),
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
              gradient: AppGradients.secondary,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(
              Icons.verified_user,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perangkat Terverifikasi',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_confirmed.length} perangkat terhubung',
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
            backgroundColor: AppColors.secondary,
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

  Widget _buildContent(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_confirmed.isEmpty) ...[
            _buildEmptyState(theme),
          ] else ...[
            ..._confirmed.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return _buildDeviceCard(d, theme, isDark, index);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.xl),
              ),
              child: Icon(
                Icons.verified_user,
                size: 40,
                color: AppColors.secondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tidak ada perangkat terverifikasi',
              style: theme.textTheme.bodyLarge?.copyWith(
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
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _refreshScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Segarkan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(TrackerDiscovery d, ThemeData theme, bool isDark, int index) {
    final display = d.shortId;
    final isValidating = _inProgress[d.shortId] == true;
    final lastResult = _lastResult[d.shortId];
    final lastChecked = _lastChecked[d.shortId];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: lastResult == true ? AppGradients.secondary : null,
          color: lastResult == true ? null : (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: lastResult == true 
                ? AppColors.secondary 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
              gradient: LinearGradient(
                colors: lastResult == true 
                    ? [AppColors.secondary, AppColors.secondaryLight]
                    : [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Icon(
              lastResult == true ? Icons.check_circle : Icons.gps_fixed,
              color: lastResult == true ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Text(
                display,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: lastResult == true ? Colors.white : null,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (lastResult == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: const Text(
                    'Terverifikasi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'RSSI: ${d.rssi} dBm',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: lastResult == true ? Colors.white70 : null,
                ),
              ),
              if (lastChecked != null)
                Text(
                  'Dicek: ${_formatTime(lastChecked)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: lastResult == true ? Colors.white60 : theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: isValidating 
                    ? const SizedBox(
                        width: 18, 
                        height: 18, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                      )
                    : const Icon(Icons.replay, size: 20),
                onPressed: isValidating ? null : () => _revalidate(d),
                color: lastResult == true ? Colors.white : theme.iconTheme.color,
              ),
              Icon(
                Icons.chevron_right,
                color: lastResult == true ? Colors.white70 : theme.iconTheme.color?.withOpacity(0.5),
              ),
            ],
          ),
          onTap: () {
            // navigate to detail or center map on device GPS when available
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}h lalu';
    return '${diff.inDays}d lalu';
  }

  void _showAddMethodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDeviceMethodSheet(),
    );
  }

  void _revalidate(TrackerDiscovery d) async {
    final id = d.shortId;
    if (_inProgress[id] == true) return;

    setState(() {
      _inProgress[id] = true;
    });

    final ok = await _mgr.validateDiscovery(d);

    if (!mounted) return;

    setState(() {
      _inProgress[id] = false;
      _lastResult[id] = ok;
      _lastChecked[id] = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Validasi berhasil untuk $id' : 'Validasi gagal untuk $id'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
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
          
          _buildMethodTile(
            context,
            icon: Icons.bluetooth,
            title: 'Bluetooth',
            subtitle: 'Cari perangkat terdekat via Bluetooth',
            color: AppColors.primary,
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
              );
              if (result == true) {}
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

