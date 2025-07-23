import 'package:flutter/material.dart';
import '../screens/account_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_services,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('AnesthesiaSafe'),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Account',
          child: IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A237E),
    );
  }
}