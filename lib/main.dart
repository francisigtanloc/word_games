import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';
import 'word.dart';
import 'game_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Games',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _fetchDataAndNavigate(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Fetch and parse data
      final url = Uri.parse('https://francisigtanloc.github.io/word_games/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonString = response.body;
        // Find the JSON content between <pre> tags if it exists
        final preStart = jsonString.indexOf('<pre>');
        final preEnd = jsonString.indexOf('</pre>');
        if (preStart != -1 && preEnd != -1) {
          jsonString = jsonString.substring(preStart + 5, preEnd).trim();
        }

        try {
          List<dynamic> data = jsonDecode(jsonString);
          List<Word> words = [];
          
          // Process JSON data
          for (var item in data) {
            words.add(Word(
              word: item['word'],
              category: item['category'],
              hint: item['hint'],
            ));
          }

          // Insert only new words, preserving existing data
          await DatabaseHelper.instance.insertWords(words);

          // Pop the loading dialog
          Navigator.pop(context);
          // Navigate to game screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GameScreen()),
          );
        } catch (e) {
          print('JSON parsing error: $e');
          throw Exception('Failed to parse data format');
        }
      } else {
        throw Exception('Failed to load data from server');
      }
    } catch (e) {
      // Pop the loading dialog
      Navigator.pop(context);
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch data. Please check your internet connection and try again.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Word Games',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(5.0, 5.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              _buildButton(
                text: 'Play',
                onPressed: () => _fetchDataAndNavigate(context),
              ),
              const SizedBox(height: 20),
              _buildButton(
                text: 'Settings',
                onPressed: () {
                  // TODO: Implement settings functionality
                },
              ),
              const SizedBox(height: 20),
              _buildButton(
                text: 'Quit',
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.blue.shade900,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
