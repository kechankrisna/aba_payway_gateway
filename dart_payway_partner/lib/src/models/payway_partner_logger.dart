import 'package:logger/logger.dart';

class PaywayPartnerLogger {
  static Logger logger = Logger(
    filter: PaywayPartnerLogFilter(),
    level: Logger.level,
  );
}

class PaywayPartnerLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

