import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../widgets/calendario_tab.dart';
import '../widgets/events_locked_banner.dart';
import '../widgets/profile_events_section.dart';
import 'event_detail_screen.dart';
import 'settings/pro_plan_screen.dart';

class MySpaceScreen extends StatefulWidget {
  final String token;
  final String currentUserId;
  final bool isPro;

  const MySpaceScreen({
    super.key,
    required this.token,
    required this.currentUserId,
    required this.isPro,
  });

  @override
  MySpaceScreenState createState() => MySpaceScreenState();
}

class MySpaceScreenState extends State<MySpaceScreen> {
  late bool _isPro = widget.isPro;

  List<Event>? _events;
  bool _loadingEvents = false;
  String? _eventsError;

  @override
  void initState() {
    super.initState();
    if (_isPro) _loadEvents();
  }

  void refreshMySpace() {
    if (_isPro) _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loadingEvents = true;
      _eventsError = null;
    });
    try {
      final events = await EventService.getMyEvents(token: widget.token);
      if (mounted) setState(() => _events = events);
    } catch (e) {
      if (mounted) setState(() => _eventsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi espacio'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Mis Eventos'),
              Tab(text: 'Mis reservas'),
              Tab(text: 'Guardados'),
              Tab(text: 'Mi red'),
              Tab(text: 'Calendario'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyEventsTab(context),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
            CalendarioTab(token: widget.token, currentUserId: widget.currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_isPro) await _loadEvents();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileEventsSection(
            events: _events,
            isLoading: _loadingEvents,
            error: _eventsError,
            onRetry: _loadEvents,
            emptyMessage: 'Todavía no has creado ningún evento',
            lockedBanner: _isPro
                ? null
                : EventsLockedBanner(
                    onUpgrade: () async {
                      final updatedUser = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProPlanScreen(
                            token: widget.token,
                            subscriptionPlan: SubscriptionPlan.free,
                          ),
                        ),
                      );
                      if (updatedUser != null) {
                        setState(() => _isPro = updatedUser.subscriptionPlan == SubscriptionPlan.pro);
                        if (_isPro) _loadEvents();
                      }
                    },
                  ),
            onEventTap: (e) async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(
                    token: widget.token,
                    event: e,
                    currentUserId: widget.currentUserId,
                  ),
                ),
              );
              if (changed == true) _loadEvents();
            },
          ),
        ],
      ),
    );
  }
}
