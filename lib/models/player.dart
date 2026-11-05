class Player {
  final String id;
  final String name;
  final String gender; // 'male' or 'female'
  int score;
  bool hasCompletedTurn;
  String? lastChosenType; // Tracks 'truth' or 'dare' from their previous turn

  Player({
    required this.id,
    required this.name,
    required this.gender,
    this.score = 0,
    this.hasCompletedTurn = false,
    this.lastChosenType,
  });

  // Convert player object (Name + Gender) to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender,
      };

  // Factory constructor to restore player from JSON
  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] ?? '',
        gender: json['gender'] ?? 'female',
      );
}
