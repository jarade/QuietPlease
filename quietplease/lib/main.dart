import 'package:flutter/material.dart';
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

const alarmAudioPath = "sound_alarm.mp3";

class _MyHomePageState extends State<MyHomePage> {
  FlutterSound flutterSound;
  StreamSubscription _dbPeakSubscription;

  double _dbAvg = 0;
  double _dbTotal = 0;
  int _dbCount = 0;
  bool _isListening = false;
  bool _isTooLoud = false;
  int _counter = 0;
  MaterialColor _color = Colors.green;
  String resultText = "";

  double _dbMin = 999;
  double _dbMax = 0;
  double _dbCountCheck = 0;
  double _dbAvgCheck = 0;
  double _dbTotalCheck = 0;
  double _dbAlertValue = 60;
  double _dbMinAlertValue = 30;

  @override
  void initState(){
    super.initState();
    initFlutterSound();
  }

  void _incrementCounter() {
    setState(() {
      this._counter++;
    });
  }


  void initFlutterSound(){
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.1);
    flutterSound.setDbPeakLevelUpdate(0.03);
    flutterSound.setDbLevelEnabled(true);
  }

  void startListening() async{
    resultText = "Currently: ";
    this._dbCount = 0;
    this._dbTotal = 0;
    this._counter = 0;
    this._dbCountCheck = 0;
    this._dbTotalCheck = 0;
    this._dbAvgCheck = 0;
    this._dbMax = 0;
    this._dbMin = 999;
    this._dbAvg = 0;

    try {
      this._isListening = true;
      String path = await flutterSound.startRecorder(null);
      _dbPeakSubscription = flutterSound.onRecorderDbPeakChanged.listen(
              (value) {
                this._dbCount++;
                this._dbTotal += value;

                //this._dbAvg = this._dbTotal/this._dbCount;


                this._dbTotalCheck += value;
                // messed with decibel calculations to get a more lifelike result. still needs work
                // Theory have a larger subset average so that it gives more accurate readings instead of 120 here 5 there sort of thing. more consistent to be able to play sound
                setState(() {
                  String val = value.toStringAsFixed(2);
                  this.resultText = "Currently: $val";
                  this._dbCountCheck++;

                  if(this._dbCountCheck >= 25){
                    this._dbAvgCheck += this._dbTotalCheck / this._dbCountCheck;
                    // Update values for alert message condition

                    this._dbAvg = (this._dbAvg + this._dbAvgCheck)/2;
                    if(value >= this._dbAlertValue){
                      // TODO add sound for too loud
                      // path = "sound_alarm.mp3"s
                      this._isTooLoud = true;
                      setState((){
                        this._color=Colors.red;
                      });
                    }

                    if(value < this._dbMinAlertValue){
                      // TODO add sound for too soft
                      this._isTooLoud = false;
                      setState((){
                        this._color=Colors.green;
                      });
                    }

                    if(this._dbAvgCheck > this._dbMax){
                      this._dbMax = this._dbAvgCheck;
                    }

                    if(this._dbAvgCheck < this._dbMin){
                      this._dbMin = this._dbAvgCheck;
                    }

                    this._dbCountCheck = 0;
                    this._dbTotalCheck = 0;
                    this._dbAvgCheck = 0;
                  }
                }
              );
            }
      );
      print(path);
    }catch(err){
      print('startRecorder error: $err');
    }
  }

  void stopListening() async{
    setState(() {
      this.resultText = "stopped, avg: " + this._dbAvg.toStringAsFixed(2);
    });
    this._isListening = false;
    try{
      String result = await flutterSound.stopRecorder();


      if(_dbPeakSubscription != null){
        _dbPeakSubscription.cancel();
        _dbPeakSubscription = null;
      }
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
        title: Text(widget.title),
        backgroundColor: _isTooLoud? Colors.red: Colors.green
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
                  child: Icon(Icons.mic),
                  backgroundColor: Colors.pink,
                  onPressed: (){
                    if(!this._isListening){
                      this.startListening();
                    }
                  },
                ),
                FloatingActionButton(
                  child: Icon(Icons.stop),
                  backgroundColor: Colors.deepPurple,
                  onPressed: () {
                    if (this._isListening) {
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
                  'Your overall decibel average:',
                ),
                Text(
                  this._dbAvg.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'The lowest decibel set was:',
                ),
                Text(
                  this._dbMin.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'The highest decibel set was:',
                ),
                Text(
                  this._dbMax.toStringAsFixed(2),
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
      backgroundColor: _color
    );
  }
}
