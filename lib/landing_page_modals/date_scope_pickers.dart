import 'package:flutter/material.dart';

// ── Public API ────────────────────────────────────────────────────────────────

/// First day of the current month through last second of the current month.
DateTimeRange currentMonthDateRange() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(
    now.year,
    now.month + 1,
    1,
  ).subtract(const Duration(seconds: 1));
  return DateTimeRange(start: start, end: end);
}

String formatDateRangeLabel(DateTimeRange range) {
  String fmt(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  return '${fmt(range.start)} - ${fmt(range.end)}';
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isCurrentMonthRange(DateTimeRange range) {
  final current = currentMonthDateRange();
  return isSameCalendarDay(range.start, current.start) &&
      isSameCalendarDay(range.end, current.end);
}

/// Compares calendar dates only (ignores time-of-day on [date]).
bool isDateWithinRange(DateTime date, DateTimeRange range) {
  final local = date.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final start = DateTime(
    range.start.year,
    range.start.month,
    range.start.day,
  );
  final end = DateTime(range.end.year, range.end.month, range.end.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

/// Audit-log style start/end date picker. Returns null when cancelled.
/// "Clear (This Month)" returns [currentMonthDateRange].
Future<DateTimeRange?> showDateRangePickerDialog(
  BuildContext context, {
  DateTimeRange? initialRange,
  int yearsBack = 5,
  int yearsForward = 5,
}) async {
  final DateTime now = DateTime.now();
  final DateTimeRange seed = initialRange ?? currentMonthDateRange();
  final DateTime? startInitial = seed.start;
  final DateTime? endInitial = seed.end;

  return showDialog<DateTimeRange?>(
    context: context,
    builder: (ctx) {
      DateTime? localStart = startInitial;
      DateTime? localEnd = endInitial;

      Future<void> pickStart(StateSetter setModalState) async {
        final res = await showDatePicker(
          context: ctx,
          initialDate: localStart ?? now,
          firstDate: DateTime(now.year - yearsBack),
          lastDate: DateTime(now.year + yearsForward),
          helpText: 'Select start date',
        );
        if (res != null) {
          final normalized = DateTime(res.year, res.month, res.day);
          if (localEnd != null && localEnd!.isBefore(normalized)) {
            localEnd = normalized;
          }
          setModalState(() => localStart = normalized);
        }
      }

      Future<void> pickEnd(StateSetter setModalState) async {
        final res = await showDatePicker(
          context: ctx,
          initialDate: localEnd ?? localStart ?? now,
          firstDate: DateTime(now.year - yearsBack),
          lastDate: DateTime(now.year + yearsForward),
          helpText: 'Select end date',
        );
        if (res != null) {
          final normalized = DateTime(
            res.year,
            res.month,
            res.day,
            23,
            59,
            59,
          );
          if (localStart != null && normalized.isBefore(localStart!)) {
            return;
          }
          setModalState(() => localEnd = normalized);
        }
      }

      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Select date range'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    localStart == null
                        ? 'Select start date'
                        : '${localStart!.month.toString().padLeft(2, '0')}/${localStart!.day.toString().padLeft(2, '0')}/${localStart!.year}',
                  ),
                  onTap: () => pickStart(setState),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(
                    localEnd == null
                        ? 'Select end date'
                        : '${localEnd!.month.toString().padLeft(2, '0')}/${localEnd!.day.toString().padLeft(2, '0')}/${localEnd!.year}',
                  ),
                  onTap: () => pickEnd(setState),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(currentMonthDateRange()),
                child: const Text('Clear (This Month)'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    localStart == null || localEnd == null
                        ? null
                        : () => Navigator.of(ctx).pop(
                          DateTimeRange(start: localStart!, end: localEnd!),
                        ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Opens a month-grid picker dialog.
/// Returns a [DateTime] with day=1 for the chosen month, or null if cancelled.
Future<DateTime?> showMonthPickerDialog(
  BuildContext context,
  DateTime initialDate,
) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthPickerDialog(initialDate: initialDate),
  );
}

/// Opens a year-list picker dialog.
/// Returns the selected year as [int], or null if cancelled.
Future<int?> showYearPickerDialog(BuildContext context, int initialYear) {
  return showDialog<int>(
    context: context,
    builder: (_) => _YearPickerDialog(initialYear: initialYear),
  );
}

// ── Month Picker ──────────────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initialDate});
  final DateTime initialDate;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _displayYear;
  late int _selectedMonth;
  late int _selectedYear;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _displayYear = widget.initialDate.year;
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _displayYear > 2020
                ? () => setState(() => _displayYear--)
                : null,
          ),
          Text(
            '$_displayYear',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _displayYear < now.year
                ? () => setState(() => _displayYear++)
                : null,
          ),
        ],
      ),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 12,
          itemBuilder: (ctx, i) {
            final monthNum = i + 1;
            final isSelected =
                monthNum == _selectedMonth && _displayYear == _selectedYear;
            final isDisabled =
                _displayYear == now.year && monthNum > now.month;

            return Material(
              color: isSelected
                  ? const Color(0xFFFFA812)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isDisabled
                    ? null
                    : () {
                        setState(() {
                          _selectedMonth = monthNum;
                          _selectedYear = _displayYear;
                        });
                        Navigator.of(context)
                            .pop(DateTime(_displayYear, monthNum));
                      },
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    _months[i],
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey.shade400
                          : isSelected
                              ? Colors.black
                              : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// ── Year Picker ───────────────────────────────────────────────────────────────

class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog({required this.initialYear});
  final int initialYear;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final years = _years();
    final idx = years.indexOf(widget.initialYear);
    _scrollController = ScrollController(
      initialScrollOffset: idx > 1 ? (idx - 1) * 52.0 : 0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _years() {
    final now = DateTime.now();
    return List.generate(now.year - 2019, (i) => 2020 + i);
  }

  @override
  Widget build(BuildContext context) {
    final years = _years();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Year',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 200,
        height: 280,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: years.length,
          itemBuilder: (ctx, i) {
            final year = years[i];
            final isSelected = year == widget.initialYear;

            return ListTile(
              title: Text(
                '$year',
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.normal,
                  color:
                      isSelected ? const Color(0xFFFFA812) : Colors.black87,
                  fontSize: isSelected ? 16 : 14,
                ),
              ),
              selected: isSelected,
              selectedTileColor:
                  const Color(0xFFFFA812).withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              onTap: () => Navigator.of(context).pop(year),
            );
          },
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
