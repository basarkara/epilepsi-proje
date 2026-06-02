import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../health/seizure_log_store.dart';
import '../theme/app_theme.dart';

class SeizureLogScreen extends StatefulWidget {
  const SeizureLogScreen({super.key});

  @override
  State<SeizureLogScreen> createState() => _SeizureLogScreenState();
}

class _SeizureLogScreenState extends State<SeizureLogScreen> {
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'tr_TR');

  final Map<String, bool> _triggers = {
    'Uykusuzluk': false,
    'Stres': false,
    'Parlak ışık': false,
    'İlaç atlama': false,
    'Yorgunluk': false,
  };

  List<SeizureLog> _logs = [];
  String _selectedType = 'Tonik-Klonik';
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final logs = await SeizureLogStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveLog() async {
    final activeTriggers = _triggers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final log = SeizureLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: _selectedType,
      occurredAt: _selectedDateTime,
      triggers: activeTriggers,
      durationMinutes: duration,
      notes: _notesController.text.trim(),
    );

    await SeizureLogStore.add(log);
    if (!mounted) {
      return;
    }

    _notesController.clear();
    _durationController.clear();
    setState(() {
      _selectedDateTime = DateTime.now();
      _triggers.updateAll((key, value) => false);
    });
    await _loadLogs();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nöbet kaydı eklendi.')));
  }

  Future<void> _deleteLog(SeizureLog log) async {
    await SeizureLogStore.delete(log.id);
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nöbet Günlüğü'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Yeni Nöbet Girişi', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                _EntryCard(
                  selectedType: _selectedType,
                  selectedDateTime: _selectedDateTime,
                  triggers: _triggers,
                  durationController: _durationController,
                  notesController: _notesController,
                  onTypeChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                  onTriggerChanged: (key, value) {
                    setState(() => _triggers[key] = value);
                  },
                  onPickDateTime: _pickDateTime,
                  onSave: _saveLog,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Geçmiş Nöbetler (${_logs.length})',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadLogs,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_logs.isEmpty)
                  const _EmptyState()
                else
                  ..._logs.map(
                    (log) => _LogCard(
                      log: log,
                      dateFormat: _dateFormat,
                      onDelete: () => _deleteLog(log),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.selectedType,
    required this.selectedDateTime,
    required this.triggers,
    required this.durationController,
    required this.notesController,
    required this.onTypeChanged,
    required this.onTriggerChanged,
    required this.onPickDateTime,
    required this.onSave,
  });

  final String selectedType;
  final DateTime selectedDateTime;
  final Map<String, bool> triggers;
  final TextEditingController durationController;
  final TextEditingController notesController;
  final ValueChanged<String?> onTypeChanged;
  final void Function(String key, bool value) onTriggerChanged;
  final VoidCallback onPickDateTime;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'tr_TR');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedType,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
              labelText: 'Nöbet türü',
            ),
            dropdownColor: AppColors.card,
            items: const ['Tonik-Klonik', 'Absans', 'Fokal', 'Diğer']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickDateTime,
            icon: const Icon(Icons.schedule),
            label: Text(dateFormat.format(selectedDateTime)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.timer_outlined),
              labelText: 'Süre',
              hintText: 'Dakika olarak yaz',
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tetikleyiciler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: triggers.entries.map((entry) {
              return FilterChip(
                label: Text(entry.key),
                selected: entry.value,
                onSelected: (value) => onTriggerChanged(entry.key, value),
                selectedColor: AppColors.primary,
                checkmarkColor: AppColors.background,
                labelStyle: TextStyle(
                  color: entry.value ? AppColors.background : AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_outlined),
              labelText: 'Not',
              hintText: 'Belirti, toparlanma süresi veya ek açıklama',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.dateFormat,
    required this.onDelete,
  });

  final SeizureLog log;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.type, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(log.occurredAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tetikleyici: ${log.triggerLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
                if (log.durationMinutes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Süre: ${log.durationMinutes} dk',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (log.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    log.notes,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.grey,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Sil',
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Henüz nöbet kaydı yok. İlk kaydı eklediğinde raporlar ve takvim otomatik güncellenecek.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
