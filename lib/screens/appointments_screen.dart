import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../emergency/emergency_notification_service.dart';
import '../health/appointment_store.dart';
import '../theme/app_theme.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _doctorController = TextEditingController();
  final _clinicController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy - HH:mm', 'tr_TR');

  List<DoctorAppointment> _appointments = [];
  DateTime _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _clinicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final appointments = await AppointmentStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _appointments = appointments;
      _isLoading = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 720)),
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

  Future<void> _saveAppointment() async {
    final doctorName = _doctorController.text.trim();
    if (doctorName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Doktor adı gerekli.')));
      return;
    }

    final notificationId =
        Object.hash(doctorName, _selectedDateTime.millisecondsSinceEpoch) &
        0x7fffffff;
    final appointment = DoctorAppointment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      doctorName: doctorName,
      clinicName: _clinicController.text.trim(),
      dateTime: _selectedDateTime,
      notes: _notesController.text.trim(),
      notificationId: notificationId,
    );

    await AppointmentStore.add(appointment);
    await EmergencyNotificationService.scheduleAppointmentReminder(
      id: notificationId,
      doctorName: appointment.doctorName,
      clinicName: appointment.clinicName,
      appointmentDateTime: appointment.dateTime,
    );

    if (!mounted) {
      return;
    }
    _doctorController.clear();
    _clinicController.clear();
    _notesController.clear();
    setState(() {
      _selectedDateTime = DateTime.now().add(const Duration(days: 1));
    });
    await _loadAppointments();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Randevu kaydedildi.')));
  }

  Future<void> _deleteAppointment(DoctorAppointment appointment) async {
    await EmergencyNotificationService.cancelNotification(
      appointment.notificationId,
    );
    await AppointmentStore.delete(appointment.id);
    await _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments.where((item) => !item.isPast).toList();
    final past = _appointments.where((item) => item.isPast).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Doktor Randevuları')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _AppointmentForm(
                  doctorController: _doctorController,
                  clinicController: _clinicController,
                  notesController: _notesController,
                  selectedDateTime: _selectedDateTime,
                  dateFormat: _dateFormat,
                  onPickDateTime: _pickDateTime,
                  onSave: _saveAppointment,
                ),
                const SizedBox(height: 24),
                Text(
                  'Yaklaşan Randevular',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  const _AppointmentEmptyState(label: 'Yaklaşan randevu yok.')
                else
                  ...upcoming.map(
                    (appointment) => _AppointmentCard(
                      appointment: appointment,
                      dateFormat: _dateFormat,
                      onDelete: () => _deleteAppointment(appointment),
                    ),
                  ),
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Geçmiş Randevular',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ...past.map(
                    (appointment) => _AppointmentCard(
                      appointment: appointment,
                      dateFormat: _dateFormat,
                      onDelete: () => _deleteAppointment(appointment),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _AppointmentForm extends StatelessWidget {
  const _AppointmentForm({
    required this.doctorController,
    required this.clinicController,
    required this.notesController,
    required this.selectedDateTime,
    required this.dateFormat,
    required this.onPickDateTime,
    required this.onSave,
  });

  final TextEditingController doctorController;
  final TextEditingController clinicController;
  final TextEditingController notesController;
  final DateTime selectedDateTime;
  final DateFormat dateFormat;
  final VoidCallback onPickDateTime;
  final VoidCallback onSave;

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
        children: [
          TextField(
            controller: doctorController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.medical_services_outlined),
              labelText: 'Doktor adı',
              hintText: 'Örn. Dr. Ayşe Yılmaz',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: clinicController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.local_hospital_outlined),
              labelText: 'Klinik / Hastane',
              hintText: 'İsteğe bağlı',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickDateTime,
            icon: const Icon(Icons.event),
            label: Text(dateFormat.format(selectedDateTime)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.notes_outlined),
              labelText: 'Not',
              hintText: 'Götürülecek raporlar, sorulacak sorular',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.add),
              label: const Text('Randevu ekle'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.dateFormat,
    required this.onDelete,
  });

  final DoctorAppointment appointment;
  final DateFormat dateFormat;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = appointment.isPast ? AppColors.muted : AppColors.primary;

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
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event_available, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(appointment.dateTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (appointment.clinicName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.clinicName,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
                  ),
                ],
                if (appointment.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    appointment.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _AppointmentEmptyState extends StatelessWidget {
  const _AppointmentEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
