import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:sensors/sensors.dart';

import 'package:beatim3/musicselectfunction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'musicdata.dart';

List<int> _playlist = [0,1,2,3,4,5,6,7,8,9,10];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ),
  );
  runApp(YoutubePlayerDemoApp());
}

/// Creates [YoutubePlayerDemoApp] widget.
class YoutubePlayerDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BEATIM',
      theme: ThemeData(
        fontFamily: 'Noto Sans',
        primarySwatch: Colors.deepOrange,
        appBarTheme: const AppBarTheme(
          color: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

/// Homepage
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late YoutubePlayerController _controller;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  double _playbackBPM = 160.0;
  bool _isPlayerReady = false;

  String _genre = "free";
  String _artist = "free";

  int lapTime = 0, oldLapTime = 0, lapTimeLim = 100, nowTime = 0, oldTime = 0, counter = 0;
  double dGyroPre = 0, dGyroNow = 0, gain = 0.84, acceleHurdol = 3, bpm = 0;
  List<double> accele = [0];
  List<double> acceleFiltered = [0,0];
  List<int> _intervals = List.filled(15, 0);
  List<double> gyro = [0,0];


  List<String> _ids = List.generate(_playlist.length, (index) => musics[_playlist[index]]['youtubeid']);

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: _ids.first,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;

    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        
        acceleFiltered[1] = acceleFiltered[0];
        accele[0] = math.pow((math.pow(event.x,2)+math.pow(event.y,2)),0.5).toDouble();

        //RCローパスフィルタ
        acceleFiltered[0] = gain*acceleFiltered[1] + (1-gain)*accele[0];
      });
    }); //get the sensor data and set then to the data types

    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        gyro[1] = gyro[0];
        gyro[0] = event.z;

        oldTime = nowTime;
        nowTime = DateTime.now().millisecondsSinceEpoch; //ストップウォッチ動かしてからの時間

        //角速度の正負が入れ替わる点（腕の振りの端っこ）を取得
        if (gyro[0]*gyro[1] < 0  &&
            acceleFiltered[0]> acceleHurdol &&
            nowTime > (lapTime + lapTimeLim)) {
          HapticFeedback.mediumImpact();
          oldLapTime = lapTime;
          lapTime = DateTime.now().millisecondsSinceEpoch;
          _intervals[counter] = lapTime - oldLapTime;
          counter ++;
          if (counter == _intervals.length) {
            setState(() {
              calcBPMFromIntervals();
              adjustSpeed();
              if (_controller.value.playbackRate < 0.9 || _controller.value.playbackRate > 1.30) {
                remakePlayList(_genre, _artist, _playbackBPM);
              }
              counter = 0;
            });
          }
        }
      });
      },
    );
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
        adjustSpeed();
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  void adjustSpeed(){
      _controller.setPlaybackRate(_playbackBPM/musics[_playlist[_ids.indexOf(_videoMetaData.videoId) > 0 ? _ids.indexOf(_videoMetaData.videoId) :0]]['BPM']);
      debugPrint('${_controller.value.playbackRate}x  ');
  }

  void remakePlayList(genre, artist, BPM){
    _playlist = musicselect(genre: genre, artist: artist, BPM: BPM);
    _ids = List.generate(_playlist.length, (index) => musics[_playlist[index]]['youtubeid']);
    _controller.load(_ids[0]);
    _controller.play();
    debugPrint("remake playlist");
  }

  void calcBPMFromIntervals(){
    double aveDul = (_intervals.reduce((a, b) => a + b) -
        _intervals.reduce(math.max) -
        _intervals.reduce(math.min)) /
        (_intervals.length - 2);
    _playbackBPM = 60.0 / (aveDul / 1000);
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.white,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          if (_controller.value.playbackRate < 0.95 || _controller.value.playbackRate > 1.30) {
            remakePlayList(_genre, _artist, _playbackBPM);
          }
          else {
            _controller.load(_ids[(_ids.indexOf(data.videoId) + 1) % _ids.length]);
            _showSnackBar('Next Video Started!');
            adjustSpeed();
          }
        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Image.asset(
              'assets/beatimlogo.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          title: const Text(
            'Beatim',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Container(
          color: Colors.black,
          child: Column(
          children:[
            player,
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _space,
                  _text('Title', _videoMetaData.title),
                  _space,
                  Row(
                    children: [
                      _text(
                        'Playback Rate',
                        '${_controller.value.playbackRate}x  ',
                      ),
                    ],
                  ),
                  _space,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed:_isPlayerReady ? () { 
                          _controller.load(_ids[(_ids.indexOf(_controller.metadata.videoId) - 1) % _ids.length]);
                          adjustSpeed();
                        } : null,
                      ),
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: _isPlayerReady
                            ? () {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                          setState(() {});
                        }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: _isPlayerReady ? () {
                          _controller.load(_ids[(_ids.indexOf(_controller.metadata.videoId) + 1) % _ids.length]);
                          adjustSpeed();
                        } : null,
                      ),
                    ],
                  ),
                  _space,
                  Row(
                    children: <Widget>[
                      _text('BPM','${_playbackBPM.round()}'),
                      IconButton(
                        onPressed: _isPlayerReady ? (){
                          setState(() {
                            _playbackBPM = (_playbackBPM - 1).toInt().toDouble();
                          });
                        }
                            :null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Slider(
                          inactiveColor: Colors.white10,
                          value: _playbackBPM,
                          min: math.min (50.0,_playbackBPM),
                          max: math.max (200.0, _playbackBPM),
                          divisions: 150,
                          label: '${(_playbackBPM).round()}',
                          onChanged: _isPlayerReady
                              ? (value) {
                                HapticFeedback.selectionClick();
                            setState(() {
                              _playbackBPM = value;
                              adjustSpeed();
                              if (_controller.value.playbackRate < 0.9 || _controller.value.playbackRate > 1.30) {
                                remakePlayList(_genre, _artist, _playbackBPM);
                              }
                            });
                          }
                              : null,
                        ),
                      ),
                      IconButton(
                        onPressed: _isPlayerReady ? (){
                          setState(() {
                            _playbackBPM = (_playbackBPM + 1).toInt().toDouble();
                          });
                        }
                            :null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _text(String title, String value) {
    return RichText(
      text: TextSpan(
        text: '$title : ',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(PlayerState state) {
    switch (state) {
      case PlayerState.unknown:
        return Colors.grey[700]!;
      case PlayerState.unStarted:
        return Colors.pink;
      case PlayerState.ended:
        return Colors.red;
      case PlayerState.playing:
        return Colors.blueAccent;
      case PlayerState.paused:
        return Colors.orange;
      case PlayerState.buffering:
        return Colors.yellow;
      case PlayerState.cued:
        return Colors.blue[900]!;
      default:
        return Colors.blue;
    }
  }

  Widget get _space => const SizedBox(height: 10);


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16.0,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }
}
