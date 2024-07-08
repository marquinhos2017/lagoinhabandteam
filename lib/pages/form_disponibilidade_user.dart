import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class form_disponibilidade_user extends StatefulWidget {
  const form_disponibilidade_user({super.key});

  @override
  State<form_disponibilidade_user> createState() =>
      _form_disponibilidade_userState();
}

class _form_disponibilidade_userState extends State<form_disponibilidade_user> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    String mesIdEspecifico = "37eTtGUMH1gtlNsfh056";
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Form_Mes_Cultos')
          .where('mes_id', isEqualTo: mesIdEspecifico)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final cultos = snapshot.data!.docs;
        return ListView.builder(
          itemCount: cultos.length,
          itemBuilder: (context, index) {
            var culto = cultos[index];
            return ListTile(
              title: Text('Culto: ${culto['culto']}'),
              subtitle:
                  Text('Horário: ${culto['horario']}, Data: ${culto['data']}'),
            );
          },
        );
      },
    );
  }
}
