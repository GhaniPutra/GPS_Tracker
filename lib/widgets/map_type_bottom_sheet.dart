import 'package:flutter/material.dart';

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

class _MapTypeBottomSheetState extends State<MapTypeBottomSheet> {
  late String imagePath;
  late bool _is3DEnabled;

  @override
  void initState() {
    super.initState();
    _is3DEnabled = widget.is3DEnabled;
    imagePath = 'assets/images/map_type_default.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipe Peta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMapTypeSelector('Default'),
                _buildMapTypeSelector('Satelit'),
                _buildMapTypeSelector('Medan'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Detail Peta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.view_in_ar,
              title: '3D',
              isEnabled: _is3DEnabled,
              onChanged: (value) {
                setState(() {
                  _is3DEnabled = value;
                });
                widget.on3DChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeSelector(String title) {
    final bool isSelected = widget.currentMapType == title;
    final theme = Theme.of(context);
    const selectedColor = Color(0xFF8FABD4);

    String imagePath;
    switch (title.toLowerCase()) {
      case 'satelit':
        // TODO: Pastikan path aset ini benar dan file gambar ada
        imagePath = 'assets/images/map_type_default.png';
        break;
      case 'medan':
        // TODO: Pastikan path aset ini benar dan file gambar ada
        imagePath = 'assets/images/map_type_default.png';
        break;
      case 'default':
      default:
        imagePath = 'assets/images/map_type_default.png';
        break;
    }

    return GestureDetector(
      onTap: () => widget.onMapTypeChanged(title),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: selectedColor, width: 3)
                  : Border.all(color: Colors.transparent, width: 1),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: isSelected
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: selectedColor.withAlpha((255 * 0.5).round()),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? selectedColor
                  : theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onChanged(!isEnabled),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: theme.iconTheme.color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onChanged,
              activeThumbColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}