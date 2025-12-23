import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking.dart';
import 'edit.dart';
import 'appointment.dart';
import 'history.dart';

final supabase = Supabase.instance.client;

class ViewBooking extends StatefulWidget {
  const ViewBooking({super.key});

  @override
  State<ViewBooking> createState() => _ViewBookingState();
}

class _ViewBookingState extends State<ViewBooking> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('appointment')
          .select('id, status, date, time, conselor_id(name)')
          .eq('user_id', 24)
          .inFilter('status', ['pending', 'approved'])
          .order('date');

      final appointments = (response as List)
          .map((item) => Appointment.fromJson(item))
          .where((appt) {
        final apptDate = DateTime.parse(appt.date);
        return apptDate.isAfter(DateTime.now().subtract(const Duration(days: 1)));
      }).toList();

      setState(() => _appointments = appointments);
    } catch (e) {
      print('Error fetching appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch appointments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _editAppointment(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookingPage(appointment: appointment),
      ),
    ).then((value) {
      if (value == true) {
        _fetchAppointments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
            ? const Center(child: Text('No upcoming appointments'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Appointment:'),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appt = _appointments[index];
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
                                appt.counselorName ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                appt.status ?? '',
                                style: TextStyle(
                                  color: appt.status?.toLowerCase() == 'pending'
                                      ? Colors.orange
                                      : appt.status?.toLowerCase() == 'approved'
                                      ? Colors.green
                                      : Colors.red,
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () => _editAppointment(appt),
                              child: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookingPage()),
                        );
                        if (result == true) {
                          _fetchAppointments();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 20),
                      ),
                      child: const Text('Booking'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 160,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryPage()),
                        ).then((_) {
                          _fetchAppointments();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 20),
                        side: const BorderSide(width: 2),
                      ),
                      child: const Text('History'),
                    ),
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
