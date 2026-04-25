import 'package:flutter/material.dart';
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:gestion_ausencias/domain/entities/profesor.dart';
import 'package:gestion_ausencias/ui/providers/auth_provider.dart';
import 'package:gestion_ausencias/domain/usecases/get_profesores_con_estado_usecase.dart';
import '../providers/config_provider.dart';

import 'package:gestion_ausencias/ui/screens/settings_screen.dart';
import 'package:gestion_ausencias/ui/screens/guardias_screen.dart';
import 'package:gestion_ausencias/ui/screens/planning_screen.dart';
import 'package:gestion_ausencias/ui/screens/profesor_screen.dart';
import 'package:gestion_ausencias/ui/screens/admin_screen.dart';

// Importación de componentes modulares
import '../widgets/home/home_content.dart';
import '../widgets/navigation/custom_sidebar.dart';
import '../widgets/navigation/custom_bottom_nav.dart';
import '../widgets/navigation/custom_drawer.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback onLogout;

  const MainLayout({super.key, required this.onLogout});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  String _departamentoSeleccionado = 'Todos';
  late Future<List<Profesor>> _profesoresFuture;
  Timer? _refreshTimer;

  // Paleta de colores oficial
  final Color sidebarColor = const Color(0xFF354231);
  final Color activeTabColor = const Color(0xFF5A6F54);
  final Color backgroundColor = const Color(0xFFF9F7F2);

  @override
  void initState() {
    super.initState();
    _profesoresFuture = context.read<GetProfesoresConEstadoUseCase>().execute();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().profesorActual;
      if (user != null) {
        setState(() => _departamentoSeleccionado = user.departamento);
      }
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool _isRefreshing = false;

  void _cargarDatos({bool esSilencioso = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final useCase = context.read<GetProfesoresConEstadoUseCase>();
    try {
      final nuevoFuture = useCase.execute();
      await nuevoFuture;
      if (mounted) {
        setState(() => _profesoresFuture = nuevoFuture);
      }
    } catch (e) {
      debugPrint("Error en auto-refresco: $e");
    } finally {
      _isRefreshing = false;
    }
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _cargarDatos(esSilencioso: true);
    });
  }

  void _irAPagina(int index) {
    if (index >= 6) return;
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      return;
    }
    if (index == 5) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      return;
    }
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<ConfigProvider>();
    final bgProvider = configProvider.backgroundImageProvider;

    return FutureBuilder<List<Profesor>>(
      future: _profesoresFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final todosProfesores = snapshot.data!;
        final screens = [
          HomeContent(
            onNavigate: _irAPagina,
            departamentoSeleccionado: _departamentoSeleccionado,
            onDepartamentoChanged: (dep) => setState(() => _departamentoSeleccionado = dep),
            todosProfesores: todosProfesores,
          ),
          const PlanningScreen(),
          const GuardiasScreen(),
          const ProfesorScreen(),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 850;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final glassColor = isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.7);

            return Scaffold(
              key: const ValueKey('main_scaffold'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              
              // Llamada a componentes modulares externos
              drawer: isMobile ? CustomDrawer(
                onNavigate: _irAPagina,
                onLogout: widget.onLogout,
                sidebarColor: sidebarColor,
                backgroundColor: backgroundColor,
              ) : null,
              
              bottomNavigationBar: isMobile ? CustomBottomNav(
                selectedIndex: _selectedIndex,
                onNavigate: _irAPagina,
                activeColor: activeTabColor,
              ) : null,
              
              body: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bgProvider == null ? Theme.of(context).scaffoldBackgroundColor : null,
                      image: bgProvider != null ? DecorationImage(image: bgProvider, fit: BoxFit.cover) : null,
                    ),
                  ),
                  Row(
                    children: [
                      if (!isMobile) CustomSidebar(
                        selectedIndex: _selectedIndex,
                        onNavigate: _irAPagina,
                        onLogout: widget.onLogout,
                        sidebarColor: sidebarColor,
                        activeTabColor: activeTabColor,
                        glassColor: glassColor,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            if (isMobile) AppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              leading: Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF354231)),
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) => setState(() => _selectedIndex = index),
                                children: screens,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
