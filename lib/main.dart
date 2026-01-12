import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/gestures.dart';

void main() {
  final game =MyGame();
  runApp(GameWrapper());
}

class GameWrapper extends StatelessWidget {
  final MyGame game = MyGame();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        game.onTapDown(details); // 将触摸事件传递给游戏逻辑
      },
      onPanUpdate: (details) {
        game.updatePosition(details); // 更新移动位置
      },
      onTapUp: (details) {
        game.stopMoving(); // 停止移动
      },
      child: GameWidget(game: game), // 显示游戏
    );
  }
}

class MyGame extends FlameGame{
  late Sprite background;      // 背景图的 Sprite
  late double backgroundY1;     // 第一张背景图的 Y 轴位置
  late double backgroundY2;     // 第二张背景图的 Y 轴位置
  final double backgroundSpeed = 100; // 背景移动速度 (像素/秒)

  List<Sprite> characterFrames=[];  // 角色帧图像列表
  late SpriteAnimation characterAnimation;// 角色动画
  double characterX = 100;            // 角色的 X 位置
  double characterY = 100;            // 角色的 Y 位置
  double speed = 2;                   // 移动速度
  double frameTime = 0.1;             // 每帧的持续时间
  double elapsedTime = 0;             // 累计时间
  int currentFrame = 0;               // 当前帧索引
  int moving=0;                       //这个用来判断是否进行移动
  double touchX=0;                    //当前手指按动位置
  late Sprite electricFence;          //fence图片
  int fenceTimer=0;            //fence时间记数
  int fenceAppearTimer=500;     //每到一定时间就产生一个fence,一般是50
  List<ElectricFence> electricFences=[];//这是所有的fence类
  late double deviceWidth;            //设备的宽度
  int score = 50;                     //这是最终分数
  double fenceSpeed = 1;              //fence的速度


  @override
  Future<void> onLoad() async{
    //加载屏幕背景图
    //Future<void> onLoad() async 是 Dart 编程语言中用于定义异步方法的语法，常见于 Flutter 应用程序中。
    //async 关键字用于标记一个方法为异步方法。使用 async 时，你可以在方法内部使用 await 关键字来等待其他异步操作完成。
    final backGroundImage = await images.load('background.png');
    electricFence= await Sprite.load('electric_fence.png');//加载图片
    deviceWidth=size.x;//得到设备的宽度
    background = Sprite(backGroundImage);
    // 初始化背景图的位置
    backgroundY1 = 0;          // 第一张背景图在屏幕顶部
    backgroundY2 = -size.y;    // 第二张背景图紧接着第一张图上方

    for(int i=1;i<=8;i++){
      characterFrames.add(await Sprite.load('character/run_00$i.png'));
    }
    characterAnimation = SpriteAnimation.spriteList(characterFrames, stepTime: 0.15);
    characterX= size.x / 2;
    characterY = size.y - 128;
    print("game on load");
  }


  @override
  void update(double dt){
    //其中dt是增量时间，也就是帧与帧之间的时间间隔，这个是没有办法进行设置的
    // 让背景向下移动
    backgroundY1 += backgroundSpeed * dt;
    backgroundY2 += backgroundSpeed * dt;

    // 当第一张背景图完全移出屏幕时，将它移到第二张背景图的上方
    if (backgroundY1 >= size.y) {
      backgroundY1 = backgroundY2 - size.y;
    }

    // 当第二张背景图完全移出屏幕时，将它移到第一张背景图的上方
    if (backgroundY2 >= size.y) {
      backgroundY2 = backgroundY1 - size.y;
    }
    elapsedTime += dt;

    // 更新当前帧
    if (elapsedTime >= frameTime) {
      currentFrame = (currentFrame + 1) % characterFrames.length; // 循环帧
      elapsedTime = 0; // 重置累积时间
    }

    if(fenceTimer == 0){
      //如果归零的话就应该产生一个fence
      fenceTimer=fenceAppearTimer;
      electricFences.add(new ElectricFence(deviceWidth));
    }
    fenceTimer=fenceTimer-1;

    //只需要计算第一个fence什么样就行
    ElectricFence fenceNow = electricFences[0];
    if(fenceNow.y > characterY-45 && fenceNow.y < characterY+32){
      //如果刚好贴住了
      //穿进去一个score
      if(fenceNow.touchCheck(characterX,score)){
        //中了
        score=fenceNow.finalScore;
        electricFences.removeAt(0);
      }
    }else if(fenceNow.y >= characterY+32){
      //没中并且过了
      electricFences.removeAt(0);
    }

    electricFences.forEach((fence){
      //对每个fence进行操作，y增加
      fence.y=fence.y+fenceSpeed;//增加速度就是fenceSpeed
    });
  }

