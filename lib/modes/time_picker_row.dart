import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Picker modes
enum TimePickerMode { full, ampm }

/// A large factor used to simulate infinite scrolling by centering the initial selection.
const int _kInfiniteFactor = 500;

/// A row of pickers for either full 24h (h/m/s) or AM/PM mode.
class TimePickerRow extends StatefulWidget {
  final void Function(int hours24, int minutes, int seconds)? onChanged;
  final TimePickerMode mode;
  final DateTime? initialTime; // optional for edit/create
  final double height;
  final double widthFactor;
  final Color overlayColor;

  const TimePickerRow({
    super.key,
    this.onChanged,
    this.mode = TimePickerMode.full,
    this.initialTime,
    this.height = 0.15,
    this.widthFactor = 0.25,
    this.overlayColor = const Color.fromARGB(80, 70, 100, 150),
    //this.overlayColor = const Color.fromARGB(60, 255, 165, 0),

  });

  @override
  State<TimePickerRow> createState() => _TimePickerRowState();
}

class _TimePickerRowState extends State<TimePickerRow> {
  late FixedExtentScrollController hourCtrl;
  late FixedExtentScrollController minCtrl;
  late FixedExtentScrollController secCtrl;
  late FixedExtentScrollController ampmCtrl;

  // ⚡ Initialize variables based on mode
  int hours = 0; // 0–23 for full, 1–12 for am/pm
  int minutes = 0;
  int seconds = 0;
  bool isAm = true;

