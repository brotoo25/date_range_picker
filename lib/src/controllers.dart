import 'dart:async';

import 'package:date_range_picker/src/models.dart';
import 'package:flutter/cupertino.dart';

/// A controller that handles the logic of the date range picker.
class RangePickerController {
  RangePickerController({
    Period? period,
    required this.onPeriodChanged,
    this.minDate,
    this.maxDate,
    this.startDate,
    this.endDate,
  }) {
    if (period != null) {
      startDate = period.start;
      endDate = period.end;
    }
  }

  final ValueChanged<Period> onPeriodChanged;

  /// The minimum date that can be selected. (inclusive)
  DateTime? minDate;

  /// The maximum date that can be selected. (inclusive)
  DateTime? maxDate;

  /// The start date of the selected range.
  DateTime? startDate;

  /// The end date of the selected range.
  DateTime? endDate;

  /// Called when the user selects a date in the calendar.
  /// If the [startDate] is null, it will be set to the [date] parameter.
  /// If the [startDate] is not null and the [endDate] is null, it will be set to the [date]
  /// parameter except if the [date] is before the [startDate]. In this case, the [startDate]
  /// will be set to the [date] parameter and the [endDate] will be set to null.
  /// If the [startDate] is not null and the [endDate] is not null, the [startDate] will be set
  /// to the [date] parameter and the [endDate] will be set to null.
  void onDateChanged(DateTime date) {
    if (startDate == null) {
      startDate = date;
    } else if (endDate == null) {
      if (date.isBefore(startDate!)) {
        startDate = date;
        endDate = null;
      } else {
        endDate = date;
        onPeriodChanged(Period(
          startDate!,
          endDate!
        ));
      }
    } else {
      startDate = date;
      endDate = null;
    }
  }

  /// Returns whether the [date] is in the selected range or not.
  bool dateInSelectedRange(DateTime date) {
    if (startDate == null || endDate == null) {
      return false;
    }
    return date.isAtSameMomentAs(startDate!) ||
        date.isAtSameMomentAs(endDate!) ||
        (date.isAfter(startDate!) && date.isBefore(endDate!));
  }

  /// Returns whether the [date] is selectable or not. (i.e. if it is between the [minDate] and the [maxDate])
  bool dateIsSelectable(DateTime date) {
    if (minDate != null && date.isBefore(minDate!)) {
      return false;
    }
    if (maxDate != null && date.isAfter(maxDate!)) {
      return false;
    }
    return true;
  }

  /// Returns whether the [date] is the start of the selected range or not.
  bool dateIsStart(DateTime date) {
    if (startDate == null) {
      return false;
    }

    return date.isAtSameMomentAs(startDate!);
  }

  /// Returns whether the [date] is the end of the selected range or not.
  bool dateIsEnd(DateTime date) {
    if (endDate == null) {
      return false;
    }

    return date.isAtSameMomentAs(endDate!);
  }

  /// Returns whether the [date] is the start or the end of the selected range or not.
  /// This is useful to display the correct border radius on the day tile.
  bool dateIsStartOrEnd(DateTime date) {
    return dateIsStart(date) || dateIsEnd(date);
  }

  List<DayModel> retrieveDatesForMonth(final DateTime month) {
    // Little hack to get the number of days in the month.
    int daysInMonth = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    final List<DayModel> dayModels = [];

    for (int i = 1; i <= daysInMonth; i++) {
      var date = DateTime(month.year, month.month, i);

      dayModels.add(DayModel(
        date: date,
        isSelected: dateIsStartOrEnd(date),
        isStart: dateIsStart(date),
        isEnd: dateIsEnd(date),
        isSelectable: dateIsSelectable(date),
        isToday: date.isAtSameMomentAs(DateTime.now()),
        isInRange: dateInSelectedRange(date),
      ));
    }

    return dayModels;
  }

  /// Returns the number of days to skip at the beginning of the month.
  int retrieveDeltaForMonth(final DateTime month) {
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    return firstDayOfMonth.weekday - 1;
  }
}

/// A controller that handles the logic of the calendar widget.
class CalendarWidgetController {
  final _streamController = StreamController<void>();

  Stream<void> get updateStream => _streamController.stream;

  /// The controller that handles the logic of the date range picker.
  final RangePickerController controller;

  CalendarWidgetController({
    required this.controller,
    required DateTime currentMonth,
  }) : _currentMonth = currentMonth;

  /// The current month that is displayed.
  DateTime _currentMonth;

  /// The current month that is displayed.
  DateTime get currentMonth => _currentMonth;

  /// The current month that is displayed.
  set currentMonth(DateTime value) {
    _currentMonth = value;
    _streamController.add(null);
  }

  /// The next month that can be displayed (two months can be displayed at the same time).
  DateTime get nextMonth =>
      DateTime(currentMonth.year, currentMonth.month + 1, 1);

  /// Goes to the next month.
  void next() {
    currentMonth = nextMonth;
  }

  void onDateChanged(DateTime date) {
    controller.onDateChanged(date);
    _streamController.add(null);
  }

  /// Goes to the previous month.
  void previous() {
    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
  }

  /// Returns the dates for the current month.
  List<DayModel> retrieveDatesForMonth() {
    return controller.retrieveDatesForMonth(currentMonth);
  }

  /// Returns the dates for the next month.
  List<DayModel> retrieveDatesForNextMonth() {
    return controller.retrieveDatesForMonth(nextMonth);
  }

  /// Returns the number of days to skip at the beginning of the current month.
  int retrieveDeltaForMonth() {
    return controller.retrieveDeltaForMonth(currentMonth);
  }

  /// Returns the number of days to skip at the beginning of the next month.
  int retrieveDeltaForNextMonth() {
    return controller.retrieveDeltaForMonth(nextMonth);
  }
}