import 'dart:async';
import 'package:flutter/material.dart';

/// A utility for debouncing button clicks to prevent duplicate actions.
///
/// Use this to prevent rapid clicks from triggering multiple API calls,
/// especially for critical actions like event registration or payments.
///
/// Example usage with StatefulWidget:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with ActionDebounceMixin {
///   void _onRegisterTapped() {
///     debounceAction('register', () async {
///       await registerForEvent();
///     });
///   }
/// }
/// ```
mixin ActionDebounceMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _inProgressActions = {};

  /// Execute an action with debouncing.
  ///
  /// If an action with the same [actionKey] is already in progress,
  /// this call will be ignored.
  ///
  /// [actionKey] - A unique identifier for this action (e.g., 'register', 'withdraw')
  /// [action] - The async action to execute
  /// [onError] - Optional error handler
  Future<void> debounceAction(
    String actionKey,
    Future<void> Function() action, {
    void Function(dynamic error, StackTrace stackTrace)? onError,
  }) async {
    if (_inProgressActions.contains(actionKey)) {
      return;
    }

    _inProgressActions.add(actionKey);

    try {
      await action();
    } catch (e, st) {
      if (onError != null) {
        onError(e, st);
      } else {
        rethrow;
      }
    } finally {
      _inProgressActions.remove(actionKey);
    }
  }

  /// Check if an action is currently in progress.
  bool isActionInProgress(String actionKey) {
    return _inProgressActions.contains(actionKey);
  }

  @override
  void dispose() {
    _inProgressActions.clear();
    super.dispose();
  }
}

/// A standalone debouncer for non-widget contexts.
///
/// Useful for services or utilities that need debouncing without
/// the widget mixin.
///
/// Example:
/// ```dart
/// final debouncer = Debouncer(milliseconds: 500);
///
/// void onSearchChanged(String query) {
///   debouncer.run(() {
///     performSearch(query);
///   });
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 300});

  /// Run the action after the debounce delay.
  ///
  /// If called again before the delay expires, the previous call is cancelled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of the debouncer.
  void dispose() {
    cancel();
  }
}

/// A button wrapper that prevents double-clicks.
///
/// Use this to wrap any button that triggers an async action:
/// ```dart
/// DebouncedButton(
///   onPressed: () async {
///     await saveData();
///   },
///   child: Text('Save'),
/// )
/// ```
class DebouncedButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const DebouncedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (widget.enabled && !_isLoading) ? _handlePress : null,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}

/// A text button wrapper that prevents double-clicks.
class DebouncedTextButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const DebouncedTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  });

  @override
  State<DebouncedTextButton> createState() => _DebouncedTextButtonState();
}

class _DebouncedTextButtonState extends State<DebouncedTextButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (widget.enabled && !_isLoading) ? _handlePress : null,
      style: widget.style,
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child,
    );
  }
}
