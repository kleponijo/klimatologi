import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/authentication_bloc/authentication_bloc.dart';
import '../../../blocs/notification_bloc/notification_bloc.dart';
import '../widgets/notification_panel.dart';
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
    return GestureDetector(
      // Tap di luar panel → tutup
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
          title: Row(
            children: [
              Image.asset(
                'images/logo_klimatologi.png',
                height: 90,
                fit: BoxFit.contain,
              ),
            ],
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
            const Center(child: Text('body home page')),

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
    );
  }
}
