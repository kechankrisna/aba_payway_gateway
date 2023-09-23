import 'package:logger/logger.dart';

class ABAPaywayLogger {
  static Logger logger = Logger(
    filter: ABAPaywayLogFilter(),
    level: Logger.level,
  );
}

class ABAPaywayLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

