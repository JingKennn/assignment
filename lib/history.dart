import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointment.dart';


final supabase = Supabase.instance.client;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Appointment> _historyAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistoryAppointments();
  }

  Future<void> _fetchHistoryAppointments() async {
    setState(() => _isLoading = true);
    try {

      final DateTime now = DateTime.now();
      final String todayString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('appointment')
          .select('id, status, date, time, conselor_id(name)')
          .eq('user_id', 24)
          .lt('date', todayString)
          .order('date', ascending: false);

      final appointments = (response as List)
          .map((item) => Appointment.fromJson(item))
          .toList();

      setState(() => _historyAppointments = appointments);
    } catch (e) {
      print('Error fetching history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAppointment(Appointment appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment?'),
        content: Text(
            'Are you sure you want to delete this appointment with '
                '${appointment.counselorName ?? 'counselor'} '
                'on ${appointment.date} at ${appointment.time}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      await supabase.from('appointment').delete().eq('id', appointment.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment deleted from history')),
      );

      _fetchHistoryAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _historyAppointments.isEmpty
            ? const Center(child: Text('No past appointments'))
            : ListView.builder(
          itemCount: _historyAppointments.length,
          itemBuilder: (context, index) {
            final appt = _historyAppointments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appt.counselorName ?? 'Unknown Counselor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          appt.status?.toUpperCase() ?? '',
                          style: TextStyle(
                            color: appt.status == 'cancelled'
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(appt.date),
                        Text(appt.time),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _deleteAppointment(appt),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}