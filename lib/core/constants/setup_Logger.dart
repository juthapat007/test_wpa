import 'package:pretty_dio_logger/pretty_dio_logger.dart';

PrettyDioLogger setupLogger() {
  return PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    logPrint: print,
  );
}
