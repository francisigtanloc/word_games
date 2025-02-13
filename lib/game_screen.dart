import 'package:flutter/material.dart';
import 'dart:math';
import 'word.dart';
import 'database_helper.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Word? currentWord;
  String? shuffledWord;
  String? message;
  bool isCorrect = false;
  bool showHint = false;
  int unusedWords = 0;
  final TextEditingController _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNewWord();
    _loadUnusedWordCount();
  }

  Future<void> _loadUnusedWordCount() async {
    final count = await DatabaseHelper.instance.getUnusedWordCount();
    setState(() {
      unusedWords = count;
    });
  }

  String _shuffleWord(String word) {
    List<String> characters = word.split('');
    do {
      characters.shuffle();
    } while (characters.join() == word);
    return characters.join();
  }

  Future<void> _loadNewWord() async {
    final newWord = await DatabaseHelper.instance.getUnusedWord();
    if (newWord != null) {
      setState(() {
        currentWord = newWord;
        shuffledWord = _shuffleWord(newWord.word);
        message = null;
        isCorrect = false;
        showHint = false;
        _guessController.clear();
      });
    } else {
      setState(() {
        currentWord = null;
        shuffledWord = null;
        message = "You have answered everything, please come back for future updates.";
      });
    }
    _loadUnusedWordCount();
  }

  void _checkAnswer() async {
    if (currentWord != null && _guessController.text.trim().toLowerCase() == currentWord!.word.toLowerCase()) {
      setState(() {
        isCorrect = true;
      });
      await DatabaseHelper.instance.markWordAsUsed(currentWord!.word);
      await _loadUnusedWordCount();
      
      if (unusedWords > 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Correct!'),
              content: Text('Great job! You got it right!'),
              actions: <Widget>[
                TextButton(
                  child: Text('Next Word'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadNewWord();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Congratulations!'),
              content: Text('You have completed all available words! Please come back for future updates.'),
              actions: <Widget>[
                TextButton(
                  child: Text('Back to Main Menu'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Return to main screen
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      setState(() {
        message = "Try again!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Word Guessing Game'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                'Words Left: $unusedWords',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: currentWord == null ? Center(
          child: Text(
            message ?? '',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ) : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (shuffledWord != null) Text(
              shuffledWord!,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            if (showHint) Text(
              'Hint: ${currentWord?.hint}',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _guessController,
              decoration: InputDecoration(
                labelText: 'Enter your guess',
                border: OutlineInputBorder(),
              ),
              enabled: currentWord != null,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: currentWord != null ? _checkAnswer : null,
                  child: Text('Submit'),
                ),
                ElevatedButton(
                  onPressed: currentWord != null ? () {
                    setState(() {
                      showHint = true;
                    });
                  } : null,
                  child: Text('Show Hint'),
                ),
              ],
            ),
            if (message != null) Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                message!,
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }
}
