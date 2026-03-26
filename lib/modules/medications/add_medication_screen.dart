import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_model.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/services/notification_service.dart';

import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _startDateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _endDateController = TextEditingController();
  List<TimeOfDay> _selectedTimes = [];

  bool _isSaving = false;

  bool get _isDirty => _nameController.text.isNotEmpty || _dosageController.text.isNotEmpty || _selectedTimes.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && !_selectedTimes.contains(picked)) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one schedule time')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final medication = Medication(
          name: _nameController.text,
          dosage: _dosageController.text,
          frequencyPerDay: _selectedTimes.length,
          startDate: _startDateController.text,
          endDate: _endDateController.text.isEmpty ? null : _endDateController.text,
          schedules: _selectedTimes
              .map((t) => Schedule(
                  timeOfDay: "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}"))
              .toList(),
        );

        await ref.read(medicationListProvider.notifier).addMedication(medication);

        for (var t in _selectedTimes) {
          final now = DateTime.now();
          var scheduledTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }

          await NotificationService().scheduleNotification(
            id: scheduledTime.millisecondsSinceEpoch ~/ 1000,
            title: 'Medication Reminder',
            body: 'Time to take ${_nameController.text}',
            scheduledDate: scheduledTime,
          );
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving medication: $e')),
          );
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    bool shouldPop = false;
    await ConfirmationDialog.show(
      context: context,
      title: 'Discard Changes?',
      content: 'You have unsaved changes. Are you sure you want to leave?',
      confirmText: 'Discard',
      confirmColor: Colors.redAccent,
      onConfirm: () => shouldPop = true,
    );
    return shouldPop;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 52, title: const Text('Add Medication')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Basic Information'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          prefixIcon: Icon(Icons.medication, size: 20),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dosageController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Dosage (e.g., 500mg, 1 pill)',
                          prefixIcon: Icon(Icons.scale, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionTitle('Schedules'),
              Card(
                child: Column(
                  children: [
                    if (_selectedTimes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('No times added yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ..._selectedTimes.map((t) => ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.access_time, size: 20, color: Colors.pink.shade300),
                          title: Text(t.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() => _selectedTimes.remove(t)),
                          ),
                        )),
                    const Divider(height: 1),
                    TextButton.icon(
                      onPressed: _addTime,
                      icon: const Icon(Icons.add_alarm, size: 18),
                      label: const Text('Add Intake Time', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: Colors.pink.shade600,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionTitle('Duration'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _startDateController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                          hintText: 'YYYY-MM-DD',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _endDateController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'End Date (Optional)',
                          prefixIcon: Icon(Icons.event_available, size: 20),
                          hintText: 'YYYY-MM-DD',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('SAVE MEDICATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.pink.shade800,
        ),
      ),
    );
  }
}
