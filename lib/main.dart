import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_colors/app_themes.dart';
import 'bloc/alarms/alarms_bloc.dart';
import 'bloc/stop_watch_bloc/stop_watch_bloc.dart';
import 'bloc/timer_bloc/timer_bloc.dart';
import 'cubic/timer_cubic_cubit.dart';
import 'modes/app_lifecycle.dart';
import 'notifications/alarm_notification_controller.dart';
import 'screen_holder.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLifecycleObserver(); // lifecycle observer

  await AlarmNotificationController.initializeChannels(); // notification channels
  await AlarmNotificationController().initialize(); // notification setup

  // request notification permission
  bool isAllowedToSendNotifications =
  await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  await AlarmNotificationController().createFromDatabase(); // load alarms

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<TimerBloc>(create: (context) => TimerBloc(0)), // timer bloc
        BlocProvider<AlarmsBloc>(create: (context) => AlarmsBloc()), // alarms bloc
        BlocProvider(create: (_) => TimerCubicCubit()), // timer cubit
        BlocProvider<StopWatchBloc>(create:(context)=>StopWatchBloc()),// stop_watch bloc
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // permission check
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Alarm of the Bloc',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.darkTheme(), // app theme
      home: const MainScreenHolder(), // main screen
    );
  }
}
