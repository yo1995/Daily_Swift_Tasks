## TicTacToe

![logo](/tictactoe/resources/logo.png)

partially inspired by https://github.com/cocoascientist/TicTacToe

Also, learned a lot from: https://freecontent.manning.com/classic-computer-science-problems-in-swift-tic-tac-toe/

Please refer to [Video](/tictactoe/progress-notes/release1_190710.mov) for more details

### 归档

压缩后的文件见 Released 目录。

### Building

```sh
xcodebuild -project tictactoe.xcodeproj -scheme DukeAppStore clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

xcodebuild -project tictactoe.xcodeproj -scheme DukeAppStore clean
```
