import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

enum BpmToastType { success, info, warning, error }

class BpmToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Uso normal desde pantallas con un [BuildContext]
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    BpmToastType type = BpmToastType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    bool dismissible = true,
  }) {
    hide();

    // Intentamos encontrar el overlay raíz desde el contexto
    final overlay = Overlay.maybeOf(
      context,
      rootOverlay: true,
    );
    if (overlay == null) {
      debugPrint('! BpmToast.show(): No Overlay found in context (rootOverlay)');
      return;
    }

    final theme = Theme.of(context);
    _insertToast(
      overlay: overlay,
      theme: theme,
      title: title,
      message: message,
      type: type,
      duration: duration,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
      dismissible: dismissible,
    );
  }

  /// 🔹 NUEVO: uso directo desde un [OverlayState]
  /// Ideal para usar con rootNavigatorKey.currentState?.overlay
  static void showFromOverlay(
    OverlayState overlay, {
    required String title,
    String? message,
    BpmToastType type = BpmToastType.info,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    bool dismissible = true,
  }) {
    hide();

    final theme = Theme.of(overlay.context);

    _insertToast(
      overlay: overlay,
      theme: theme,
      title: title,
      message: message,
      type: type,
      duration: duration,
      icon: icon,
      actionText: actionText,
      onAction: onAction,
      dismissible: dismissible,
    );
  }

  /// Helper privado que realmente crea e inserta el overlay
  static void _insertToast({
    required OverlayState overlay,
    required ThemeData theme,
    required String title,
    String? message,
    required BpmToastType type,
    required Duration duration,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
    required bool dismissible,
  }) {
    final color = _colorFor(type, theme);
    final fallbackIcon = _iconFor(type);
    final usedIcon = icon ?? fallbackIcon;

    _entry = OverlayEntry(
      builder: (_) => _BpmToastView(
        title: title,
        message: message,
        color: color,
        icon: usedIcon,
        actionText: actionText,
        onAction: onAction,
        dismissible: dismissible,
        onClose: hide,
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, () => hide());
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static Color _colorFor(BpmToastType type, ThemeData theme) {
    switch (type) {
      case BpmToastType.success:
        return Colors.green;
      case BpmToastType.info:
        return theme.colorScheme.primary;
      case BpmToastType.warning:
        return Colors.orange;
      case BpmToastType.error:
        return Colors.red;
    }
  }

  static IconData _iconFor(BpmToastType type) {
    switch (type) {
      case BpmToastType.success:
        return Icons.check_circle_rounded;
      case BpmToastType.info:
        return Icons.info_rounded;
      case BpmToastType.warning:
        return Icons.warning_rounded;
      case BpmToastType.error:
        return Icons.error_rounded;
    }
  }
}

class _BpmToastView extends StatefulWidget {
  const _BpmToastView({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    required this.actionText,
    required this.onAction,
    required this.dismissible,
    required this.onClose,
  });

  final String title;
  final String? message;
  final Color color;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool dismissible;
  final VoidCallback onClose;

  @override
  State<_BpmToastView> createState() => _BpmToastViewState();
}

class _BpmToastViewState extends State<_BpmToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width < 520 ? width - 24 : 520.0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: Dismissible(
                  key: const ValueKey('bpm_toast'),
                  direction: widget.dismissible
                      ? DismissDirection.up
                      : DismissDirection.none,
                  onDismissed: (_) => _close(),
                  child: _card(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final hasMsg =
        (widget.message != null && widget.message!.trim().isNotEmpty);
    final hasAction = (widget.actionText != null &&
        widget.actionText!.trim().isNotEmpty &&
        widget.onAction != null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.12),
              )
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconPill(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if (hasMsg) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.message!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withOpacity(0.72),
                              height: 1.2,
                            ),
                      ),
                    ],
                    if (hasAction) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: widget.color,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            widget.onAction?.call();
                            _close();
                          },
                          child: Text(
                            widget.actionText!,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: _close,
                icon: Icon(Icons.close_rounded,
                    color: Colors.black.withOpacity(0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconPill() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: widget.color.withOpacity(0.12),
        border: Border.all(color: widget.color.withOpacity(0.22)),
      ),
      child: Icon(widget.icon, color: widget.color),
    );
  }
}
