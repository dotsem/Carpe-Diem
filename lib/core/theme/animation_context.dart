import 'package:flutter/widgets.dart';

extension AnimationContext on BuildContext {
  bool get animationsEnabled => !MediaQuery.disableAnimationsOf(this);
}
