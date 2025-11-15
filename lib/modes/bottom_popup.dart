import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_colors/app_colors.dart';
import '../bloc/alarms/alarms_bloc.dart';
import 'alarm_song_selector.dart';

// Mapping short day names to full display names for UI
const Map<String, String> shortToFullDayNames = {
  'Mon': 'Every Monday',
  'Tue': 'Every Tuesday',
  'Wed': 'Every Wednesday',
  'Thu': 'Every Thursday',
  'Fri': 'Every Friday',
  'Sat': 'Every Saturday',
  'Sun': 'Every Sunday',
};

// Reverse mapping for convenience
final Map<String, String> fullToShortDayNames = {
  for (var e in shortToFullDayNames.entries) e.value: e.key,
};

// --- BottomPopup ---
// Reusable bottom sheet for editing alarms (label, repeat, sound)
class BottomPopup extends StatefulWidget {
  final String title;
  final Widget content; // Optional custom content (e.g., time picker)
  final VoidCallback? onSave; // Save callback
  final VoidCallback? onCancel; // Cancel callback
  final Widget? actionButton; // Optional bottom button (e.g., Close)
  final VoidCallback? onClose; // Callback when bottom button is pressed
  final bool showButton; // Show bottom action button

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

  // --- Static helper to open the bottom sheet ---
  // Reuses the existing AlarmsBloc from the context
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
      isScrollControlled: true, // allow dragging full height
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: screenHeight * 0.9, // almost full screen
        width: screenWidth,
        child: BlocProvider.value(
          value: bloc, // provide same bloc to popup
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

  // --- Cancel action ---
  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  // --- Save action ---
  void _handleSave() {
    widget.onSave?.call();
    Navigator.of(context).pop();
  }

  // --- Open sound selection modal ---
  // Updates BLoC state with the selected alarm sound
  Future<void> _handleSoundTap(BuildContext context) async {
    final bloc = context.read<AlarmsBloc>();
    final currentState = bloc.state;

    final selectedPath = await showAlarmSongSelector(
      context,
      currentState.music, // show current selection
    );

    if (selectedPath != null && selectedPath != currentState.music) {
      bloc.add(UpdateMusicEvent(selectedPath)); // trigger state update
    }
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHeader(context, state.currentView), // top bar with Cancel/Save or Back
                  Divider(height: 1, color: AppColors.divider),
                  Expanded(
                    child: IndexedStack(
                      index: state.currentView.index, // switch between views
                      children: [
                        // --- Main Form View ---
                        _MainAlarmFormView(
                          scrollController: scrollController,
                          content: widget.content,
                          labelText: state.labelText,
                          music: state.music,
                          selectedDays: state.selectedDays
                              .map((d) => shortToFullDayNames[d] ?? d)
                              .toList(),
                          onLabelChanged: (val) => bloc.add(UpdateLabelEvent(val)),
                          onRepeatTap: () => bloc.add(ChangeViewEvent(PopupView.repeatSelection)),
                          onSoundTap: () => _handleSoundTap(context),
                        ),
                        // --- Repeat Selection View ---
                        RepeatSelectionView(
                          allDays: const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
                          selectedDays: state.selectedDays,
                          toggleDay: (shortName) => bloc.add(ToggleDayEvent(shortName)),
                        ),
                      ],
                    ),
                  ),
                  // Optional bottom action button
                  if (widget.showButton && state.currentView == PopupView.main)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: widget.actionButton ??
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.text,
                            ),
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

  // --- Header Row ---
  Widget _buildHeader(BuildContext context, PopupView currentView) {
    final bloc = context.read<AlarmsBloc>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentView == PopupView.main)
            TextButton(onPressed: _handleCancel, child: const Text('Cancel', style: TextStyle(color: AppColors.text))),
          if (currentView == PopupView.repeatSelection)
            TextButton.icon(
              onPressed: () => bloc.add(ChangeViewEvent(PopupView.main)),
              icon: const Icon(Icons.chevron_left, size: 26, color: AppColors.text),
              label: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            ),
          Text(currentView == PopupView.main ? widget.title : 'Repeat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text)),
          if (currentView == PopupView.main)
            TextButton(onPressed: _handleSave, child: const Text('Save', style: TextStyle(color: AppColors.text))),
          if (currentView == PopupView.repeatSelection)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// --- Main Alarm Form View ---
// Handles label, repeat summary, and sound selection rows
class _MainAlarmFormView extends StatelessWidget {
  final ScrollController scrollController;
  final Widget content;
  final String labelText;
  final String music;
  final List<String> selectedDays; // full names
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
    // Summarize days as short names for display
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
            content, // optional content (e.g., time picker)
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppColors.rowBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildSettingsRow('Repeat', daySummary, true, onRepeatTap),
                  Divider(height: 1, color: AppColors.divider),
                  _buildLabelRow(),
                  Divider(height: 1, color: AppColors.divider),
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
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 16, color: AppColors.text)),
                if (showArrow) const SizedBox(width: 8),
                if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey),
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
          const Text('Label', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'Alarm',
                hintStyle: TextStyle(color: AppColors.text, fontSize: 16),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: onLabelChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Repeat Selection View ---
// Allows toggling weekdays for repeating alarms
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
            color: AppColors.rowBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: allDays.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1,color:AppColors.divider),
            itemBuilder: (context, index) {
              final shortName = allDays[index];
              final fullName = shortToFullDayNames[shortName] ?? shortName;
              final isSelected = selectedDays.contains(shortName);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => toggleDay(shortName), // toggle day selection
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fullName, style: const TextStyle(fontSize: 16, color: AppColors.text, fontWeight: FontWeight.w600)),
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
