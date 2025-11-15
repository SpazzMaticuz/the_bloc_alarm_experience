import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_colors/app_themes.dart';
import 'bloc/alarms/alarms_bloc.dart';
import 'bloc/timer_bloc/timer_bloc.dart';
import 'cubic/timer_cubic_cubit.dart';
import 'modes/app_lifecycle.dart';
import 'notifications/alarm_notification_controller.dart';
import 'screen_holder.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLifecycleObserver(); // initialize singleton

  // ✅ FIX: Use the static method to initialize and register channels
  await AlarmNotificationController.initializeChannels();

  // ✅ FIX: Initialize listeners (should be done after channels)
  await AlarmNotificationController().initialize();

  bool isAllowedToSendNotifications =
  await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowedToSendNotifications) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }
  await AlarmNotificationController().createFromDatabase();

  runApp(
    MultiBlocProvider(
      providers: [
        // Assuming AlarmBloc is a typo and should be AlarmsBloc, or you have another Bloc
        // I will keep the original providers list structure:
        // BlocProvider<AlarmBloc>(create: (context) => AlarmBloc()),
        BlocProvider<TimerBloc>(create: (context) => TimerBloc(0)),
        BlocProvider<AlarmsBloc>(create: (context) => AlarmsBloc()),
        BlocProvider(create: (_) => TimerCubicCubit()),
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


  // ❌ REMOVED: onActionReceivedMethod is now inside AlarmNotificationController
  // to properly handle background isolates.

  @override
  void initState() {
    super.initState();

    // ❌ REMOVED: No need to call setListeners here, as it's done once in main()
    // via AlarmNotificationController().initialize();

    // Ask permission if not granted (This check is fine to keep here)
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
      theme: AppThemes.darkTheme(),
      home: const MainScreenHolder(),
    );
  }
}