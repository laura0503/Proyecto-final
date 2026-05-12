import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';
import 'package:gestion_ausencias/ui/widgets/wallpaper_card.dart';
import 'package:gestion_ausencias/ui/widgets/wallpaper_option_cards.dart';
import 'package:gestion_ausencias/ui/widgets/wallpaper_preview_dialog.dart';

class WallpaperSelectorScreen extends StatelessWidget {
  const WallpaperSelectorScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    HapticFeedback.mediumImpact();
    final originalPath = result.files.single.path!;
    String? finalPath;

    if (Platform.isAndroid || Platform.isIOS) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: originalPath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Encuadrar fondo',
            toolbarColor: const Color(0xFF6C63FF),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF6C63FF),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: false,
          ),
        ],
      );
      finalPath = cropped?.path;
    } else {
      finalPath = originalPath;
    }

    if (finalPath != null && context.mounted) {
      context.read<ConfigProvider>().setWallpaper(finalPath);
      _showSnackBar(context, 'Foto personalizada aplicada');
    }
  }

  void _applyWallpaper(BuildContext context, String path, String name) {
    HapticFeedback.lightImpact();
    context.read<ConfigProvider>().setWallpaper(path);
    _showSnackBar(context, 'Fondo "$name" aplicado');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
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
          _applyWallpaper(context, wallpaper.path, wallpaper.name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final options = configProvider.wallpapers;
    final selectedPath = configProvider.backgroundImage;

    final isCustom = selectedPath != null &&
        !selectedPath.startsWith('assets/') &&
        !selectedPath.startsWith('http');
    final isNone = selectedPath == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      appBar: AppBar(
        title: const Text('Cambiar Fondo',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GalleryPickerCard(
                    isCustom: isCustom,
                    customPath: isCustom ? selectedPath : null,
                    onTap: () => _pickFromGallery(context),
                  ),
                  const SizedBox(height: 12),
                  NoBackgroundCard(
                    isSelected: isNone,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<ConfigProvider>().setWallpaper(null);
                      _showSnackBar(context, 'Fondo eliminado');
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'FONDOS PREDETERMINADOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mantén pulsado para ver la vista previa',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final wallpaper = options[index];
                final isSelected = selectedPath == wallpaper.path;
                return WallpaperCard(
                  wallpaper: wallpaper,
                  isSelected: isSelected,
                  onTap: () => _applyWallpaper(context, wallpaper.path, wallpaper.name),
                  onLongPress: () => _showFullPreview(context, wallpaper),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
