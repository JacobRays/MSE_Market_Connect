import 'package:flutter/foundation.dart';

class MainNavController {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);

  static void goTo(int newIndex) {
    index.value = newIndex;
  }
}
