import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final supabase = Supabase.instance.client;


class Counselor {
  final int id;
  final String name;

  Counselor({required this.id, required this.name});

  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}



class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {

  List<Counselor> counselors = [];
  bool isLoadingCounselors = true;

  @override
  void initState() {
    super.initState();
    fetchCounselors();
  }

  Future<void> fetchCounselors() async {
    try {
      final response = await supabase.from('counselors').select();
      setState(() {
        counselors = (response as List)
            .map((c) => Counselor.fromJson(c))
            .toList();
        isLoadingCounselors = false;
      });
    } catch (e) {
      print('Error fetching counselors: $e');
      setState(() {
        isLoadingCounselors = false;
      });
    }
  }

  Counselor? selectedCounselor;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;



  Future<bool> checkAvailability(int counselorId, DateTime date, TimeOfDay time) async {

    final appointmentDate = date.toIso8601String().split('T')[0];

    final appointmentTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    try {
      final response = await supabase
          .from('appointment')
          .select()
          .eq('conselor_id', counselorId)
          .eq('date', appointmentDate)
          .eq('time', appointmentTime)
          .neq('status', 'rejected');

      return (response as List).isEmpty;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }




  Future<void> bookAppointment() async {
    if (selectedCounselor == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a counselor and time.')),
      );
      return;
    }

    bool available = await checkAvailability(selectedCounselor!.id, selectedDate, selectedTime!);
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected slot is unavailable.')),
      );
      return;
    }

    final appointmentDate = selectedDate.toIso8601String().split('T')[0];
    final appointmentTime = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

    await supabase.from('appointment').insert({
      'user_id': 24,
      'conselor_id': selectedCounselor!.id,
      'date': appointmentDate,
      'time': appointmentTime,
      'status': 'pending',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment booked successfully!')),
    );
  }


  List<TimeOfDay> generateTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int hour = 9; hour <= 17; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      slots.add(TimeOfDay(hour: hour, minute: 30));
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = generateTimeSlots();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Counselor:'),
            DropdownButton<Counselor>(
              value: selectedCounselor,
              hint: isLoadingCounselors
                  ? const Text('Loading...')
                  : const Text('Choose a counselor'),
              items: counselors
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCounselor = val),
            ),

            const SizedBox(height: 16),
            const Text('Select Date:'),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select Time:'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: timeSlots.map((t) {
                return ChoiceChip(
                  label: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'),
                  selected: selectedTime == t,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        selectedTime = t;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: bookAppointment,
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
