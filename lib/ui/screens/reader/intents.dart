import 'package:flutter/widgets.dart';

abstract class PageDown {
  void onPageDownRequested(BuildContext context);
}

class PageDownIntent extends Intent {
  const PageDownIntent();
}

class PageDownAction extends Action<PageDownIntent> {
  PageDownAction(this.pageDown, this.context);

  final PageDown pageDown;
  final BuildContext context;

  @override
  void invoke(covariant PageDownIntent intent) =>
      pageDown.onPageDownRequested(context);
}

abstract class PageUp {
  void onPageUpRequested(BuildContext context);
}

class PageUpIntent extends Intent {
  const PageUpIntent();
}

class PageUpAction extends Action<PageUpIntent> {
  PageUpAction(this.pageUp, this.context);

  final PageUp pageUp;
  final BuildContext context;

  @override
  void invoke(covariant PageUpIntent intent) =>
      pageUp.onPageUpRequested(context);
}


abstract class ScrollUp {
  void onScrollUpRequested(BuildContext context);
}

class ScrollUpIntent extends Intent {
  const ScrollUpIntent();
}

class ScrollUpAction extends Action<ScrollUpIntent> {
  ScrollUpAction(this.pageUp, this.context);

  final ScrollUp pageUp;
  final BuildContext context;

  @override
  void invoke(covariant ScrollUpIntent intent) =>
      pageUp.onScrollUpRequested(context);
}
abstract class ScrollDown {
  void onScrollDownRequested(BuildContext context);
}

class ScrollDownIntent extends Intent {
  const ScrollDownIntent();
}

class ScrollDownAction extends Action<ScrollDownIntent> {
  ScrollDownAction(this.pageDown, this.context);

  final ScrollDown pageDown;
  final BuildContext context;

  @override
  void invoke(covariant ScrollDownIntent intent) =>
      pageDown.onScrollDownRequested(context);
}