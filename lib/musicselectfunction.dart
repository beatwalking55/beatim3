import 'package:flutter/cupertino.dart';

import 'musicdata.dart';
import 'dart:math' as math ;

musicselect({genre, artist, BPM}) {
  int i = 0;
  int numberofmusics = musics.length;
  List<int> playList = []; //再生リストの曲IDのみを収納
  const minBPMratio = 0.95;  //再生倍率の最小値
  const maxBPMratio = 1.3;  //再生倍率の最大値

  //musicID番目の曲の評価値を返す関数
  //評価値はいい曲ほど高い
  double evaluate(musicID){

    //各パラメータを正規化する。double型にしておく。
    //beatabilityの正規化。そのまま。
    double normalizedbeatability = musics[musicID]['beatability'].toDouble();
    //bpmratioの正規化。とりあえずグラフを直線で結んだ形にした。
    double bpmratio = BPM/musics[musicID]["BPM"];
    double normalizedbpmratio = 0;
    if(bpmratio<0.95){
      normalizedbpmratio = (0.5/0.95)*bpmratio;
    }else if(bpmratio>=0.95 && bpmratio<=1.0){
      normalizedbpmratio = 10.0*bpmratio - 9.0;
    }else if (bpmratio > 1.0 && bpmratio <= 1.3){
      normalizedbpmratio = (-5/3)*bpmratio + 8/3;
    }else{
      normalizedbpmratio = 0;
    }

    //ランダム要素。0~1の値を適当にとる
    double normalizedrandom = math.Random().nextDouble();

    //各パラメータの重みづけ。最後の一つは1-(他のパラメータの重み付け)にする。
    double beatabilityweight = 0.45;//ここの数字を上げると、beatabilityが高い曲がプレイリスト上位に出てくる。逆にこの数字を下げると、BPMが近い曲がプレイリスト上位に出てくる。
    double bpmratioweight = 0.45;
    double randomweight = 1-beatabilityweight - bpmratioweight;

    return beatabilityweight*normalizedbeatability + bpmratioweight*normalizedbpmratio + normalizedrandom*randomweight;//型に注意
  }


  //おまかせ（ジャンルフリー、アーティストフリー）の場合
  if (genre == "free" && artist == "free") {
    List <List> playList_ = []; //評価値も収納する仮プレイリスト

    //BPMが計測BPMの0.9~1.3の範囲の物を選別する。
    for (i = 0; i < numberofmusics; i++) {
      if (musics[i]["BPM"] <= BPM/minBPMratio && musics[i]["BPM"] >= BPM/maxBPMratio) {
        playList_.add([i, -evaluate(i)]);//評価値は昇順でソートするためマイナスをかけている
      }
    }

    //beatabilityに応じて並べ替え
    playList_.sort(
          (a, b) {
        return a[1].compareTo(b[1]);
      },
    );
    playList = List.generate(playList_.length, (index) => playList_[index][0]);

    //BPM的に合う曲がなかった時の救済
    if (playList.isEmpty) {
      return List.generate(numberofmusics, (index) => index);
    }

    debugPrint("$playList");
    return playList;
  }





  //ジャンル選択ページからきた（ジャンル指定、アーティストフリー）の場合
  else if (genre != "free" && artist == "free") {
    List<List> playList_a = []; //genre一致の曲IDとその評価値を収納する仮プレイリスト
    List<List> playList_b = []; //genre不一致の曲IDとその評価値を収納
    List<int> playLista = []; //genre一致の曲IDを収納する仮プレイリスト
    List<int> playListb = []; //genre不一致の曲IDを収納する仮プレイリスト

    for (i = 0; i < numberofmusics; i++) {
      //BPMが計測BPMの0.9~1.3の範囲の物を選別する。
      if (musics[i]["BPM"] <= BPM/minBPMratio && musics[i]["BPM"] >= BPM/maxBPMratio) {
        //ジャンル一致のものとそうでないものに振り分ける
        if (musics[i]['genre1'] == genre ||
            musics[i]['genre2'].toString() == genre) {
          playList_a.add([i, -evaluate(i)]);//評価値は昇順でソートするためマイナスをかけている
        } else {
          playList_b.add([i, -evaluate(i)]);//評価値は昇順でソートするためマイナスをかけている
        }
      }
    }
    playList_a.sort(
          (a, b) {
        return a[1].compareTo(b[1]);
      },
    );
    playList_b.sort(
          (a, b) {
        return a[1].compareTo(b[1]);
      },
    );
    //仮プレイリストから曲IDのみを取ってきて仮プレイリストを作る
    playLista =
        List.generate(playList_a.length, (index) => playList_a[index][0]);
    playListb =
        List.generate(playList_b.length, (index) => playList_b[index][0]);

    //playListにそれぞれの仮プレイリストを加えて結合
    playList.addAll(playLista);
    playList.addAll(playListb);

    //BPM的に合う曲がなかった時の救済
    if (playList.isEmpty) {
      return List.generate(numberofmusics, (index) => index);
    }
    debugPrint("$playList");
    return playList;






    //アーティスト選択ページから来た（ジャンルフリー、アーティスト指定あり）の場合
  } else if (genre == "free" && artist != "free") {
    List<List> playList_a = []; //artist一致の曲IDとその評価値を収納する仮プレイリスト
    List<List> playList_b = []; //artist不一致の曲IDとその評価値を収納
    List<int> playLista = []; //artist一致した曲IDを収納する仮プレイリスト
    List<int> playListb = []; //artist不一致の曲IDを収納する仮プレイリスト

    for (i = 0; i < numberofmusics; i++) {
      //BPMが計測BPMの0.9~1.3の範囲の物を選別する。
      if (musics[i]["BPM"] <= BPM/minBPMratio && musics[i]["BPM"] >= BPM/maxBPMratio) {
        //ジャンル一致のものとそうでないものに振り分ける
        if (musics[i]['artist'] == artist) {
          playList_a.add([i, -evaluate(i)]);//評価値は昇順でソートするためマイナスをかけている
        } else {
          playList_b.add([i, -evaluate(i)]);
        }
      }
    }
    playList_a.sort(
          (a, b) {
        return a[1].compareTo(b[1]);
      },
    );
    playList_b.sort(
          (a, b) {
        return a[1].compareTo(b[1]);
      },
    );
    //仮プレイリストから曲IDのみを取ってきて仮プレイリストを作る
    playLista =
        List.generate(playList_a.length, (index) => playList_a[index][0]);
    playListb =
        List.generate(playList_b.length, (index) => playList_b[index][0]);

    //playListにそれぞれの仮プレイリストを加えて結合
    playList.addAll(playLista);
    playList.addAll(playListb);

    //BPM的に合う曲がなかった時の救済
    if (playList.isEmpty) {
      return List.generate(numberofmusics, (index) => index);
    }
    debugPrint("$playList");
    return playList;
  }
}
