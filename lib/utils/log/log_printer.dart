import 'package:logger/logger.dart';

class SimpleLogPrinter extends LogPrinter {
  final String className;

  SimpleLogPrinter(this.className);

  @override
  void log(LogEvent event) {
    var emoji = PrettyPrinter.levelEmojis[event.level];
    println('$emoji $className - ${event.message}');
  }
}
