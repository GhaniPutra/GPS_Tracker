import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../utils/theme.dart';
import 'package:latlong2/latlong.dart';

class MemberCardWidget extends StatefulWidget {
  final ConnectedUser user;
  final int index;
  final VoidCallback onRevoke;

  const MemberCardWidget({
    super.key,
    required this.user,
    required this.index,
    required this.onRevoke,
  });

  @override
  State<MemberCardWidget> createState() => _MemberCardWidgetState();
}

class _MemberCardWidgetState extends State<MemberCardWidget> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + (widget.index * 50)),
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
          color: (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            _buildMainContent(theme),
            if (_showActions) _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = widget.user.hasRecentLocation;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isOnline ? AppGradients.primary : null,
              color: isOnline ? null : AppColors.markerDeviceOffline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppBorderRadius.full),
            ),
            child: widget.user.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    child: Image.network(
                      widget.user.photoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      widget.user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
          // Online indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.markerDeviceOffline,
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
                border: Border.all(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Text(
            widget.user.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: _buildSubtitle(theme),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'revoke') {
            widget.onRevoke();
          } else if (value == 'center') {
            _centerOnUser();
          }
        },
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'center',
            child: Row(
              children: [
                Icon(Icons.my_location, size: 18),
                SizedBox(width: AppSpacing.sm),
                Text('Tampilkan di peta'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'revoke',
            child: Row(
              children: [
                Icon(Icons.person_remove, size: 18, color: AppColors.error),
                SizedBox(width: AppSpacing.sm),
                Text('Hapus', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
        icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.5)),
      ),
      onTap: () {
        setState(() {
          _showActions = !_showActions;
        });
      },
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    if (widget.user.location != null) {
      return Row(
        children: [
          const Icon(Icons.location_on, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Expanded(
            child: Consumer<ConnectionProvider>(
              builder: (context, cp, _) {
                // Get current position from home screen context
                // In a real implementation, this would come from a location provider
                return FutureBuilder<LatLng?>(
                  future: _getCurrentPosition(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final distance = _calculateDistance(snapshot.data!, widget.user.location!.toLatLng());
                      return Text(
                        distance,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return const Text(
                      'Lokasi aktif',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Text(
      widget.user.isOnline ? 'Online' : 'Lokasi terakhir: ${_formatTimeAgo(widget.user.location?.lastUpdate)}',
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppBorderRadius.md),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: _centerOnUser,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Tampilkan di peta'),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: widget.onRevoke,
              icon: const Icon(Icons.person_remove, size: 18, color: AppColors.error),
              label: const Text('Hapus', style: TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnUser() {
    if (widget.user.location != null) {
      // Notify parent to center map on this user
      // This would typically be done through a callback or provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menampilkan lokasi ${widget.user.displayName}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
      );
    }
  }

  Future<LatLng?> _getCurrentPosition() async {
    // This would get the current user position from a provider
    return null;
  }

  String _calculateDistance(LatLng from, LatLng to) {
    const distance = Distance();
    final meters = distance(from, to);
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m dari Anda';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km dari Anda';
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Tidak diketahui';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }
}

