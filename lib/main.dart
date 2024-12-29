import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'chatCOC',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController _scrollController = ScrollController();
  TextEditingController _promptController = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  FocusNode _focusNode = FocusNode();
  String _response = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _setFocus() {
    FocusScope.of(context).requestFocus(_focusNode);
  }

  Future<void> callGPT4AllAPI(String prompt) async {
    setState(() {
      _response = 'Generating response...';
      chatHistory.add({'role': 'user', 'content': prompt});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      _promptController.clear();
    });

    final url = Uri.parse('http://localhost:4891/v1/chat/completions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'Meta-Llama-3-8B-Instruct.Q4_0.gguf',
      'messages': chatHistory,
      'max_tokens': 50000,
      'temperature': 0.28,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _response = data['choices'][0]['message']['content'];
          chatHistory.add({'role': 'assistant', 'content': _response});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          _setFocus();
        });
      } else {
        throw Exception('Failed to generate response');
      }
    } catch (error) {
      print('Error calling GPT4All API: $error');
      setState(() {
        _response = 'An error occurred while generating the response.';
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: chatHistory.length,
                itemBuilder: (context, index) {
                  final isUser = chatHistory[index]['role'] == 'user';
                  double widthMultiplier = isUser ? .7 : .9;
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: _screenWidth * widthMultiplier,
                      child: Card(
                        color: isUser ? Colors.green[100] : Colors.grey[200],
                        child: ListTile(
                          title: Text(
                            chatHistory[index]['content']!,
                            textAlign:
                                isUser ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _promptController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Enter your prompt here...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    callGPT4AllAPI(_promptController.text);
                  },
                  icon: Icon(Icons.send),
                ),
              ),
              onSubmitted: (value) => callGPT4AllAPI(value),
            ),
          ],
        ),
      ),
    );
  }
}
