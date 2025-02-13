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
  int totalWords = 0;
  final TextEditingController _guessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNewWord();
    _loadWordCount();
  }

  Future<void> _loadWordCount() async {
    final count = await DatabaseHelper.instance.getWordCount();
    setState(() {
      totalWords = count;
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
      await DatabaseHelper.instance.markWordAsUsed(newWord.word);
    } else {
      setState(() {
        message = "No more words available!";
      });
    }
  }

  void _checkAnswer() async {
    if (currentWord != null && _guessController.text.trim().toLowerCase() == currentWord!.word.toLowerCase()) {
      setState(() {
        isCorrect = true;
      });
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
                'Words: $totalWords',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.blue.shade200],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Category: ${currentWord?.category ?? ""}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                shuffledWord ?? "",
                style: TextStyle(fontSize: 36, letterSpacing: 4),
              ),
              SizedBox(height: 20),
              if (showHint)
                Text(
                  'Hint: ${currentWord?.hint ?? ""}',
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
              SizedBox(height: 20),
              TextField(
                controller: _guessController,
                decoration: InputDecoration(
                  labelText: 'Enter your guess',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showHint = true;
                      });
                    },
                    child: Text('Show Hint'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _checkAnswer,
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
              if (message != null)
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    message!,
                    style: TextStyle(
                      fontSize: 18,
                      color: message == "Try again!" ? Colors.red : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
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
