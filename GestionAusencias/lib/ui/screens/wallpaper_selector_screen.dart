import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gestion_ausencias/ui/providers/config_provider.dart';

class WallpaperSelectorScreen extends StatelessWidget {
  const WallpaperSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final options = configProvider.wallpapers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cambiar Fondo"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: options.length + 1, // +1 for "No Background" option
          itemBuilder: (context, index) {
            String? bgUrl;
            if (index > 0) {
              bgUrl = options[index - 1];
            }

            final isSelected = configProvider.backgroundImage == bgUrl;

            return GestureDetector(
              onTap: () {
                context.read<ConfigProvider>().setWallpaper(bgUrl);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF6C63FF), width: 3)
                      : Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Background Preview
                      Positioned.fill(
                        child: bgUrl == null
                            ? Center(
                                child: Text(
                                  "Sin Fondo\n(Color sólido)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : (bgUrl.startsWith('assets/')
                                  ? Image.asset(bgUrl, fit: BoxFit.cover)
                                  : Image.network(
                                      bgUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        color: Colors.blueGrey.shade50,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.cloud_off_rounded,
                                                color: Colors.blueGrey.shade200,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Error de red",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      Colors.blueGrey.shade300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      loadingBuilder: (c, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey.shade50,
                                          child: Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )),
                      ),

                      // Chat Bubble Mockup to show contrast
                      if (bgUrl != null)
                        Container(
                          color: Colors.white.withOpacity(
                            0.3,
                          ), // Overlay simulation
                        ),

                      if (isSelected)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF6C63FF),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
