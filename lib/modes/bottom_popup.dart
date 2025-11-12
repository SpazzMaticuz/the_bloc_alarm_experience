import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarms/alarms_bloc.dart';
import 'alarm_song_selector.dart';

// Maps short day names to full display names
const Map<String, String> shortToFullDayNames = {
  'Mon': 'Every Monday',
  'Tue': 'Every Tuesday',
  'Wed': 'Every Wednesday',
  'Thu': 'Every Thursday',
  'Fri': 'Every Friday',
  'Sat': 'Every Saturday',
  'Sun': 'Every Sunday',
};

// Reverse mapping
final Map<String, String> fullToShortDayNames =
{for (var e in shortToFullDayNames.entries) e.value: e.key};

class BottomPopup extends StatefulWidget {
  final String title;
  final Widget content;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final Widget? actionButton;
  final VoidCallback? onClose;
  final bool showButton;

  const BottomPopup({
    super.key,
    required this.title,
    required this.content,
    this.onSave,
    this.onCancel,
    this.actionButton,
    this.onClose,
    this.showButton = false,
  });

  static Future<void> show(
      BuildContext context, {
        required String title,
        required Widget content,
        VoidCallback? onSave,
        VoidCallback? onCancel,
        Widget? actionButton,
        VoidCallback? onClose,
        bool showButton = false,
      }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bloc = context.read<AlarmsBloc>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: screenHeight * 0.9,
        width: screenWidth,
        child: BlocProvider.value(
          value: bloc,
          child: BottomPopup(
            title: title,
            content: content,
            onSave: onSave,
            onCancel: onCancel,
            actionButton: actionButton,
            onClose: onClose,
            showButton: showButton,
          ),
        ),
      ),
    );
  }

  @override
  State<BottomPopup> createState() => _BottomPopupState();
}

class _BottomPopupState extends State<BottomPopup> {
  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  void _handleSave() {
    widget.onSave?.call();
    Navigator.of(context).pop();
  }

  Future<void> _handleSoundTap(BuildContext context) async {
    final bloc = context.read<AlarmsBloc>();
    final currentState = bloc.state;

    // Call the modal and wait for a selection, using the current music path
    final selectedPath = await showAlarmSongSelector(context, currentState.music);

    if (selectedPath != null && selectedPath != currentState.music) {
      // Dispatch the new event to update the music path in the BLoC state
      bloc.add(UpdateMusicEvent(selectedPath));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return DraggableScrollableSheet(
      minChildSize: 0.5,
      initialChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<AlarmsBloc, AlarmsState>(
          builder: (context, state) {
            final bloc = context.read<AlarmsBloc>();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHeader(context, state.currentView),
                  const Divider(height: 1),
                  Expanded(
                    child: IndexedStack(
                      index: state.currentView.index,
                      children: [
                        // Main alarm form
                        _MainAlarmFormView(

                          scrollController: scrollController,
                          content: widget.content,
                          labelText: state.labelText,
                          music: state.music,
                          selectedDays: state.selectedDays
                              .map((d) => shortToFullDayNames[d] ?? d)
                              .toList(),
                          onLabelChanged: (val) => bloc.add(UpdateLabelEvent(val)),
                          onRepeatTap: () =>
                              bloc.add(ChangeViewEvent(PopupView.repeatSelection)),
                          onSoundTap: () => _handleSoundTap(context),
                        ),

                        // Repeat selection view
                        RepeatSelectionView(
                          allDays: allDays,
                          selectedDays: state.selectedDays,
                          toggleDay: (shortName) => bloc.add(ToggleDayEvent(shortName)),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showButton && state.currentView == PopupView.main)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: widget.actionButton ??
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onClose?.call();
                            },
                            child: const Text('Close'),
                          ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PopupView currentView) {
    final bloc = context.read<AlarmsBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentView == PopupView.main)
            TextButton(onPressed: _handleCancel, child: const Text('Cancel')),
          if (currentView == PopupView.repeatSelection)
            TextButton.icon(
              onPressed: () => bloc.add(ChangeViewEvent(PopupView.main)),
              icon: const Icon(Icons.chevron_left, size: 26),
              label: const Text(
                'Back',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          Text(
            currentView == PopupView.main ? widget.title : 'Repeat',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (currentView == PopupView.main)
            TextButton(onPressed: _handleSave, child: const Text('Save')),
          if (currentView == PopupView.repeatSelection)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ------------------------
// Main Form View
// ------------------------
class _MainAlarmFormView extends StatelessWidget {
  final ScrollController scrollController;
  final Widget content;
  final String labelText;
  final String music;
  final List<String> selectedDays; // full names: Every Monday
  final Function(String) onLabelChanged;
  final VoidCallback onRepeatTap;
  final VoidCallback onSoundTap;

  const _MainAlarmFormView({
    required this.scrollController,
    required this.content,
    required this.labelText,
    required this.music,
    required this.selectedDays,
    required this.onLabelChanged,
    required this.onRepeatTap,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    final daySummary = selectedDays.isEmpty
        ? 'Never'
        : selectedDays.map((d) => d.split(' ')[1].substring(0, 3)).join(' ');
    final soundName = getSongNameFromPath(music);

    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            content,
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildSettingsRow('Repeat', daySummary, true, onRepeatTap),
                  const Divider(height: 1),
                  _buildLabelRow(),
                  const Divider(height: 1),
                  _buildSettingsRow('Sound', soundName, true, onSoundTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(String title, String value, bool showArrow, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                if (showArrow) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow() {
    final controller = TextEditingController(text: labelText);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Label',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                  hintText: 'Alarm', hintStyle: TextStyle(color: Colors.black54, fontSize: 16), border: InputBorder.none, isDense: true),
              onChanged: onLabelChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------
// Repeat Selection View
// ------------------------
class RepeatSelectionView extends StatelessWidget {
  final List<String> allDays; // short names
  final List<String> selectedDays; // short names
  final Function(String) toggleDay;

  const RepeatSelectionView({
    super.key,
    required this.allDays,
    required this.selectedDays,
    required this.toggleDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.50,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: allDays.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
            itemBuilder: (context, index) {
              final shortName = allDays[index];
              final fullName = shortToFullDayNames[shortName] ?? shortName;
              final isSelected = selectedDays.contains(shortName);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => toggleDay(shortName),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fullName,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600)),
                        if (isSelected) const Icon(Icons.check, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
