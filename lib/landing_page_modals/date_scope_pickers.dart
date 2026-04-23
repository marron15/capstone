import 'package:flutter/material.dart';

// ── Public API ────────────────────────────────────────────────────────────────

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
