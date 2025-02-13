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
  String currentWord = '';
  String shuffledWord = '';
  String category = '';
  String hint = '';
  final dbHelper = DatabaseHelper.instance;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  RewardedAd? _rewardedAd;
  RewardedAd? _shuffleRewardedAd;
  InterstitialAd? _interstitialAd;
  final TextEditingController _guessController = TextEditingController();
  String? message;
  bool isCorrect = false;
  int unusedWords = 0;
  int correctAnswerCount = 0;
  bool hasShuffledCurrentWord = false;  // Track if current word has been shuffled

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _loadShuffleRewardedAd();
    _loadInterstitialAd();
    _createBannerAd();
    _initializeGame();
    _loadUnusedWordCount();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-9316751746869318/7771864609', // Updated hint reward ad
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Failed to load hint rewarded ad: ${error.message}');
        },
      ),
    );
  }

  void _loadShuffleRewardedAd() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-9316751746869318/6290801554', // Shuffle reward ad
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _shuffleRewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Failed to load shuffle rewarded ad: ${error.message}');
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-9316751746869318/7603883227', // Interstitial ad
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: ${error.message}');
        },
      ),
    );
  }

  void _createBannerAd() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: 'ca-app-pub-9316751746869318/6600124449', // Banner ad
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Try to load a new banner ad after failure
          Future.delayed(Duration(seconds: 30), () {
            if (mounted) {
              _createBannerAd();
            }
          });
        },
      ),
      request: AdRequest(),
    );

    _bannerAd?.load();
  }

  void _showShuffleRewardedAd(Function onRewarded) {
    if (_shuffleRewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shuffle reward ad is not ready yet. Please try again.')),
      );
      _loadShuffleRewardedAd();
      return;
    }

    _shuffleRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onRewarded();
        _loadShuffleRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadShuffleRewardedAd(); // Preload next ad
      },
    );

    _shuffleRewardedAd!.show(onUserEarnedReward: (_, reward) {
      // Don't call onRewarded here, wait for ad dismissal
    });
  }

  void _showHintRewardedAd(Function onRewarded) {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hint reward ad is not ready yet. Please try again.')),
      );
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onRewarded();
        _loadRewardedAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd(); // Preload next ad
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (_, reward) {
      // Don't call onRewarded here, wait for ad dismissal
    });
  }

  void _showInterstitialAd(Function onClosed) {
    if (_interstitialAd == null) {
      onClosed();
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onClosed();
        _loadInterstitialAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onClosed();
        _loadInterstitialAd(); // Preload next ad
      },
    );

    _interstitialAd!.show();
  }

  void _shuffleWord() async {
    if (!hasShuffledCurrentWord) {  // First shuffle for this word is free
      setState(() {
        shuffledWord = _shuffleString(currentWord);
        hasShuffledCurrentWord = true;  // Mark that we've used the free shuffle
      });
    } else {  // After first shuffle, show ad
      _showShuffleRewardedAd(() {
        setState(() {
          shuffledWord = _shuffleString(currentWord);
        });
      });
    }
  }

  void _showHint() async {
    bool canUseHint = await dbHelper.canUseHint();
    if (canUseHint) {
      _displayHint();
      await dbHelper.useHint();
    } else {
      _showHintRewardedAd(() async {
        _displayHint();
        await dbHelper.resetHint();
      });
    }
  }

  void _displayHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hint'),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _shuffleString(String str) {
    List<String> characters = str.split('');
    characters.shuffle();
    String newStr = characters.join();
    // Make sure we don't get the same word
    if (newStr == str && str.length > 1) {
      return _shuffleString(str);
    }
    return newStr;
  }

  void _initializeGame() async {
    final newWord = await dbHelper.getUnusedWord();
    if (newWord != null) {
      setState(() {
        currentWord = newWord.word;
        category = newWord.category;
        hint = newWord.hint;
        shuffledWord = _shuffleString(currentWord);
        hasShuffledCurrentWord = false;  // Reset shuffle flag for new word
        message = null;
        isCorrect = false;
      });
    } else {
      setState(() {
        currentWord = '';
        category = '';
        hint = '';
        shuffledWord = '';
        message = "You have answered everything, please come back for future updates.";
      });
    }
  }

  Future<void> _loadUnusedWordCount() async {
    final count = await dbHelper.getUnusedWordCount();
    setState(() {
      unusedWords = count;
    });
  }

  void _handleCorrectAnswer() async {
    setState(() {
      isCorrect = true;
      message = "Correct!";
      correctAnswerCount++;
    });

    await dbHelper.markWordAsUsed(currentWord);
    await _loadUnusedWordCount();

    if (correctAnswerCount % 2 == 0) {
      _showInterstitialAd(() {
        _showResultDialog();
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
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
                  _initializeGame();
                  _guessController.clear();
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
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game'),
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
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[50]!],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Guess the $category',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    shuffledWord.toUpperCase(),
                    style: TextStyle(fontSize: 36, letterSpacing: 8),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _shuffleWord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shuffle),
                            SizedBox(width: 4),
                            Text('Shuffle'),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showHint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lightbulb_outline),
                            SizedBox(width: 4),
                            Text('Hint'),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          _showInterstitialAd(() {
                            if (currentWord.isNotEmpty) {
                              _initializeGame();
                              _guessController.clear();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.skip_next),
                            SizedBox(width: 4),
                            Text('Skip'),
                          ],
                        ),
                      ),
                    ],
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
                        enabled: currentWord.isNotEmpty,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: currentWord.isNotEmpty ? () async {
                      if (_guessController.text.trim().toLowerCase() == currentWord.toLowerCase()) {
                        _handleCorrectAnswer();
                      } else {
                        setState(() {
                          isCorrect = false;
                          message = "Try again!";
                        });
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Submit'),
                      ],
                    ),
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
    _rewardedAd?.dispose();
    _shuffleRewardedAd?.dispose();
    _interstitialAd?.dispose();
    _guessController.dispose();
    super.dispose();
  }
}
