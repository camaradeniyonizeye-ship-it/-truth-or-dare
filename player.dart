class Player {
  final String id;
  final String name;
  final String gender;
  int score;
  bool hasCompletedTurn;

  Player({
    required this.id,
    required this.name,
    required this.gender,
    this.score = 0,
    this.hasCompletedTurn = false,
  });

  Player copyWith({
    String? id,
    String? name,
    String? gender,
    int? score,
    bool? hasCompletedTurn,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      score: score ?? this.score,
      hasCompletedTurn: hasCompletedTurn ?? this.hasCompletedTurn,
    );
  }
}
