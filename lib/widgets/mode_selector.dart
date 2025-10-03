import 'package:flutter/material.dart';

import '../models/chat_mode.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  final ChatMode currentMode;
  final ValueChanged<ChatMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ChatMode.values.map((mode) {
        final isSelected = currentMode == mode;
        return IconButton(
          icon: Icon(
            mode.icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          tooltip: mode.label,
          onPressed: () => onModeSelected(mode),
        );
      }).toList(),
    );
  }
}
