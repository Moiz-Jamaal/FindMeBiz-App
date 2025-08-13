import 'package:flutter/material.dart';
import 'package:souq/app/core/widgets/app_logo.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
    title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
      const AppLogo(size: 24, radius: 6),
            const SizedBox(width: 8),
            const Text('FindMeBiz'),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'HomeView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
