// Експеримент: що буде, якщо перевизначити == і не перевизначити hashCode.
// ignore_for_file: hash_and_equals, public_member_api_docs

class WithBoth {
  WithBoth(this.key);
  final String key;

  @override
  bool operator ==(Object other) => other is WithBoth && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

class OnlyEquals {
  OnlyEquals(this.key);
  final String key;

  @override
  bool operator ==(Object other) => other is OnlyEquals && key == other.key;
}

void main() {
  final good = {WithBoth('Dart'), WithBoth('Dart')};
  final bad = {OnlyEquals('Dart'), OnlyEquals('Dart')};

  print('== і hashCode: розмір Set = ${good.length}');
  print('лише ==:      розмір Set = ${bad.length}');
  print(
    'contains для лише ==: '
    '${bad.contains(OnlyEquals('Dart'))}',
  );
}
