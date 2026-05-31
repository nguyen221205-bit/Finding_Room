import 'dart:math';

class IdGenerator {
  static final Random _random = Random.secure();

  static String generate(String prefix) {
    final int timePart = DateTime.now().microsecondsSinceEpoch;
    final String randomPart = List<int>.generate(
      8,
      (_) => _random.nextInt(256),
    ).map((int value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${prefix}_${timePart}_$randomPart';
  }
}
