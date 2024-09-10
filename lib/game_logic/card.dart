enum CardType { number, sylop, imposter }

class SabbacCard {
  final int value;
  final CardType type;

  SabbacCard.number(this.value) : type = CardType.number;
  SabbacCard.sylop()
      : value = -1,
        type = CardType.sylop;
  SabbacCard.imposter()
      : value = -1,
        type = CardType.imposter;

  @override
  String toString() {
    switch (type) {
      case CardType.number:
        return value.toString();
      case CardType.sylop:
        return 'Sylop';
      case CardType.imposter:
        return 'Imposter';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SabbacCard && other.value == value && other.type == type;
  }

  @override
  int get hashCode => value.hashCode ^ type.hashCode;

  SabbacCard copyWith({
    int? value,
    CardType? type,
  }) {
    return SabbacCard(
      value ?? this.value,
      type ?? this.type,
    );
  }

  SabbacCard(
    this.value,
    this.type,
  );
}
