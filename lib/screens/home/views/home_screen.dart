import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monitoring_repository/monitoring_repository.dart';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import '../../../blocs/notification_bloc/notification_bloc.dart';
import '../../monitoring/wind_speed/blocs/wind_speed_bloc.dart';
import '../../monitoring/evaporasi/blocs/evaporasi_bloc.dart';
import '../../monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart';
import '../../auth/views/welcome_screen.dart';
import '../widgets/notification_panel.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/dashboard_charts.dart';
import 'main_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showNotifications = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleNotifications() {
    setState(() => _showNotifications = !_showNotifications);
    if (_showNotifications) {
      _animController.forward();
      // Tandai semua sebagai dibaca saat panel dibuka
      context.read<NotificationBloc>().add(const NotificationsMarkedAsRead());
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WindSpeedBloc>(
          create: (context) => WindSpeedBloc(
            repository: context.read<MonitoringRepository>(),
            notificationBloc: context.read<NotificationBloc>(),
          )..add(WatchWindSpeedStarted()),
        ),
        BlocProvider<EvaporasiBloc>(
          create: (context) => EvaporasiBloc(
            repository: context.read<MonitoringRepository>(),
            notificationBloc: context.read<NotificationBloc>(),
          )..add(WatchEvaporasiStarted()),
        ),
        BlocProvider<AtmosphericConditionsBloc>(
          create: (context) => AtmosphericConditionsBloc(
            repository: context.read<MonitoringRepository>(),
          )..add(WatchAtmosphericConditionsStarted()),
        ),
      ],
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state.status == AuthenticationStatus.unauthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        },
        child: GestureDetector(
          onTap: () {
            if (_showNotifications) _toggleNotifications();
          },
          child: Scaffold(
            drawer: const MainDrawer(),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              centerTitle: false,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Image.asset(
                'images/logo_klimatologi.png',
                height: 90,
                fit: BoxFit.contain,
              ),
              actions: [
                // Icon lonceng dengan badge
                BlocBuilder<NotificationBloc, NotificationState>(
                  buildWhen: (prev, cur) =>
                      prev.unreadCount != cur.unreadCount ||
                      prev.hasActiveAlerts != cur.hasActiveAlerts,
                  builder: (context, state) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showNotifications
                                ? Icons.notifications
                                : Icons.notifications_none,
                            color: Colors.black,
                          ),
                          onPressed: _toggleNotifications,
                        ),
                        if (state.unreadCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                state.unreadCount > 9
                                    ? '9+'
                                    : '${state.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () => context
                      .read<AuthenticationBloc>()
                      .add(AuthenticationLogoutRequested()),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                // Konten utama
                const _HomeBody(),
                // Dropdown notification panel
                if (_showNotifications)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: GestureDetector(
                        onTap: () {}, // cegah tap di panel menutup panel
                        child: const NotificationPanel(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monitoring Realtime',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 12),
          const SensorGrid(),
          const SizedBox(height: 24), // ← TAMBAH
          const DashboardCharts(), // ← TAMBAH
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
