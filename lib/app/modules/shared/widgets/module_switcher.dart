import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/user_role.dart';
import '../../../services/role_service.dart';

class ModuleSwitchButton extends StatelessWidget {
  const ModuleSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final role = Get.find<RoleService>().currentRole;
    return Obx(() {
      final isBuyer = role.value == UserRole.buyer;
      return IconButton(
        tooltip: isBuyer ? 'Switch to Seller' : 'Switch to Buyer',
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: isBuyer
              ? const Color(0xFF2E7D32) // seller green when switching to seller
              : const Color(0xFF0EA5A4), // brand teal when switching to buyer
          child: const Icon(
            Icons.swap_horiz,
            size: 18,
            color: Colors.white,
          ),
        ),
        onPressed: () => showModuleSwitchSheet(context),
      );
    });
  }
}

Future<void> showModuleSwitchSheet(BuildContext context) async {
  final roleService = Get.find<RoleService>();
  final current = roleService.currentRole.value;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(
              context,
              title: 'Buyer',
              subtitle: 'Browse and order',
              icon: Icons.shopping_bag_outlined,
              selected: current == UserRole.buyer,
              onTap: () => roleService.switchTo(UserRole.buyer),
            ),
            _tile(
              context,
              title: 'Seller',
              subtitle: 'Manage catalog and profile',
              icon: Icons.storefront_outlined,
              selected: current == UserRole.seller,
              onTap: () => roleService.switchTo(UserRole.seller),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Widget _tile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: selected ? const Icon(Icons.check) : null,
    onTap: () {
      Navigator.of(context).pop();
      onTap();
    },
  );
}
