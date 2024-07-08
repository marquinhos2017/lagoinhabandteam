import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Form_Culto_Disponibilidade extends StatefulWidget {
  late String id_form;

  Form_Culto_Disponibilidade({required this.id_form});

  @override
  _Form_Culto_DisponibilidadeState createState() =>
      _Form_Culto_DisponibilidadeState();
}

class _Form_Culto_DisponibilidadeState
    extends State<Form_Culto_Disponibilidade> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    String mesIdEspecifico = widget.id_form;

    return Scaffold(
      appBar: AppBar(
        title: Text('Exibir Cultos Específicos'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                      subtitle: Text(
                          'Horário: ${culto['horario']}, Data: ${culto['data']}'),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
              onPressed: () {
                _showAddCultoModal(widget.id_form);
              },
              child: Text("Add Culto")),
        ],
      ),
    );
  }

  void _showAddCultoModal(String mesId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nomeController = TextEditingController();
        final TextEditingController horarioController = TextEditingController();
        final TextEditingController dataController = TextEditingController();

        return AlertDialog(
          title: Text('Adicionar Culto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: horarioController,
                decoration: InputDecoration(labelText: 'Horário'),
              ),
              TextField(
                controller: dataController,
                decoration: InputDecoration(labelText: 'Data'),
                onTap: () async {
                  //FocusScope.of(context).requestFocus(new FocusNode());
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(DateTime.now().year, 8, 1),
                    firstDate: DateTime(DateTime.now().year, 8, 1),
                    lastDate: DateTime(DateTime.now().year, 8, 31),
                    selectableDayPredicate: (DateTime val) => val.month == 8,
                  );
                  if (picked != null) {
                    dataController.text = "${picked.toLocal()}".split(' ')[0];
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Adicionar'),
              onPressed: () {
                String nome = nomeController.text;
                String horario = horarioController.text;
                String data = dataController.text;

                _addCulto(mesId, nome, horario, data).then((_) {
                  Navigator.of(context).pop();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCulto(
      String mesId, String nome, String horario, String data) async {
    await _firestore.collection('Form_Mes_Cultos').add({
      'culto': nome,
      'horario': horario,
      'data': data,
      'mes_id': mesId,
    });
  }
}
