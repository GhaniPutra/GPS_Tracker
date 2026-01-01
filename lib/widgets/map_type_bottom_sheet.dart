
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class MapTypeBottomSheet extends StatefulWidget {
  final String currentMapType;
  final bool is3DEnabled;
  final Function(String) onMapTypeChanged;
  final Function(bool) on3DChanged;

  const MapTypeBottomSheet({
    super.key,
    required this.currentMapType,
    required this.is3DEnabled,
    required this.onMapTypeChanged,
    required this.on3DChanged,
  });

  @override
  State<MapTypeBottomSheet> createState() => _MapTypeBottomSheetState();
}

class _MapTypeBottomSheetState extends State<MapTypeBottomSheet> with TickerProviderStateMixin {
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            _buildHandle(),
            
            // Header
            _buildHeader(theme),
            
            // Map types
            _buildMapTypes(theme),
            
            const SizedBox(height: AppSpacing.lg),
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
              Icons.map,
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
                  'Tipe Peta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Pilih tampilan peta yang diinginkan',
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

  Widget _buildMapTypes(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    final mapTypes = [
      _MapTypeData(
        id: 'default',
        name: 'Standar',
        description: 'Peta jalan standar',
        icon: Icons.map,
        color: Colors.blue,
      ),
      _MapTypeData(
        id: 'satellite',
        name: 'Satelit',
        description: 'Tampilan satelit resolusi tinggi',
        icon: Icons.satellite,
        color: Colors.orange,
      ),
      _MapTypeData(
        id: 'terrain',
        name: 'Terrain',
        description: 'Peta dengan kontur tanah',
        icon: Terrain.terrain,
        color: Colors.green,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: mapTypes.map((type) {
          final index = mapTypes.indexOf(type);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 150 + (index * 50)),
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
            child: _buildMapTypeCard(type, theme, isDark),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapTypeCard(_MapTypeData type, ThemeData theme, bool isDark) {
    final isActive = type.id == widget.currentMapType;

    // Color tokens for light/dark and active/inactive states
    const Color activeTextColor = Colors.white;
    final Color inactiveTextColor = isDark ? const Color(0xFFE0E0E0) : Colors.black87;
    const Color activeDescColor = Colors.white70;
    final Color inactiveDescColor = isDark ? const Color(0xFF94A3B8) : Colors.black54;
    const Color activeIconColor = Colors.white;
    final Color inactiveIconColor = isDark ? const Color(0xFF94A3B8) : type.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: isActive ? AppGradients.primary : null,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Material(
        color: isActive ? Colors.transparent : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          onTap: () {
            // Inform parent and return the selected map type as the result.
            try {
              widget.onMapTypeChanged(type.id);
            } catch (_) {}
            Navigator.pop(context, type.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? null
                        : LinearGradient(
                            colors: [type.color.withOpacity(0.2), type.color.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isActive ? Colors.white.withOpacity(0.08) : type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Icon(
                    type.icon,
                    color: isActive ? activeIconColor : inactiveIconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isActive ? activeTextColor : inactiveTextColor,
                        ),
                      ),
                      Text(
                        type.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isActive ? activeDescColor : inactiveDescColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: isActive ? Colors.white : theme.iconTheme.color?.withOpacity(isDark ? 0.6 : 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapTypeData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _MapTypeData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Custom icon for terrain
class Terrain {
  static const IconData terrain = Icons.landscape;
}

