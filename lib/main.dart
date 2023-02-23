import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:beatim3/musicselectfunction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'video_list.dart';
import 'musicdata.dart';

List<int> _playlist = [0,1,2,3,4,5,6,7,8,9,10];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.blueAccent,
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
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blueAccent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.blueAccent,
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
  List<int> _duls = [1, 1, 1, 1, 1, 1, 1];
  int _counter = 0;
  double _runnigBPM = 160.0;

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
  }

  void remakePlayList(genre, artist, BPM){
    _playlist = musicselect(genre: genre, artist: artist, BPM: BPM);
    _ids = List.generate(_playlist.length, (index) => musics[_playlist[index]]['youtubeid']);
    _controller.load(_ids[0]);
    _controller.play();
    debugPrint("remake playlist");
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
        progressIndicatorColor: Colors.blueAccent,
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
              'assets/beatim.png',
              fit: BoxFit.fitWidth,
            ),
          ),
          title: const Text(
            'Beatim',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.video_library),
              onPressed: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => VideoList(),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            player,
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _space,
                  _text('Title', _videoMetaData.title),
                  _space,
                  _text('Channel', _videoMetaData.author),
                  _space,
                  _text('Video Id', _videoMetaData.videoId),
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
                  TextField(
                    enabled: _isPlayerReady,
                    controller: _idController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter youtube \<video id\> or \<link\>',
                      fillColor: Colors.blueAccent.withAlpha(20),
                      filled: true,
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.blueAccent,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _idController.clear(),
                      ),
                    ),
                  ),
                  _space,
                  Row(
                    children: [
                      _loadCueButton('LOAD'),
                      const SizedBox(width: 10.0),
                      _loadCueButton('CUE'),
                    ],
                  ),
                  _space,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
                      FullScreenButton(
                        controller: _controller,
                        color: Colors.blueAccent,
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
                    ],
                  ),
                  _space,
                  Row(
                    children: <Widget>[
                      const Text(
                        "Volume",
                        style: TextStyle(fontWeight: FontWeight.w300),
                      ),
                      Expanded(
                        child: Slider(
                          inactiveColor: Colors.transparent,
                          value: _volume,
                          min: 0.0,
                          max: 100.0,
                          divisions: 10,
                          label: '${(_volume).round()}',
                          onChanged: _isPlayerReady
                              ? (value) {
                            setState(() {
                              _volume = value;
                            });
                            _controller.setVolume(_volume.round());
                          }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Text(
                        "playbackBPM",
                        style: TextStyle(fontWeight: FontWeight.w300),
                      ),
                      Expanded(
                        child: Slider(
                          inactiveColor: Colors.transparent,
                          value: _playbackBPM,
                          min: math.min (50.0,_playbackBPM),
                          max: math.max (200.0, _playbackBPM),
                          label: '${(_playbackBPM).round()}',
                          onChanged: _isPlayerReady
                              ? (value) {
                            setState(() {
                              _playbackBPM = value;
                              remakePlayList(_genre, _artist, _playbackBPM);
                            });
                          }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: _isPlayerReady ? (){
                            setState(() {
                              _playbackBPM --;
                            });
                        }
                          :null,
                          icon: const Icon(Icons.remove),
                      ),
                      Text("${_playbackBPM.round()}"),
                      IconButton(
                        onPressed: _isPlayerReady ? (){
                          setState(() {
                            _playbackBPM ++;
                          });
                        }
                            :null,
                          icon: const Icon(Icons.add),
                      ),
                      Text("${_ids.indexOf(_controller.metadata.videoId)}"),
                    ],
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
                    width: 20, //幅
                    height: 20, //高さ
                    child: Center(
                      //内側の四角
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1), //角丸にする
                          color: Colors.black, //色
                        ),
                        width: 17, //幅
                        height: 17, //高さ
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _oldtime = _newtime;
                            _newtime = DateTime.now()
                                .millisecondsSinceEpoch; //millisecond
                            for (int i = _duls.length - 1; i > 0; i--) {
                              _duls[i] = _duls[i - 1];
                            }
                           _duls[0] = _newtime - _oldtime;
                            double aveDul = (_duls.reduce((a, b) => a + b) -
                                _duls.reduce(math.max) -
                                _duls.reduce(math.min)) /
                                (_duls.length - 2);
                            setState(() {
                              _runnigBPM = 60.0 / (aveDul / 1000);
                            });
                            _counter ++;
                            if (_counter == _duls.length + 1) {
                              HapticFeedback.vibrate();
                              setState(() {
                                _playbackBPM = _runnigBPM;
                                remakePlayList(_genre, _artist, _playbackBPM);
                                setState(() {
                                  _counter = 0;
                                });
                              });
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Positioned(
                                top: 1.0,
                                child: Column(
                                  //ボタンの中身
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(
                                          1.0), //走る人マーク周りの余白
                                      child: Icon(
                                        Icons.directions_run,
                                        color: Colors.white,
                                        size: 10,
                                      ), //走る人のマーク
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0,1,0,0), //現在のBPM周りの余白
                                      child: Text(
                                        "runningBPM${_runnigBPM.toStringAsFixed(1)}",
                                        style: const TextStyle(
                                            fontSize: 2,
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
                  _space,
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: _getStateColor(_playerState),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _playerState.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _text(String title, String value) {
    return RichText(
      text: TextSpan(
        text: '$title : ',
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.blueAccent,
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

  Widget _loadCueButton(String action) {
    return Expanded(
      child: MaterialButton(
        color: Colors.blueAccent,
        onPressed: _isPlayerReady
            ? () {
          if (_idController.text.isNotEmpty) {
            var id = YoutubePlayer.convertUrlToId(
              _idController.text,
            ) ??
                '';
            if (action == 'LOAD') _controller.load(id);
            if (action == 'CUE') _controller.cue(id);
            FocusScope.of(context).requestFocus(FocusNode());
          } else {
            _showSnackBar('Source can\'t be empty!');
          }
        }
            : null,
        disabledColor: Colors.grey,
        disabledTextColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

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
