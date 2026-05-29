import 'dart:math';

class UuidV7 {
  UuidV7({Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;

  String generate() {
    final timestamp = _now().toUtc().millisecondsSinceEpoch;
    final timeHex = timestamp.toRadixString(16).padLeft(12, '0');
    final randomA = _random.nextInt(0x1000);
    final randomB = _random62Bits();

    final versionAndRandom = (0x7000 | randomA)
        .toRadixString(16)
        .padLeft(4, '0');
    final variantAndRandom = (0x8000 | (randomB >> 48))
        .toRadixString(16)
        .padLeft(4, '0');
    final tail = (randomB & 0x0000ffffffffffff)
        .toRadixString(16)
        .padLeft(12, '0');

    return '${timeHex.substring(0, 8)}-'
        '${timeHex.substring(8, 12)}-'
        '$versionAndRandom-'
        '$variantAndRandom-'
        '$tail';
  }

  int _random62Bits() {
    final high = _random.nextInt(1 << 30);
    final low = _random.nextInt(1 << 32);
    return (high << 32) | low;
  }
}
