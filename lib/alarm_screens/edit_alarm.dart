import 'package:flutter/material.dart';

// ✅ Your BottomPopup utility (assumes you already have this somewhere)
import '../app_colors/app_colors.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/bottom_popup.dart';
import 'alarm_options.dart'; // your AlarmOptions widget
import 'package:flutter_bloc/flutter_bloc.dart';

/// A reusable class that shows the bottom popup to edit or delete an alarm.
///
/// You can call `AlarmEditorPopup.show(context, alarmData)`
/// from inside your AlarmCard onTap, or anywhere else.
///
/// It uses the same BottomPopup.show logic you provided.
class AlarmEditorPopup {
  /// Displays the bottom popup for editing or deleting an alarm.
  ///
  /// [context] — BuildContext from the widget tree
  /// [title] — popup title (default: "Edit Alarm")
  /// [isEdit] — if true, shows the AlarmOptions in edit mode
  /// [onSave] — callback when the Save button is pressed
  /// [onDelete] — callback when the Delete button is pressed
  static void show(BuildContext context, {
    String title = 'Edit Alarm',
    bool isEdit = true,
    required int alarmId, // Pass the alarm ID here
    required VoidCallback onSave,
    required VoidCallback onDelete,
  }) {
    final bloc = context.read<AlarmsBloc>();
    BottomPopup.show(
      context,
      title: title,
      content: AlarmOptions(
        isEdit: isEdit,
        onSave: onSave,
      ),
      showButton: true,
      onSave: onSave,
      actionButton: ElevatedButton(
        onPressed: () {
          bloc.add(DeleteAlarmEvent(alarmId));
          onDelete();
          Navigator.of(context).pop();
        },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.text,
          ),
        child: const Text('Delete Alarm'),
      ),
    );
  }

}