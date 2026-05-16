import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../providers/config_provider.dart';
import '../../../widgets/wallpaper_preview_dialog.dart';

class MobileWallpaperSelectorScreen extends StatelessWidget {
  const MobileWallpaperSelectorScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    HapticFeedback.mediumImpact();
    final originalPath = result.files.single.path!;

    final cropped = await ImageCropper().cropImage(
      sourcePath: originalPath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Encuadrar fondo',
          toolbarColor: const Color(0xFF4F46E5),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF4F46E5),
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          showCropGrid: false,
        ),
      ],
    );

    if (cropped != null && context.mounted) {
      context.read<ConfigProvider>().setWallpaper(cropped.path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto personalizada aplicada')),
      );
    }
  }

  void _showFullPreview(BuildContext context, WallpaperItem wallpaper) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => WallpaperPreviewDialog(
        wallpaper: wallpaper,
        onApply: () {
          Navigator.pop(ctx);
          HapticFeedback.lightImpact();
          context.read<ConfigProvider>().setWallpaper(wallpaper.path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Personalizar Fondo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: _buildSpecialOptions(context, config),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: config.wallpapers.length,
              itemBuilder: (context, index) {
                final wp = config.wallpapers[index];
                return _buildOption(
                  context,
                  wp.name,
                  wp.path,
                  config.backgroundImage == wp.path,
                  onLongPress: () => _showFullPreview(context, wp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOptions(BuildContext context, ConfigProvider config) {
    return Row(
      children: [
        Expanded(
          child: _SpecialCard(
            title: 'Galería',
            icon: Icons.add_photo_alternate_rounded,
            color: const Color(0xFF4F46E5),
            onTap: () => _pickFromGallery(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SpecialCard(
            title: 'Sin Fondo',
            icon: Icons.block_flipped,
            color: Colors.grey,
            isSelected: config.backgroundImage == null,
            onTap: () {
              HapticFeedback.lightImpact();
              config.setWallpaper(null);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, String name, String path, bool isSelected, {VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<ConfigProvider>().setWallpaper(path);
      },
      onLongPress: onLongPress,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 13 : 15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (path.startsWith('http'))
                      Image.network(path, fit: BoxFit.cover)
                    else
                      Image.asset(path, fit: BoxFit.cover),
                    if (isSelected)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? const Color(0xFF818CF8) : Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecialCard({
    required this.title,
    required this.icon,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
