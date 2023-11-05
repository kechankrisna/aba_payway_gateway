import 'package:logger/logger.dart';

class PaywayLogger {
  static Logger logger = Logger(
    filter: PaywayLogFilter(),
    level: Logger.level,
  );
}

class PaywayLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

