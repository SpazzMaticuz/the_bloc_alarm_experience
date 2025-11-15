import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timer_bloc/timer_bloc.dart';
import 'timer_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/timer_bloc/timer_bloc.dart';
import 'timer_view.dart';

class TimerControls extends StatelessWidget {
  //Accept the unique ID from the database/Cubit
  final int timerId;
  final int initialDuration;
  final VoidCallback onDelete;

  const TimerControls({
    Key? key,
    required this.timerId,
    required this.initialDuration,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Each TimerControls creates a unique TimerBloc instance for one timer.
      create: (_) => TimerBloc(initialDuration),
      child: TimerView(
        //Pass the unique ID down to TimerView
        timerId: timerId,
        initialDuration: initialDuration,
        onDelete: onDelete,
      ),
    );
  }
}