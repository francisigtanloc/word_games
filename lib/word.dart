class Word {
  final String word;
  final String category;
  final String hint;
  bool used;

  Word({
    required this.word, 
    required this.category, 
    required this.hint,
    this.used = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'category': category,
      'hint': hint,
      'used': used ? 1 : 0,  // SQLite doesn't have boolean, so we use 1 and 0
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      word: map['word'],
      category: map['category'],
      hint: map['hint'],
      used: map['used'] == 1,
    );
  }
}
