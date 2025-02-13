import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
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
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await fetchDataAndStore();
      // Pop the loading dialog
      Navigator.pop(context);
      // Navigate to game screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameScreen()),
      );
    } catch (e) {
      // Pop the loading dialog
      Navigator.pop(context);
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to fetch data: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
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

Future<void> fetchDataAndStore() async {
  try {
    final url = Uri.parse('https://francisigtanloc.github.io/word_games/');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var document = parser.parse(response.body);
      var preElement = document.querySelector('pre');
      
      if (preElement != null) {
        String jsonString = preElement.text.trim();
        
        try {
          List<dynamic> data = jsonDecode(jsonString);
          
          // Clear existing data
          await DatabaseHelper.instance.clearTable();

          // Insert new data
          for (var item in data) {
            Word word = Word(
              word: item['word'],
              category: item['category'],
              hint: item['hint'],
            );
            await DatabaseHelper.instance.insert(word);
          }
        } catch (e) {
          print('JSON decode error: $e');
          throw Exception('Failed to parse JSON data: $e');
        }
      } else {
        throw Exception('Could not find data element in the response');
      }
    } else {
      throw Exception('Failed to fetch data: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in fetchDataAndStore: $e');
    throw Exception('Error fetching or storing data: $e');
  }
}
