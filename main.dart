import 'dart:io';
import 'dart:math';

class Board {
  static const int size = 8;
  List<List<String>> board;
  String currentPlayer;

  Board()
      : board = List.generate(size, (_) => List.filled(size, '.')),
        currentPlayer = '●' {
    _initializeBoard();
  }

  void _initializeBoard() {
    board[3][3] = board[4][4] = '○'; // White pieces
    board[3][4] = board[4][3] = '●'; // Black pieces
  }

  void displayBoard() {
    // Create a temporary board to display available moves
    List<List<String>> tempBoard =
        List.generate(size, (i) => List.from(board[i]));
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (Logic.isValidMove(board, i, j, currentPlayer)) {
          tempBoard[i][j] =
              '${i + 1}${j + 1}'; // Show coordinates for available moves
        }
      }
    }

    // Print the column labels with proper spacing
    stdout.write('   '); // Initial space for row labels
    for (int j = 1; j <= size; j++) {
      stdout.write('${j.toString().padLeft(2)} '); // Column labels
    }
    print('');

    // Print the board row by row
    for (int i = 1; i <= size; i++) {
      stdout.write('${i.toString().padLeft(2)} '); // Row label
      for (int j = 1; j <= size; j++) {
        // Use an empty string for empty cells
        stdout.write(
            '${tempBoard[i - 1][j - 1].padLeft(2)} '); // Cell content with padding
      }
      print('');
    }

    // Display the current scores
    displayScores();
  }

  void displayScores() {
    int blackCount = 0, whiteCount = 0;
    for (var row in board) {
      for (var cell in row) {
        if (cell == '●') blackCount++;
        if (cell == '○') whiteCount++;
      }
    }
    print('Score => Black: $blackCount, White: $whiteCount');
  }

  void startGame() {
    while (true) {
      displayBoard();
      print('Player $currentPlayer\'s turn');

      if (!Logic.hasValidMove(board, currentPlayer)) {
        print('Player $currentPlayer has no valid moves');
        currentPlayer = currentPlayer == '●' ? '○' : '●';
        if (!Logic.hasValidMove(board, currentPlayer)) break;
        continue;
      }

      if (currentPlayer == '●') {
        // Input row and column in the format "rowcol"
        stdout.write('Enter row and column: ');
        var input = stdin.readLineSync();

        if (input == null || input.length != 2) {
          print(
              'Invalid input format. Please enter coordinates in the format "rowcol".');
          continue;
        }

        int row = int.tryParse(input[0]) ?? -1;
        int col = int.tryParse(input[1]) ?? -1;

        if (row < 1 || row > Board.size || col < 1 || col > Board.size) {
          print(
              'Coordinates out of bounds. Please enter valid row and column.');
          continue;
        }

        if (!Logic.isValidMove(board, row - 1, col - 1, currentPlayer)) {
          print(
              'Invalid move. The chosen coordinates do not correspond to a valid move.');
          continue;
        }

        Logic.makeMove(board, row - 1, col - 1, currentPlayer);
        currentPlayer = currentPlayer == '●' ? '○' : '●';
      } else if (currentPlayer == '○') {
        List<int> botMove = Bot.botPlay(board, currentPlayer);
        int row = botMove[0];
        int col = botMove[1];
        print('Bot played at ${row + 1}${col + 1}');
        Logic.makeMove(board, row, col, currentPlayer);
        currentPlayer = currentPlayer == '●' ? '○' : '●';
      }
    }

    // Display board
    displayBoard();
    int blackCount = 0, whiteCount = 0;
    for (var row in board) {
      for (var cell in row) {
        if (cell == '●') blackCount++;
        if (cell == '○') whiteCount++;
      }
    }

    // End game
    print('Game over! Black: $blackCount, White: $whiteCount');
    if (blackCount > whiteCount) {
      print('Black wins!');
    } else if (whiteCount > blackCount) {
      print('White wins!');
    } else {
      print('It\'s a tie!');
    }

    // Restart the game after end game
    stdout.write('Do you want to restart the game? (y/n): ');
    var restartInput = stdin.readLineSync();
    if (restartInput != null && restartInput.toLowerCase() == 'y') {
      restartGame();
    }
  }

  void restartGame() {
    board = List.generate(size, (_) => List.filled(size, '.'));
    _initializeBoard();
    currentPlayer = '●';
    startGame();
  }
}

class Logic {
  static bool isValidMove(
      List<List<String>> board, int row, int col, String currentPlayer) {
    if (row < 0 ||
        row >= Board.size ||
        col < 0 ||
        col >= Board.size ||
        board[row][col] != '.') {
      return false;
    }

    bool isValid = false;

    // Check all 8 possible directions
    for (int dRow = -1; dRow <= 1; dRow++) {
      for (int dCol = -1; dCol <= 1; dCol++) {
        if (dRow != 0 || dCol != 0) {
          int r = row + dRow, c = col + dCol;
          bool hasOpponent = false;

          while (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
            if (board[r][c] == '.') break;
            if (board[r][c] == currentPlayer) {
              if (hasOpponent) {
                isValid = true;
                break;
              }
              break;
            }
            hasOpponent = true;
            r += dRow;
            c += dCol;
          }
        }
      }
    }

    return isValid;
  }

  static void makeMove(
      List<List<String>> board, int row, int col, String currentPlayer) {
    if (!isValidMove(board, row, col, currentPlayer)) {
      print('Invalid move');
      return;
    }
    board[row][col] = currentPlayer;

    // Flip the opponent's pieces
    for (int dRow = -1; dRow <= 1; dRow++) {
      for (int dCol = -1; dCol <= 1; dCol++) {
        if (dRow != 0 || dCol != 0) {
          List<List<int>> toFlip = [];
          int r = row + dRow, c = col + dCol;

          while (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
            if (board[r][c] == '.') break;
            if (board[r][c] == currentPlayer) {
              for (var pos in toFlip) {
                board[pos[0]][pos[1]] = currentPlayer;
              }
              break;
            }
            toFlip.add([r, c]);
            r += dRow;
            c += dCol;
          }
        }
      }
    }
  }

  static bool hasValidMove(List<List<String>> board, String currentPlayer) {
    for (int i = 0; i < Board.size; i++) {
      for (int j = 0; j < Board.size; j++) {
        if (isValidMove(board, i, j, currentPlayer)) return true;
      }
    }
    return false;
  }
}

class Bot {
  static var random = Random();
  static List<int> botPlay(List<List<String>> board, String currentPlayer) {
    int row;
    int col;
    List<int> botMove = [];
    while (true) {
      row = random.nextInt(Board.size);
      col = random.nextInt(Board.size);
      if (Logic.isValidMove(board, row, col, currentPlayer)) {
        botMove.add(row);
        botMove.add(col);
        return botMove;
      }
    }
  }
}

void main() {
  Board game = Board();
  game.startGame();
}
