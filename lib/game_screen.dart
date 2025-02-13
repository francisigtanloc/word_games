import 'package:flutter/material.dart';
import 'dart:math';
import 'word.dart';
import 'database_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNewWord();
    _loadUnusedWordCount();
    _createBannerAd();
  }

  Future<void> _loadUnusedWordCount() async {
    final count = await DatabaseHelper.instance.getUnusedWordCount();
    setState(() {
      unusedWords = count;
    });
  }

  String _shuffleWord(String word) {
    List<String> characters = word.toUpperCase().split('');
    do {
      characters.shuffle();
    } while (characters.join() == word.toUpperCase());
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

  void _createBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit ID
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: AdRequest(),
    );

    _bannerAd?.load();
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
        title: Text(
          '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blue[700],
        actions: [
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Words Left: $unusedWords',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[50]!],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: currentWord == null ? Center(
                  child: Text(
                    message ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ) : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            if (currentWord != null) Text(
                              'Guess the ${currentWord!.category}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 24),
                            if (shuffledWord != null) Text(
                              shuffledWord!,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 12.0,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    if (showHint) Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.yellow[700]!),
                      ),
                      child: Text(
                        'Hint: ${currentWord?.hint}',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.brown[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _guessController,
                          decoration: InputDecoration(
                            labelText: 'Enter your guess',
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.blue[700]),
                            prefixIcon: Icon(Icons.edit, color: Colors.blue[700]),
                          ),
                          enabled: currentWord != null,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: currentWord != null ? () {
                            setState(() {
                              showHint = true;
                            });
                          } : null,
                          icon: Icon(Icons.lightbulb_outline),
                          label: Text('Show Hint'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: currentWord != null ? _checkAnswer : null,
                          icon: Icon(Icons.check_circle_outline),
                          label: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message != null) Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isCorrect ? Colors.green[700]! : Colors.red[700]!,
                          ),
                        ),
                        child: Text(
                          message!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCorrect ? Colors.green[700] : Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isAdLoaded)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _guessController.dispose();
    super.dispose();
  }
}
