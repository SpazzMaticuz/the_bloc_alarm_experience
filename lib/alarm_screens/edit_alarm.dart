import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_colors/app_colors.dart';
import '../bloc/alarms/alarms_bloc.dart';
import '../modes/bottom_popup.dart';
import 'alarm_options.dart';

/// A reusable utility to show a bottom sheet popup for editing or deleting an alarm.
///
/// This class wraps your existing [BottomPopup] and [AlarmOptions] to provide
/// a convenient interface for editing alarms in the UI.
class AlarmEditorPopup {

  /// Displays the bottom popup for editing or deleting an alarm.
  ///
  /// [context] — BuildContext from the widget tree.
  /// [title] — Title of the popup (default: "Edit Alarm").
  /// [isEdit] — Whether the popup is in edit mode.
  /// [alarmId] — The ID of the alarm being edited or deleted.
  /// [onSave] — Callback triggered when the user saves changes.
  /// [onDelete] — Callback triggered when the user deletes the alarm.
  static void show(
      BuildContext context, {
        String title = 'Edit Alarm',
        bool isEdit = true,
        required int alarmId,
        required VoidCallback onSave,
        required VoidCallback onDelete,
      }) {
    final bloc = context.read<AlarmsBloc>();

    // Show the bottom sheet using your BottomPopup utility
    BottomPopup.show(
      context,
      title: title,
      content: AlarmOptions(
        isEdit: isEdit,
        onSave: onSave,
      ),
      showButton: true, // Always show the action button at the bottom
      onSave: onSave,
      actionButton: ElevatedButton(
        onPressed: () {
          // Dispatch DeleteAlarmEvent to the bloc
          bloc.add(DeleteAlarmEvent(alarmId));

          // Call the provided onDelete callback
          onDelete();

          // Close the popup
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
