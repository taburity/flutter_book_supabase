import "appointments_model.dart";
import "package:supabase_flutter/supabase_flutter.dart";


/// Classe que provê acesso ao banco de dados para gerenciar compromissos.
class AppointmentsDBWorker {

  /// Static instance and private constructor, since this is a singleton.
  AppointmentsDBWorker._();
  static final AppointmentsDBWorker db = AppointmentsDBWorker._();

  /// Create a Appointment from a Map.
  Appointment appointmentFromMap(Map inMap) {
    print("## appointments AppointmentsDBWorker.appointmentFromMap(): inMap = $inMap");
    Appointment appointment = Appointment(
      id: inMap["id"],
      title: inMap["title"],
      description: inMap["description"],
      apptDate: inMap["appt_date"],
      apptTime: inMap["appt_time"],
      createdBy: inMap["created_by"],
      sharedWith: inMap["shared_with"],
      status: inMap["status"]
    );
    print("## appointments AppointmentsDBWorker.appointmentFromMap(): appointment = $appointment");
    return appointment;
  }

  /// Create a Map from a Appointment.
  Map<String, dynamic> appointmentToMap(Appointment inAppointment) {
    print("## appointments AppointmentsDBWorker.appointmentToMap(): inAppointment = $inAppointment");
    Map<String, dynamic> map = Map<String, dynamic>();
    map["id"] = inAppointment.id;
    map["title"] = inAppointment.title;
    map["description"] = inAppointment.description;
    map["appt_date"] = inAppointment.apptDate;
    map["appt_time"] = inAppointment.apptTime;
    map["created_by"] = inAppointment.createdBy;
    map["shared_with"] = inAppointment.sharedWith;
    map["status"] = inAppointment.status;
    print("## appointments AppointmentsDBWorker.appointmentToMap(): map = $map");
    return map;
  }

  /// Create a appointment.
  ///
  /// @param inAppointment the Appointment object to create.
  Future create(Appointment inAppointment, String? otherUser) async {
    print("## appointments AppointmentsDBWorker.create(): inAppointment = $inAppointment");
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    return await supabase.from('appointments').insert({
      'title': inAppointment.title,
      'description': inAppointment.description,
      'appt_date': inAppointment.apptDate,
      'appt_time': inAppointment.apptTime,
      'created_by': userId,
      'shared_with': otherUser,
      'status': otherUser != null ? 'accepted' : null,
    }).select();
  }

  /// Get a specific appointment.
  ///
  /// @param  inID The ID of the appointment to get.
  /// @return      The corresponding Appointment object.
  Future<Appointment> get(String inID) async {
    print("## appointments AppointmentsDBWorker.get(): inID = $inID");
    final response = await Supabase.instance.client
        .from('appointments')
        .select()
        .eq('id', inID)
        .single();
    print("## appointments AppointmentsDBWorker.get(): $response");
    return appointmentFromMap(response);
  }

  /// Get all appointments.
  ///
  /// @return A List of Appointment objects.
  Future<List<Appointment>> getAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final response = await Supabase.instance.client
        .from('appointments')
        .select()
        .or('created_by.eq.$userId,shared_with.eq.$userId');
    var list = response.map<Appointment>((a) => appointmentFromMap(a)).toList();
    print("## appointments AppointmentsDBWorker.getAll(): list = $list");
    return list;
  }

  /// Update a appointment.
  ///
  /// @param inAppointment The appointment to update.
  Future update(Appointment inAppointment) async {
    print("## appointments AppointmentsDBWorker.update(): inAppointment = $inAppointment");
    final supabase = Supabase.instance.client;
    return await supabase.from('appointments').update({
      'title': inAppointment.title,
      'description': inAppointment.description,
      'appt_date': inAppointment.apptDate,
      'appt_time': inAppointment.apptTime,
    }).eq('id', inAppointment.id!);
  }

  /// Delete a appointment.
  ///
  /// @param inID The ID of the appointment to delete.
  Future delete(String inID) async {
    print("## appointments AppointmentsDBWorker.delete(): inID = $inID");
    return await Supabase.instance.client
        .from('appointments')
        .delete()
        .eq('id', inID);
  }


}