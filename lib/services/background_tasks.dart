import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

const String kWeatherRefreshTask = 'umbrellaWeatherRefresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case kWeatherRefreshTask:
      case Workmanager.iOSBackgroundTask:
        await NotificationService.instance.refreshFromBackground();
        break;
      default:
        break;
    }
    return Future.value(true);
  });
}
