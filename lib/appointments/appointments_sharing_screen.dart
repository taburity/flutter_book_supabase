import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'appointments_model.dart';

class AppointmentsSharingScreen extends StatefulWidget {
  @override
  _AppointmentsSharingScreenState createState() => _AppointmentsSharingScreenState();
}

class _AppointmentsSharingScreenState extends State<AppointmentsSharingScreen> {
  final supabase = Supabase.instance.client;
  List<Appointment> sharedAppointments = [];

  @override
  void initState() {
    super.initState();
    fetchSharedAppointments();
  }

  Future<void> fetchSharedAppointments() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('appointments')
        .select()
        .eq('shared_with', userId!)
        .eq('status', 'pending');

    List<Appointment> sharedAppts = response.map<Appointment>((e) {
      final a = e['appointments'];
      return Appointment(
        id: a['id'],
        title: a['title'],
        description: a['description'],
        apptDate: a['appt_date'],
        apptTime: a['appt_time'],
      );
    }).toList();

    setState(() {
      sharedAppointments = sharedAppts;
    });
  }

  Future<void> updateAppointmentStatus(int appointmentId, String status) async {
    await supabase
        .from('appointments')
        .update({'status': status})
        .match({'id': appointmentId});
    fetchSharedAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appointment Invitations')),
      body: ListView.builder(
        itemCount: sharedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = sharedAppointments[index];

          String apptTime = "";
          if (appointment.apptTime != null) {
            List timeParts = appointment.apptTime!.split(",");
            TimeOfDay at = TimeOfDay(
                hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])
            );
            apptTime = " (${at.format(context)})";
          }

          return Card(
            child: ListTile(
              title: Text(appointment.title),
              subtitle: apptTime.isEmpty? Text("Data: ${appointment.apptDate}") : Text("Data: ${appointment.apptDate} - ${apptTime}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => updateAppointmentStatus(appointment.id!, 'accepted'),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => updateAppointmentStatus(appointment.id!, 'rejected'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
