import 'package:flutter/material.dart';

class DraggableMicButton extends StatefulWidget {
  const DraggableMicButton({
    super.key,
    required this.onPressed,
    required this.initialOffset,
    required this.onPositionChanged,
    this.isRecording = false,
    this.isDisabled = false,
    this.onTapDown,
    this.onTapUp,
  });

  final VoidCallback onPressed;
  final Offset initialOffset;
  final ValueChanged<Offset> onPositionChanged;
  final bool isRecording;
  final bool isDisabled;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  @override
  State<DraggableMicButton> createState() => _DraggableMicButtonState();
}

class _DraggableMicButtonState extends State<DraggableMicButton> {
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.initialOffset;
  }

  @override
  void didUpdateWidget(covariant DraggableMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialOffset != widget.initialOffset) {
      _offset = widget.initialOffset;
    }
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      final size = MediaQuery.of(context).size;
      final dx = (_offset.dx + details.delta.dx).clamp(16.0, size.width - 72.0);
      final dy = (_offset.dy + details.delta.dy).clamp(100.0, size.height - 72.0);
      _offset = Offset(dx, dy);
    });
    widget.onPositionChanged(_offset);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      bottom: _offset.dy,
      child: GestureDetector(
        onPanUpdate: widget.isDisabled ? null : _handleDrag,
        onTapDown: widget.isDisabled
            ? null
            : (_) {
                widget.onTapDown?.call();
              },
        onTapUp: widget.isDisabled
            ? null
            : (_) {
                widget.onTapUp?.call();
              },
        onTapCancel: widget.isDisabled
            ? null
            : () {
                widget.onTapUp?.call();
              },
        child: FloatingActionButton(
          onPressed: widget.isDisabled ? null : widget.onPressed,
          backgroundColor: widget.isRecording
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          child: Icon(widget.isRecording ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }
}
