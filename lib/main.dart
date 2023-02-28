import 'dart:developer' as dev;
import 'dart:math' as math;

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
      title: 'Beatim',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: const AppBarTheme(
          color: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
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
  double _volume = 100;
  double _playbackBPM = 160.0;
  bool _muted = false;
  bool _isPlayerReady = false;
  int _oldtime = 0;
  int _newtime = 0;
  List<int> _intervals = [1, 1, 1, 1, 1, 1, 1];
  int _counter = 0;

  String _genre = "free";
  String _artist = "free";


  List<String> _ids = List.generate(_playlist.length, (index) => musics[_playlist[index]]['youtubeid']);

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: _ids.first,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
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
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {
              dev.log('Settings Tapped!');
            },
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          _controller
              .load(_ids[(_ids.indexOf(data.videoId) + 1) % _ids.length]);
          _showSnackBar('Next Video Started!');
          adjustSpeed();
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
                        'Playback Quality',
                        _controller.value.playbackQuality ?? '',
                      ),
                      const Spacer(),
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
                        icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                        onPressed: _isPlayerReady
                            ? () {
                          _muted
                              ? _controller.unMute()
                              : _controller.mute();
                          setState(() {
                            _muted = !_muted;
                          });
                        }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed:_isPlayerReady
                            ? () { _controller.load(_ids[
                        (_ids.indexOf(_controller.metadata.videoId) -
                            1) %
                            _ids.length]);
                        adjustSpeed();}
                            : null,
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
                        onPressed: _isPlayerReady
                            ? () {_controller.load(_ids[
                        (_ids.indexOf(_controller.metadata.videoId) +
                            1) %
                            _ids.length]);
                        adjustSpeed();}
                            : null,
                      ),
                      FullScreenButton(
                        controller: _controller,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  _space,
                  Row(
                    children: <Widget>[
                      const Text(
                        "playbackBPM : ",
                        style: TextStyle(fontWeight: FontWeight.w300,color: Colors.white),
                      ),
                      Text("${_playbackBPM.round()}", style: TextStyle(color: Colors.white),),
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
                          inactiveColor: Colors.transparent,
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
                              remakePlayList(_genre, _artist, _playbackBPM);
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10,50,10,10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 70,
                          height: 60,
                        ),
                        Container(
                          //外側の四角
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20), //角丸にする
                            gradient: const LinearGradient(
                              //グラデーション設定
                                begin: FractionalOffset.topLeft, //グラデーション開始位置
                                end: FractionalOffset.bottomRight, //グラデーション終了位置
                                colors: [
                                  Colors.pinkAccent, //グラデーション開始色
                                  Colors.purple, //グラデーション終了色
                                ]),
                          ),
                          width: 200, //幅
                          height: 200, //高さ
                          child: Center(
                            //内側の四角
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5), //角丸にする
                                color: Colors.black, //色
                              ),
                              width: 170, //幅
                              height: 170, //高さ
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _oldtime = _newtime;
                                  _newtime = DateTime.now().millisecondsSinceEpoch; //millisecond
                                  _intervals[_counter] = _newtime - _oldtime;
                                  _counter ++;
                                  if (_counter == _intervals.length) {
                                    HapticFeedback.vibrate();
                                    setState(() {
                                      calcBPMFromIntervals();
                                      remakePlayList(_genre, _artist, _playbackBPM);
                                        _counter = 0;
                                    });
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Positioned(
                                      top: 10.0,
                                      child: Column(
                                        //ボタンの中身
                                        children: [
                                          Container(
                                            width:120,
                                            height: 120,
                                            child: Image.asset(
                                              'assets/beatimlogo.png',
                                             ),
                                            ), //走る人のマーク
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                2,2,2,2), //現在のBPM周りの余白
                                            child: Text(
                                              "BPM${_playbackBPM.toStringAsFixed(1)}",
                                              style: const TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.white),
                                            ), //現在のBPM
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          height: 60,
                        )
                      ],
                    ),
                  ),
                  _space,
                  Center(
                    child: Container(
                      child: Text("Tap ${7-_counter} more times !",style: TextStyle(fontSize: 20,color: Colors.white),),
                    ),
                  )
                  // AnimatedContainer(
                  //   duration: const Duration(milliseconds: 800),
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(20.0),
                  //     color: _getStateColor(_playerState),
                  //   ),
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Text(
                  //     _playerState.toString(),
                  //     style: const TextStyle(
                  //       fontWeight: FontWeight.w300,
                  //       color: Colors.white,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ),
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
