import 'dart:io';

import 'package:wisely/src/application/ports/platform_ports.dart';

class ProcessAppExit implements AppExitPort {
  @override
  Never quit() => exit(0);
}
