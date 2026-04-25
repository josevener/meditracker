import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medtrack_mobile/modules/medications/medication_provider.dart';
import 'package:medtrack_mobile/core/repository/medication_repository.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(toolbarHeight: 52, title: const Text('Calendar')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 1,
            shadowColor: Colors.black12,
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([
                repo.getAdherenceForMonth(_focusedDay),
                repo.getDayTicksForMonth(_focusedDay),
              ]),
              builder: (context, snapshot) {
                final adherence = (snapshot.data?[0] as Map<String, String>?) ?? {};
                final dayTicks = (snapshot.data?[1] as Set<String>?) ?? {};
                return TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.week: 'Week',
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.pink.shade700),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    formatButtonTextStyle: TextStyle(color: Colors.pink.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(fontSize: 13),
                    weekendTextStyle: const TextStyle(fontSize: 13),
                    selectedDecoration: BoxDecoration(
                      color: Colors.pink.shade600,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.pink.shade200.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink.shade200, width: 1.5),
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Colors.transparent, 
                      shape: BoxShape.circle,
                    ),
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final dateStr = DateFormat('yyyy-MM-dd').format(day);
                      final isTicked = dayTicks.contains(dateStr);
                      if (isTicked) {
                        return Positioned(
                          bottom: 4,
                          child: Icon(
                            Icons.favorite,
                            color: Colors.pink.shade600,
                            size: 14,
                          ),
                        );
                      }
                      
                      if (adherence.containsKey(dateStr)) {
                        final isCompleted = adherence[dateStr] == 'green';
                        return Positioned(
                          bottom: 4,
                          child: Icon(
                            isCompleted ? Icons.check_circle : Icons.cancel,
                            color: isCompleted ? Colors.pink.shade600 : Colors.red.shade400,
                            size: 12,
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.pink.shade600, 'Ticked', Icons.favorite),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.pink.shade600, 'Taken', Icons.check_circle),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red.shade400, 'Missed', Icons.cancel),
              ],
            ),
          ),
          _buildDailyTickButton(_selectedDay!),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 8, thickness: 1),
          ),
          Expanded(
            child: _buildDayLogs(_selectedDay!),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildDayLogs(DateTime day) {
    // ... existing _buildDayLogs code ...
    final repo = ref.watch(medicationRepositoryProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(day);

    return FutureBuilder<List<IntakeLogWithMed>>(
      future: repo.getLogsForDate(dateStr),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.pink.shade600));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  'No logs for ${DateFormat('MMM dd').format(day)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final log = entry.log;
            final isTaken = log.status == 'taken';
            final logColor = isTaken ? Colors.pink.shade600 : Colors.red.shade400;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.pink.shade50),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Details: ${entry.medName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: logColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTaken ? Icons.check_circle : Icons.error_outline,
                          color: logColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.medName} - ${entry.dosage}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.pink.shade900),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  'Scheduled: ${log.scheduledTime}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            if (log.takenAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Taken: ${DateFormat('HH:mm').format(DateTime.parse(log.takenAt!))}',
                                  style: TextStyle(fontSize: 11, color: Colors.pink.shade700, fontWeight: FontWeight.w500),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Status: Missed',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDailyTickButton(DateTime day) {
    final repo = ref.watch(medicationRepositoryProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(day);

    return FutureBuilder<bool>(
      future: repo.isDayTicked(dateStr),
      builder: (context, snapshot) {
        final isTicked = snapshot.data ?? false;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isTicked 
                ? LinearGradient(colors: [Colors.pink.shade600, Colors.pink.shade400])
                : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade100]),
              boxShadow: isTicked ? [
                BoxShadow(color: Colors.pink.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
              ] : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await repo.toggleDayTick(dateStr);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTicked ? Icons.favorite : Icons.favorite_border, 
                        color: isTicked ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isTicked ? 'Day Ticked!' : 'Tick this day',
                        style: TextStyle(
                          color: isTicked ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
