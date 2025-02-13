class Word {
  final String word;
  final String category;
  final String hint;

  Word({required this.word, required this.category, required this.hint});

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'category': category,
      'hint': hint,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      word: map['word'],
      category: map['category'],
      hint: map['hint'],
    );
  }
}