  @override
  void initState() {
    super.initState();
    hourCtrl = FixedExtentScrollController();
    minCtrl = FixedExtentScrollController();
    secCtrl = FixedExtentScrollController();
    ampmCtrl = FixedExtentScrollController();

    // Use current time or provided initialTime
    final now = widget.initialTime ?? DateTime.now();

    if (widget.mode == TimePickerMode.ampm) {
      // AM/PM mode setup (Infinite scrolling logic)
      hours = now.hour % 12;
      if (hours == 0) hours = 12; // 0 becomes 12 for 12 AM
      minutes = now.minute;
      isAm = now.hour < 12;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Jump to a centered index for infinite scroll

        // AM/PM Hours are 1-indexed (1 through 12), so we use hours - 1 for 0-indexed jump.
        final initialHourIndex = 12 * _kInfiniteFactor + (hours - 1);

        // Minutes are 0-indexed (0 through 59).
        final initialMinIndex = 60 * _kInfiniteFactor + minutes;

        hourCtrl.jumpToItem(initialHourIndex);
        minCtrl.jumpToItem(initialMinIndex);

        // AM/PM picker is not infinite, so it jumps to 0 or 1.
        ampmCtrl.jumpToItem(isAm ? 0 : 1);
      });
    } else {
      // ⚡ Full mode (h/m/s) setup (Finite, 0:00:00 default if no initialTime)
      if (widget.initialTime != null) {
        // Use the provided time
        hours = now.hour;
        minutes = now.minute;
        seconds = now.second;
      } else {
        // Use 0:00:00 if no initialTime provided
        hours = 0;
        minutes = 0;
        seconds = 0;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // For finite pickers, jump directly to the index.
        hourCtrl.jumpToItem(hours);
        minCtrl.jumpToItem(minutes);
        secCtrl.jumpToItem(seconds);
      });
    }
  }

  @override
  void dispose() {
    hourCtrl.dispose();
    minCtrl.dispose();
    secCtrl.dispose();
    ampmCtrl.dispose();
    super.dispose();
  }

  /// Returns hours in 24h format
  int getHours24() {
    if (widget.mode == TimePickerMode.ampm) {
      int h = hours % 12; // converts 12 to 0
      if (!isAm) h += 12; // adds 12 if PM, converting 0 (12 PM) to 12, and 1-11 to 13-23
      return h;
    }
    return hours;
  }

  void _updateTime() {
    // We only call onChanged with the 24h format, regardless of mode.
    widget.onChanged?.call(getHours24(), minutes, seconds);
  }

  // NOTE: This _buildPicker is used for the *finite* Full Mode (h/m/s)
  Widget _buildPicker(
      String label,
      FixedExtentScrollController controller,
      int count,
      void Function(int) onChanged,
      bool showLeadingZero,
      ) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.height,
      width: MediaQuery.of(context).size.width * widget.widthFactor,
      child: CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: 40,
        // Since this is finite (count = 24 or 60), the index is the value itself
        onSelectedItemChanged: onChanged,
        selectionOverlay: Container(color: widget.overlayColor),
        childCount: count,
        itemBuilder: (context, index) {
          String text = '$index';
          if (showLeadingZero) {
            text = index.toString().padLeft(2, '0');
          }
          return Center(
            child: Text(
              '$text $label',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  /// Builds circular hours picker (1–12) for AM/PM mode
  Widget _buildHourPicker() {
    const int count = 12;
    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.height,
      width: MediaQuery.of(context).size.width * widget.widthFactor,
      child: CupertinoPicker.builder(
        scrollController: hourCtrl,
        itemExtent: 40,
        // Large number for infinite feel
        childCount: count * 1000,
        onSelectedItemChanged: (index) {
          // Calculate the 1-based hour (1-12) from the 0-indexed index.
          hours = (index % count) + 1;
          _updateTime();
        },
        selectionOverlay: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: widget.overlayColor),
        ),
        itemBuilder: (context, index) {
          final displayHour = (index % count) + 1;
          return Center(
            child: Text(
              '$displayHour ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  /// Builds circular minutes picker (00–59) for AM/PM mode
  Widget _buildMinPicker() {
    const int count = 60;
    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.height,
      width: MediaQuery.of(context).size.width * widget.widthFactor,
      child: CupertinoPicker.builder(
        scrollController: minCtrl,
        itemExtent: 40,
        // Large number for "infinite" circular feel
        childCount: count * 1000,
        onSelectedItemChanged: (index) {
          minutes = index % count; // wrap around using modulo
          _updateTime();
        },
        selectionOverlay: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: widget.overlayColor),
        ),
        itemBuilder: (context, index) {
          final displayMin = (index % count).toString().padLeft(2, '0'); // 00–59
          return Center(
            child: Text(
              '$displayMin ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }


  /// Builds the AM/PM picker (not infinite)
  Widget _buildAmPmPicker() {
    // This picker is intentionally kept finite (2 items)
    return SizedBox(
      height: MediaQuery.of(context).size.height * widget.height,
      width: MediaQuery.of(context).size.width * 0.2,
      child: CupertinoPicker(
        scrollController: ampmCtrl,
        itemExtent: 40,
        onSelectedItemChanged: (index) {
          setState(() => isAm = index == 0);
          _updateTime();
        },
        selectionOverlay: Container(color: widget.overlayColor),
        children: const [
          Center(child: Text('AM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Center(child: Text('PM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == TimePickerMode.ampm) {
      // ⚡ AM/PM Mode (Infinite hours and minutes, Finite AM/PM)
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHourPicker(),
          _buildMinPicker(),
          _buildAmPmPicker(),
        ],
      );
    } else {
      //  Full Mode (h/m/s) - All are Finite
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hours 0-23 (no padding)
          _buildPicker('h', hourCtrl, 24, (v) {
            setState(() => hours = v);
            _updateTime();
          }, false),
          // Minutes 0-59 (with padding)
          _buildPicker('m', minCtrl, 60, (v) {
            setState(() => minutes = v);
            _updateTime();
          }, true),
          // Seconds 0-59 (with padding)
          _buildPicker('s', secCtrl, 60, (v) {
            setState(() => seconds = v);
            _updateTime();
          }, true),
        ],
      );
    }
  }
}
