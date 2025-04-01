import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils.dart' as utils;
import 'appointments_dbworker.dart';
import 'appointments_model.dart';

class AppointmentsEntry extends StatefulWidget {
  @override
  _AppointmentsEntryState createState() => _AppointmentsEntryState();
}

class _AppointmentsEntryState extends State<AppointmentsEntry> {
  final TextEditingController _titleEditingController = TextEditingController();
  final TextEditingController _descriptionEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedReceiverId;
  String? _selectedReceiverName;

  @override
  Widget build(BuildContext context) {
    print("## AppointmentsEntry.build()");
    bool isNew = false;
    return Consumer<AppointmentsModel>(
      builder: (context, model, child) {
        if (model.entityBeingEdited != null) {
          _titleEditingController.text = model.entityBeingEdited.title;
          _descriptionEditingController.text = model.entityBeingEdited.description;
          if(model.entityBeingEdited.id==null){
            isNew = true;
          }
        }

        return Scaffold(
          bottomNavigationBar: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            child: Row(
              children: [
                ElevatedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    model.setStackIndex(0);
                  },
                ),
                Spacer(),
                ElevatedButton(
                  child: Text("Save"),
                  onPressed: () => _save(context, model),
                ),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.subject),
                  title: TextFormField(
                    decoration: InputDecoration(hintText: "Title"),
                    controller: _titleEditingController,
                    onChanged: (inValue) =>
                    model.entityBeingEdited.title = _titleEditingController.text,
                    validator: (inValue) {
                      if (inValue == null || inValue.isEmpty) {
                        return "Please enter a title";
                      }
                      return null;
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.description),
                  title: TextFormField(
                    keyboardType: TextInputType.multiline,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: "Description"),
                    controller: _descriptionEditingController,
                    onChanged: (inValue) =>
                    model.entityBeingEdited.description = inValue,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.today),
                  title: Text("Date"),
                  subtitle: Text(model.chosenDate ?? ""),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    color: Colors.blue,
                    onPressed: () async {
                      String chosenDate = await utils.selectDate(
                        context, model, model.entityBeingEdited.apptDate,
                      );
                      model.entityBeingEdited.apptDate = chosenDate;
                    },
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.alarm),
                  title: Text("Time"),
                  subtitle: Text(model.apptTime),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    color: Colors.blue,
                    onPressed: () => _selectTime(context, model),
                  ),
                ),
                if (isNew)
                  ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text("Share with"),
                    subtitle: Text(_selectedReceiverName ?? "Tap to choose"),
                    trailing: Icon(Icons.arrow_drop_down),
                    onTap: () async {
                      final result = await _askForReceiver(context);
                      if (result != null) {
                        setState(() {
                          _selectedReceiverId = result['id'];
                          _selectedReceiverName = result['full_name'];
                        });
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future _selectTime(BuildContext inContext, AppointmentsModel inModel) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (inModel.entityBeingEdited.apptTime != null && !inModel.entityBeingEdited.apptTime.isEmpty) {
      List timeParts = inModel.entityBeingEdited.apptTime.split(",");
      initialTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }

    TimeOfDay? picked = await showTimePicker(context: inContext, initialTime: initialTime);
    if (picked != null) {
      inModel.entityBeingEdited.apptTime = "${picked.hour},${picked.minute}";
      inModel.setApptTime(picked.format(inContext));
    }
  }

  void _save(BuildContext inContext, AppointmentsModel inModel) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    //O compromisso não será salvo se as entradas do formulário não forem validadas
    if (!_formKey.currentState!.validate()) return;

    final isNew = inModel.entityBeingEdited.id == null;
    final response;

    if (isNew) {
      response = await AppointmentsDBWorker.db.create(inModel.entityBeingEdited,
          _selectedReceiverId);
    } else {
      response = await AppointmentsDBWorker.db.update(inModel.entityBeingEdited);
    }
    if (_selectedReceiverId != null && response.isNotEmpty) {
      print("Appointment shared with ${_selectedReceiverName}");
    }

    inModel.loadData("appointments", null);
    _titleEditingController.clear();
    _descriptionEditingController.clear();
    _selectedReceiverId = null;
    _selectedReceiverName = null;

    // Retornar para a listagem de compromissos
    inModel.setStackIndex(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        content: Text("Appointment saved"),
      ),
    );
  }

  Future<Map<String, String>?> _askForReceiver(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('profiles')
        .select('id, full_name')
        .neq('id', currentUserId)
        .order('full_name');
    print("DATA: ${data.length}");

    final List<Map<String, String>> users = List<Map<String, String>>.from(
      data.map((user) => {
        'id': user['id'] as String,
        'full_name': user['full_name'] as String,
      }),
    );

    Map<String, String>? selectedUser;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Share Appointment"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['full_name'] ?? 'Unknown'),
                onTap: () {
                  selectedUser = user;
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    return selectedUser;
  }
}
