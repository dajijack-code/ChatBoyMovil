import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.status,
    required this.onRetry,
  });

  final String? status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(status!),
        trailing: TextButton(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}
