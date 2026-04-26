class SheetMusic {
  final int? id;
  final String title;
  final String composer;
  final int bpm;
  final String imagePath;
  final DateTime createdAt;

  SheetMusic({
    this.id,
    required this.title,
    required this.composer,
    required this.bpm,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'composer': composer,
      'bpm': bpm,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SheetMusic.fromMap(Map<String, dynamic> map) {
    return SheetMusic(
      id: map['id'] as int?,
      title: map['title'] as String,
      composer: map['composer'] as String,
      bpm: map['bpm'] as int,
      imagePath: map['image_path'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SheetMusic copyWith({
    int? id,
    String? title,
    String? composer,
    int? bpm,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return SheetMusic(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      bpm: bpm ?? this.bpm,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SheetMusic(id: $id, title: $title, bpm: $bpm)';
}
