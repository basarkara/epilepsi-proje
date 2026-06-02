import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../health/appointment_store.dart';
import '../health/health_report_export_service.dart';
import '../health/seizure_log_store.dart';
import '../theme/app_theme.dart';

class HealthReportsScreen extends StatefulWidget {
  const HealthReportsScreen({super.key});

  @override
  State<HealthReportsScreen> createState() => _HealthReportsScreenState();
}

class _HealthReportsScreenState extends State<HealthReportsScreen> {
  final _monthFormat = DateFormat('MMMM yyyy', 'tr_TR');
  final _dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'tr_TR');

  List<SeizureLog> _logs = [];
  List<DoctorAppointment> _appointments = [];
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await SeizureLogStore.load();
    final appointments = await AppointmentStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _logs = logs;
      _appointments = appointments;
      _isLoading = false;
    });
  }

  Future<void> _sharePdf() async {
    await _runExport(
      () => HealthReportExportService.sharePdf(
        logs: _logs,
        appointments: _appointments,
      ),
    );
  }

  Future<void> _shareCsv() async {
    await _runExport(
      () => HealthReportExportService.shareCsv(
        logs: _logs,
        appointments: _appointments,
      ),
    );
  }

  Future<void> _runExport(Future<void> Function() action) async {
    setState(() => _isExporting = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarım başlatılamadı: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Map<DateTime, int> _monthlyCounts() {
    final now = DateTime.now();
    final months = <DateTime, int>{};
    for (var index = 5; index >= 0; index--) {
      final month = DateTime(now.year, now.month - index);
      months[DateTime(month.year, month.month)] = 0;
    }

    for (final log in _logs) {
      final month = DateTime(log.occurredAt.year, log.occurredAt.month);
      if (months.containsKey(month)) {
        months[month] = months[month]! + 1;
      }
    }
    return months;
  }

  List<SeizureLog> _logsForDay(DateTime day) {
    return _logs.where((log) => _sameDay(log.occurredAt, day)).toList();
  }

  int _countForDay(DateTime day) => _logsForDay(day).length;

  String _topTrigger() {
    final counts = <String, int>{};
    for (final log in _logs) {
      for (final trigger in log.triggers) {
        counts[trigger] = (counts[trigger] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      return 'Yok';
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLogs = _logsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistik ve Raporlama')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SummaryGrid(
                    totalCount: _logs.length,
                    thisMonthCount: _logs
                        .where(
                          (log) =>
                              log.occurredAt.year == DateTime.now().year &&
                              log.occurredAt.month == DateTime.now().month,
                        )
                        .length,
                    averageCount: _logs.isEmpty
                        ? '0'
                        : (_logs.length / 6).toStringAsFixed(1),
                    topTrigger: _topTrigger(),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Nöbet Sıklığı',
                    child: _MonthlyBarChart(monthlyCounts: _monthlyCounts()),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Doktor İçin Dışa Aktar',
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isExporting ? null : _sharePdf,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('PDF'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isExporting ? null : _shareCsv,
                            icon: const Icon(Icons.table_view),
                            label: const Text('CSV'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Takvim Görünümü',
                    child: Column(
                      children: [
                        _CalendarHeader(
                          label: _monthFormat.format(_visibleMonth),
                          onPrevious: () {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              );
                            });
                          },
                          onNext: () {
                            setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        _CalendarGrid(
                          visibleMonth: _visibleMonth,
                          selectedDay: _selectedDay,
                          countForDay: _countForDay,
                          onDaySelected: (day) {
                            setState(() => _selectedDay = day);
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay)} kayıtları',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedLogs.isEmpty)
                          Text(
                            'Bu gün için kayıt yok.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          ...selectedLogs.map(
                            (log) =>
                                _MiniLogRow(log: log, dateFormat: _dateFormat),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.totalCount,
    required this.thisMonthCount,
    required this.averageCount,
    required this.topTrigger,
  });

  final int totalCount;
  final int thisMonthCount;
  final String averageCount;
  final String topTrigger;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Toplam', totalCount.toString(), Icons.event_note),
      _SummaryItem('Bu ay', thisMonthCount.toString(), Icons.today),
      _SummaryItem('Aylık ort.', averageCount, Icons.bar_chart),
      _SummaryItem('Tetikleyici', topTrigger, Icons.flash_on),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) => _SummaryTile(item: items[index]),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({required this.monthlyCounts});

  final Map<DateTime, int> monthlyCounts;

  @override
  Widget build(BuildContext context) {
    final maxValue = monthlyCounts.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );
    final monthFormat = DateFormat('MMM', 'tr_TR');

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: monthlyCounts.entries.map((entry) {
          final ratio = entry.value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 100 * ratio + 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: entry.value == 0
                          ? AppColors.surface
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    monthFormat.format(entry.key),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.countForDay,
    required this.onDaySelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final int Function(DateTime day) countForDay;
  final ValueChanged<DateTime> onDaySelected;

  List<DateTime> _days() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final leadingDays = firstDay.weekday - 1;
    final start = firstDay.subtract(Duration(days: leadingDays));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    const weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Column(
      children: [
        Row(
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          itemCount: 42,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final day = _days()[index];
            final isCurrentMonth = day.month == visibleMonth.month;
            final isSelected = _sameDay(day, selectedDay);
            final count = countForDay(day);

            return Material(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onDaySelected(day),
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.background
                            : isCurrentMonth
                            ? AppColors.white
                            : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.background,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MiniLogRow extends StatelessWidget {
  const _MiniLogRow({required this.log, required this.dateFormat});

  final SeizureLog log;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.type, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  dateFormat.format(log.occurredAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
