import 'package:flutter/material.dart';

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
  void refreshMySpace() {}

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
        body: const TabBarView(
          children: [
            SizedBox.shrink(),
            SizedBox.shrink(),
            SizedBox.shrink(),
            SizedBox.shrink(),
            SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
