import 'package:flutter/material.dart';
import 'package:expressions/expressions.dart';
import 'dart:async';
import 'dart:math'; 

void main() {
  runApp(const MyApp());
}

final functions = [
  '1','2','3','/',
  '4','5','6','*',
  '7','8','9','-',
  '.','0','+','=', 
  //'(',')'
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Calculator', home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<String> _results = [];
  String displayedText = "";

  static const _evaluator = ExpressionEvaluator();
  static String parse(expression) {
    return _evaluator.eval(Expression.parse(expression), {}).toString();
  }

  void _computeResult() {
    setState(() {
      try {
        displayedText = parse(displayedText);
        if (displayedText == "null") throw Error;

        _results.add(displayedText);
      } catch (_) {
        displayedText = "Error";
      }
    });
  }

  static final operands = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '(', ')'];
  void _handlePress(String key) {
    if (key == '=') {
      _computeResult();
    } else if (key == 'Backspace') {
      _handleBackspace();
    } else {
      if (operands.contains(key) ||
          displayedText.isNotEmpty &&
          operands.contains(displayedText.characters.last)) {
        setState(() {
          if (displayedText == "Error") displayedText = ""; 
          displayedText += key;
        });
      }
    }
  }

  void _handleBackspace() {
    setState(() {
      if (displayedText == 'Error') {
        displayedText = "";
      } else {
        var len = displayedText.length;
        displayedText = displayedText.substring(0, len == 0 ? 0 : len - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      appBar: MyAppBar(),
      endDrawer: PrevResDrawer(
        results: _results,
        onInsertPressed: (res) => setState(() {
          if (displayedText == "Error") displayedText = ""; 
          displayedText += res;
        })),
      body: Center(
        child: Calculator(
          displayedText: displayedText,
          handlePress: _handlePress,
        ),
      )
    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({
    Key? key,
  }) : super(key: key);
  @override
  final preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Calculator'), actions: [
      IconButton(
        tooltip: "Open Previous Calculations",
        icon: const Icon(Icons.list),
        onPressed: () => Scaffold.of(context).openEndDrawer(),
      )
    ]);
  }
}

class PrevResDrawer extends StatelessWidget {
  final List<String> results;
  final void Function(String) onInsertPressed;
  const PrevResDrawer(
      {Key? key, required this.results, required this.onInsertPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      semanticLabel: "Open Previous Calculations",
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(children: [
          SizedBox(
            height: 125,
            child: DrawerHeader(
              child: Text('Previous Calculations', 
                style: Theme.of(context).textTheme.headline4),
            ),
          ),
          ...results
              .map((result) {
                return ListTile(
                  title: Text(result, 
                    style: const TextStyle(fontSize: 20)),
                  trailing: TextButton(
                      child: const Text('Insert'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onInsertPressed(result);
                      }),
                );
              })
              .toList()
              .reversed,
        ]),
      ),
    );
  }
}

class Calculator extends StatelessWidget {
  final String displayedText;
  final void Function(String) handlePress;
  const Calculator(
      {Key? key, required this.displayedText, required this.handlePress})
      : super(key: key);


  static const maxTileSide = 150.0; 
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size; 
    var appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0;
    var tileSide = min(maxTileSide, min(screenSize.width/4, (screenSize.height-appBarHeight)/4.5));

    return Container(
      constraints: BoxConstraints(maxWidth: tileSide*4), 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, 
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0), 
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(displayedText, 
                      style: TextStyle(
                        overflow: TextOverflow.clip,
                        fontSize: tileSide*0.4, 
                        color: Colors.grey[800], 
                      )
                    )
                  ),
                  BackspaceButton(
                    iconSize: tileSide * 0.4, 
                    onTriggered: () => handlePress('Backspace'),
                  ),
                ]
              ),
            )
          ),
          GridView.count(
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: tileSide), 
            crossAxisCount: 4,
            children: functions
                .map((tile) => SizedBox(
                  width: tileSide/2, height: tileSide/2, 
                  child: Card( 
                    margin: const EdgeInsets.all(5.0), 
                    child: TextButton(
                      child: FittedBox(
                          fit: BoxFit.fitHeight, 
                          child: Text(tile, style: 
                            TextStyle(
                              fontSize: tileSide, 
                              fontFamily: 'monospace', 
                            )
                          )
                        ),
                      onPressed: () => handlePress(tile),
                    ),
                    color: Colors.blueGrey[200],
                  ),
                ))
                .toList()),
        ],
      ),
    );
  }
}

class BackspaceButton extends StatefulWidget {
  final void Function() onTriggered;
  final double iconSize; 
  const BackspaceButton({Key? key, required this.onTriggered, this.iconSize=24.0})
      : super(key: key);

  @override
  State<BackspaceButton> createState() => _BackspaceButtonState();
}

class _BackspaceButtonState extends State<BackspaceButton> {
  Timer? _timer;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (_) {
        widget.onTriggered();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
          widget.onTriggered();
        });
      },
      onTap: () => _timer?.cancel(),
      onTapCancel: () => _timer?.cancel(),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: EdgeInsets.all(widget.iconSize/2),
        child: Icon(Icons.backspace, size: widget.iconSize),
      ));
  }
}
