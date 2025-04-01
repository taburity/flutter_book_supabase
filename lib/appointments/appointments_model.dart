import "../base_model.dart";
import "appointments_dbworker.dart";


///Uma classe que representa um compromisso.
class Appointment {
  String? id;
  String title;
  String description;
  String apptDate; // YYYY,MM,DD
  String? apptTime; // HH,MM
  String? createdBy;
  String? sharedWith;
  String? status;

  Appointment({
    this.id,
    required this.title,
    required this.description,
    required this.apptDate,
    this.apptTime,
    this.createdBy,
    this.sharedWith,
    this.status
  });

  String toString() {
    return "{ id=$id, title=$title, description=$description, "
        "apptDate=$apptDate, apptTime=$apptTime }";
  }
}


/// The model backing this entity type's views.
class AppointmentsModel extends BaseModel {
  String apptTime;

  AppointmentsModel({required this.apptTime});

  void setApptTime(String inApptTime) {
    apptTime = inApptTime;
    notifyListeners();
  }

  @override
  void loadData(String inEntityType, dynamic inDatabase) async {
    print("## ${inEntityType}Model.loadData() overridden");
    print("## Appointments getAppointments");
    entityList = await AppointmentsDBWorker.db.getAll();
    print("## Appointments getAppointments: list = $entityList");
    notifyListeners();
  }
}