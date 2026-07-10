import 'package:flutter/material.dart';

class MySpaceScreen extends StatelessWidget {
  const MySpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi espacio')),
      body: const Center(child: Text('Próximamente: tus reservas y actividad')),
    );
  }
}
