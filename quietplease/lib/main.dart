import 'package:flutter/material.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'package:willow_flutter_sound/willow_flutter_sound.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  static const TITLE = "Quiet Please";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: TITLE,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: TITLE),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SpeechRecognition _speechRecognition;
  FlutterSound flutterSound;
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;

  double _dbLevel;
  bool _isAvailable = false;
  bool _isListening = false;
  int _counter = 0;
  String resultText = "";

  @override
  void initState(){
    super.initState();
    initSpeechRecognizer();
    initFlutterSound();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void initSpeechRecognizer(){
    _speechRecognition = SpeechRecognition();

    _speechRecognition.setAvailabilityHandler(
        (bool result) => setState(() => _isAvailable = result),
    );

    _speechRecognition.setRecognitionStartedHandler(
        () => setState(() => _isListening = true),
    );

    _speechRecognition.setRecognitionResultHandler(
        (String speech) => setState(() => resultText = speech),
    );

    _speechRecognition.setRecognitionCompleteHandler(
        () => setState(()=> _isListening = false),
    );

    _speechRecognition.activate().then(
        (result) => setState(()=> _isAvailable = result),
    );
  }

  void initFlutterSound(){
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
  }


  void startListening() async{
    resultText = "playing";
    _speechRecognition.listen(locale: "en_US").then(
            (result) => print('listening: $result'));
    try {
      String path = await flutterSound.startRecorder(null);
        _dbPeakSubscription = flutterSound.onRecorderDbPeakChanged.listen(
              (value) {
              print("got update -> $value");
              setState(() {
                this.resultText += value.toString();
              });
            });
       /* done in init speech recognizer
      this.setState(() {
        this._isListening = true;
      });*/

    }catch(err){
      print('startRecorder error: $err');
    }
  }

  void stopListening() async{
    _speechRecognition.stop().then(
          (result) => setState(() => _isListening = result),
    );

    resultText = "stopped";

    try{
      String result = await flutterSound.stopRecorder();
    } catch (err){
      print('stopRecorder error: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FloatingActionButton(
                  child: Icon(Icons.cancel),
                  mini: true,
                  backgroundColor: Colors.deepOrange,
                  onPressed: (){
                    if(_isListening){
                      _speechRecognition.cancel().then(
                          (result) => setState(() {
                            _isListening = result;
                            resultText = "";
                          }),
                      );
                    }
                  },
                ),
                FloatingActionButton(
                  child: Icon(Icons.mic),
                  backgroundColor: Colors.pink,
                  onPressed: (){
                    if(_isAvailable && !_isListening){
                      this.startListening();
                    }
                  },
                ),
                FloatingActionButton(
                  child: Icon(Icons.stop),
                  mini: true,
                  backgroundColor: Colors.deepPurple,
                  onPressed: (){
                    if(_isListening){
                      this.stopListening();
                    }
                  },
                ),
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.cyanAccent[100],
                borderRadius: BorderRadius.circular(6.0),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: Text(
                resultText,
                style: TextStyle(fontSize: 24.0),
              )
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