  @override
  void render(Canvas canvas){
    //每一个帧中进行调用
    super.render(canvas);

    // 设置文本样式
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    // 绘制两张背景图
    background.renderRect(
        canvas,
        Rect.fromLTWH(0, backgroundY1, size.x, size.y)  // 绘制第一张背景
    );
    background.renderRect(
        canvas,
        Rect.fromLTWH(0, backgroundY2, size.x, size.y)  // 绘制第二张背景
    );

    // 绘制fence
    electricFences.forEach((fence){
      //对每个fence进行操作
      electricFence.renderRect(
          canvas,
          Rect.fromLTWH(fence.x, fence.y, 256, 50));
      final leftFenceSpan = TextSpan(
        text: fence.leftOperatorString+fence.leftNumber.toString(),
        style: textStyle,
      );
      final leftFencePainter = TextPainter(
        text: leftFenceSpan,
        textDirection: TextDirection.ltr,
      );
      // 计算文本位置
      leftFencePainter.layout();
      // 在画布上绘制文本
      leftFencePainter.paint(canvas, Offset(fence.x+64, fence.y));

      final rightFenceSpan = TextSpan(
        text: fence.rightOperatorString+fence.rightNumber.toString(),
        style: textStyle,
      );
      final rightFencePainter = TextPainter(
        text: rightFenceSpan,
        textDirection: TextDirection.ltr,
      );
      // 计算文本位置
      rightFencePainter.layout();
      // 在画布上绘制文本
      rightFencePainter.paint(canvas, Offset(fence.x+192, fence.y));

    });

    // 绘制当前角色动画
    characterFrames[currentFrame].render(canvas, position: Vector2(characterX, characterY),size: Vector2(64, 64));
    // 根据触摸位置更新角色的 X 位置
    if (touchX < characterX) {
      characterX=characterX-moving*speed;
    } else if (touchX > characterX) {
      characterX=characterX+moving*speed;
    }

    //画出分数
    final scoreSpan = TextSpan(
      text: score.toString(),
      style: textStyle,
    );
    final scorePainter = TextPainter(
      text: scoreSpan,
      textDirection: TextDirection.ltr,
    );
    // 计算文本位置
    scorePainter.layout();
    // 在画布上绘制文本
    scorePainter.paint(canvas, Offset(characterX, characterY-64));
  }

  @override
  void onTapDown(TapDownDetails details) {
    touchX = details.localPosition.dx;
    moving=1;
  }

  void stopMoving() {
    // 角色停止移动
    moving=0;
  }

  void updatePosition(DragUpdateDetails details) {
    touchX = details.localPosition.dx;
    moving=1;
  }
}

class ElectricFence{
  double x=0;
  double y=0;
  double deviceWidth=0;

  int leftOperator = 0;
  int rightOperator=0;
  String leftOperatorString = '';
  String rightOperatorString='';

  int leftNumber=0;
  int rightNumber=0;
  int finalScore=0;
  bool isTouch=false;

  ElectricFence(this.deviceWidth){
    //构造器应该产生x与y值
    //y肯定是0
    Random random = Random();
    x = random.nextInt((deviceWidth - 260).toInt())+1;//产生一个随机数
    rightOperator=random.nextInt(4) + 1;
    leftOperator=random.nextInt(4) + 1;
    rightNumber=random.nextInt(10)+1;
    leftNumber=random.nextInt(10)+1;
    leftOperatorString=getOperatorString(leftOperator);
    rightOperatorString=getOperatorString(rightOperator);

  }
  bool touchCheck(double characterX,int score){
    //输入characterX,判断长度关系
    //因为characterX是左上角，所以这里要加个判断
    if( characterX+32 > x && characterX+32 < x+128){
      print("击中左边");
      finalScore = caculater(leftOperator, leftNumber,score);//击中左边
      isTouch=true;
      return isTouch;
    }

    if( characterX+32 >= x+128 && characterX+32 < x+256){
      print("击中右边");
      finalScore = caculater(rightOperator, rightNumber,score);//击中右边
      isTouch=true;
      return isTouch;
    }
    print("没有命中");
    return isTouch;
  }
  int caculater(int operator,int number,int score){
    switch(operator){
      case 1:
        return score+number;
      case 2:
        return score-number;
      case 3:
        return score*number;
      case 4:
        return score ~/ number;
    }
    return 0;
  }
  String getOperatorString(int operator){
    switch(operator){
      case 1:
        return '+';
      case 2:
        return "-";
      case 3:
        return "x";
      case 4:
        return "/";
    }
    return "";
  }
}
