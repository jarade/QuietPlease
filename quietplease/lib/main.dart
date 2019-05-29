import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'dart:async';

void main() => runApp(MyApp());

const alarmAudioPath = "sound_alarm.mp3";
const softAudioPath = "sound_alarm.mp3";

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

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  StreamSubscription<NoiseEvent> _noiseSubscription;
  Noise _noise;

  static AudioCache player = new AudioCache();
  AudioPlayer audioPlayer = AudioPlayer();
  bool playingSound = false;

  String resultText = "Click mic icon to start";
  double _maxValue = 70;
  double _minValue = 20;

  MaterialColor _color = Colors.green;
  double _dbAvg = 0;
  double _dbTotal = 0;
  int _dbCount = 0;
  bool _isListening = false;
  int _dbMin = 999;
  int _dbMax = 0;

  @override
  void initState(){
    super.initState();
  }

  Future<void> setPlayer(AudioPlayer ap) async{
    this.audioPlayer = ap;
    audioPlayer.onPlayerCompletion.listen((event) {
      playingSound = false;
    });
  }

  /// onData - on change of the decibels
  /// returns: void
  /// params: NoiseEvent
  void onData(NoiseEvent e) {
    this.setState(() {
      this.resultText = "Currently: ${e.decibel} dB";

      this._dbCount++;
      this._dbTotal += e.decibel;
      this._dbAvg = this._dbTotal/this._dbCount;

      this._color = Colors.green;
      if(e.decibel >= this._maxValue){
        this._color = Colors.red;
        if(!playingSound) {
          player.play(alarmAudioPath).then((result){
            this.audioPlayer = result;
            audioPlayer.onPlayerCompletion.listen((event) {
              playingSound = false;
            });
            playingSound = true;
          });
        }
      }
      if(e.decibel <= this._minValue){
        this._color = Colors.blue;
        if(!playingSound) {
          player.play(softAudioPath).then((result){
            this.audioPlayer = result;
            audioPlayer.onPlayerCompletion.listen((event) {
              playingSound = false;
            });
            playingSound = true;
          });
        }
      }

      if(e.decibel > this._dbMax){
        this._dbMax = e.decibel;
      }

      // Ignore the first run of this function since it will be 0
      if(e.decibel < this._dbMin && this._isListening){
        this._dbMin = e.decibel;
      }

      if (!this._isListening) {
        this._isListening = true;
      }
    });
  }

  void startListening() async {
    try {
      _noise = new Noise(500); // New observation every 500 ms
      _noiseSubscription = _noise.noiseStream.listen(onData);

      resultText = "Currently: 0";
      this._dbCount = 0;
      this._dbTotal = 0;
      this._dbMax = 0;
      this._dbMin = 999;
      this._dbAvg = 0;
    } on NoiseMeterException catch (exception) {
      print(exception);
    }
  }

  void stopListening() async {
    try {
      if(audioPlayer != null){
        audioPlayer.stop();
        playingSound = false;
      }
      if (_noiseSubscription != null) {
        _noiseSubscription.cancel();
        _noiseSubscription = null;
      }
      this.setState(() {
        this._isListening = false;
        this._color = Colors.green;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  Expanded textComponent(String message){
    return new Expanded(
        child: Text(
          message,
          style: TextStyle(fontSize: 18.0)
        )
    );
  }

  Flexible fieldComponent(String label, Function func){
    return new Flexible(
        child: TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: label,
            fillColor: Colors.white,
            filled: true,
          ),
          keyboardType: TextInputType.number,
          maxLength: 3,
          onSubmitted: func,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _color
      ),
      body: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 12.0
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width - 24,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent[100],
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 12.0,
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                            Text(
                              resultText,
                              style: TextStyle(fontSize: 24.0),
                            ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          fieldComponent("What is the quiet threshold?",
                              (value) => setState(() => this._minValue = double.parse(value)  )
                          ),
                         ],
                      ),
                      Row(
                         children: <Widget>[
                            fieldComponent("What is the ear bleeading threshold?",
                                (value) => setState(() => this._maxValue = double.parse(value)  )
                            ),
                         ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          textComponent('Your overall decibel average:'),
                          textComponent(this._dbAvg.toStringAsFixed(2)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          textComponent('The lowest decibel set was:'),
                          textComponent("$_dbMin"),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          textComponent('The highest decibel set was:'),
                          textComponent("$_dbMax"),
                        ],
                      ),
                    ]
                  )
                ),
                Container(
                    width: MediaQuery.of(context).size.width -24,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent[100],
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    padding:
                    EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                ),
              ],
            ),
          ),
        ]
      ),
      backgroundColor: _color
    );
  }
}
