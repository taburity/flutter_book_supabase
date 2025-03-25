import "package:flutter/material.dart";
import 'package:supabase_flutter/supabase_flutter.dart';
import "tasks/tasks.dart";
import "appointments/appointments.dart";
import "contacts/contacts.dart";
import "notes/notes.dart";

class FlutterBookHomeScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    print("## FlutterBook.build()");
    return MaterialApp(
        home : DefaultTabController(
            length : 4,
            child : Scaffold(
                appBar : AppBar(
                    title : Text("FlutterBook"),
                    bottom : TabBar(
                        tabs : [
                          Tab(icon : Icon(Icons.date_range), text : "Appointments"),
                          Tab(icon : Icon(Icons.contacts), text : "Contacts"),
                          Tab(icon : Icon(Icons.note), text : "Notes"),
                          Tab(icon : Icon(Icons.assignment_turned_in), text : "Tasks")
                        ]),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: () async {
                          await Supabase.instance.client.auth.signOut();
                          // Use setState, GetX, Provider ou outra lib para forçar rebuild e voltar à AuthScreen
                        },
                      ),
                    ],
                ),
                body : TabBarView(
                    children : [
                      Appointments(),
                      Contacts(),
                      Notes(),
                      Tasks()
                    ]))));
  }
}