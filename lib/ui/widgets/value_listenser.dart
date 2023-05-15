import 'package:flutter/material.dart';

class ValueListener<T> extends StatefulWidget {
  final ValueNotifier<T> notifier;
  final Widget child;
  final void Function(T)? onChanged;

  const ValueListener({
    Key? key,
    required this.notifier,
    required this.child,
    this.onChanged,
  }) : super(key: key);

  @override
  _ValueListenerState<T> createState() => _ValueListenerState<T>();
}

class _ValueListenerState<T> extends State<ValueListener<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.notifier.value;
    widget.notifier.addListener(_handleValueChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_handleValueChanged);
    super.dispose();
  }

  void _handleValueChanged() {
    final newValue = widget.notifier.value;
    if (newValue != _value) {
      _value = newValue;
      widget.onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
