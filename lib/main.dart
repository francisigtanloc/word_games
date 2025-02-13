import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'database_helper.dart';
import 'word.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

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
                onPressed: () {
                  // TODO: Implement play functionality
                },
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
  final url = Uri.parse('https://francisigtanloc.github.io/word_games/');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    var document = parser.parse(response.body);
    dom.Element? preElement = document.querySelector('pre');
    if (preElement != null) {
      String jsonString = preElement.text;
      // Remove any leading/trailing whitespace or newlines
      jsonString = jsonString.trim();

      // Decode the JSON string
      List<dynamic> data = jsonDecode(jsonString);

      // Store the data in the database
      for (var item in data) {
        Word word = Word(
          word: item['word'],
          category: item['category'],
          hint: item['hint'],
        );
        await DatabaseHelper.instance.insert(word);
      }
    } else {
      print('Could not find <pre> element');
    }
  } else {
    print('Failed to fetch data: ${response.statusCode}');
  }
}
