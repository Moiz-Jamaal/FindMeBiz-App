import 'package:flutter/material.dart';

class SponsoredPill extends StatelessWidget {
  const SponsoredPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Sponsored',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
