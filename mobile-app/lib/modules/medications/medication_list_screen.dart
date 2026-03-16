import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/modules/medications/add_medication_screen.dart';
import 'package:medtrack_mobile/modules/medications/edit_medication_screen.dart';
import 'package:medtrack_mobile/widgets/confirmation_dialog.dart';
import 'package:medtrack_mobile/modules/medications/medication_model.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationState = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        title: const Text('My Medications'),
      ),
      body: medicationState.when(
        data: (meds) {
          if (meds.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(medicationListProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.medication, size: 60, color: Colors.pink.shade200),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Your medication cabinet is empty",
                            style: TextStyle(color: Colors.pink.shade800, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap the + button to add a new medicine",
                            style: TextStyle(color: Colors.pink.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(medicationListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: meds.length,
              itemBuilder: (context, index) {
                final med = meds[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Dismissible(
                    key: Key(med.id.toString()),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await _confirmDelete(context, ref, med);
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever, color: Colors.white, size: 24),
                          SizedBox(height: 2),
                          Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
                        ],
                      ),
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => EditMedicationScreen(medication: med)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.medication_rounded, color: Colors.pink.shade700, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      med.dosage ?? 'No dosage info',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                    if (med.endDate != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          "Ends on: ${med.endDate}",
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.pink.shade600,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
          );
        },
        child: const Icon(Icons.add, size: 20),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WidgetRef ref, Medication med) async {
    bool confirmed = false;
    await ConfirmationDialog.show(
      context: context,
      title: 'Delete Medication',
      content: 'Are you sure you want to delete ${med.name}? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.redAccent,
      onConfirm: () {
        confirmed = true;
      },
    );

    if (confirmed) {
      await ref.read(medicationListProvider.notifier).removeMedication(med.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${med.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return confirmed;
  }
}
