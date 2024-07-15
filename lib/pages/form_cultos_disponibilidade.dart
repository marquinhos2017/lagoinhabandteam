import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Form_Culto_Disponibilidade extends StatefulWidget {
  late String id_form;

  Form_Culto_Disponibilidade({required this.id_form});

  @override
  _Form_Culto_DisponibilidadeState createState() =>
      _Form_Culto_DisponibilidadeState();
}

class _Form_Culto_DisponibilidadeState
    extends State<Form_Culto_Disponibilidade> {
  String Formulario_Ativo = "";
  Map<String, dynamic> documentData = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    fetchDocumentData();
  }

  Future<void> updateAllMusicos(String formulario) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('musicos').get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        // Defina o valor do novo doc_formulario conforme necessário
        String novoDocFormulario = formulario; // Substitua por seu novo valor

        // Atualize o campo doc_formulario para cada documento
        await doc.reference.update({'doc_formulario': novoDocFormulario});
      }

      print("Todos os documentos foram atualizados com sucesso.");
    } catch (e) {
      print("Erro ao atualizar documentos: $e");
    }
  }

  Future<void> fetchDocumentData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Forms_Disponibilidades')
          .doc(widget.id_form)
          .get();

      if (doc.exists) {
        setState(() {
          documentData = doc.data() as Map<String, dynamic>;
          print(documentData['Ano']);
          print(documentData['Mes']);
        });
      } else {
        print('Documento não encontrado');
      }
    } catch (e) {
      print('Erro ao buscar documento: $e');
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    String mesIdEspecifico = widget.id_form;
    print(mesIdEspecifico);

    return Scaffold(
      appBar: AppBar(
        title: Text('Exibir Cultos Específicos'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        content: Text(
                            "Deseja enviar esse formulario para os musicos ?"),
                        actions: [
                          GestureDetector(
                              onTap: () {
                                updateAllMusicos(mesIdEspecifico);
                                Navigator.pop(context);
                              },
                              child: Text("Sim"))
                        ],
                      );
                    });
              },
              child: Icon(
                Icons.outbond_outlined,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('Form_Mes_Cultos')
                  .where('mes_id', isEqualTo: mesIdEspecifico)
                  .orderBy(
                    'data',
                  )
                  .snapshots(),
              builder: (context,
                  AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(
                      child: Text(
                          'Erro ao carregar documentos: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhum documento encontrado.'));
                }

                // Processar os documentos
                List<DocumentSnapshot<Map<String, dynamic>>> documentos =
                    snapshot.data!.docs;
                return ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    // Extrair os dados do documento
                    Map<String, dynamic>? data = documentos[index].data();
                    String nomeDocumento =
                        data?['culto'] ?? 'Nome do Culto Indisponível';
                    DateTime? dataDocumento;
                    try {
                      dataDocumento = data?['data']?.toDate();
                    } catch (e) {
                      print('Erro ao converter data: $e');
                      dataDocumento = null;
                    }

                    // Exibir cada documento em um ListTile (ou outro widget de sua escolha)
                    return ListTile(
                      title: Text(nomeDocumento),
                      subtitle: dataDocumento != null
                          ? Text(
                              DateFormat('dd/MM/yyyy').format(dataDocumento!))
                          : Text('Data Indisponível'),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
              onPressed: () async {
                DateTime primeiroDia = DateTime(int.parse(documentData['Ano']),
                    int.parse(documentData['Mes']), 1);
                DateTime ultimoDia = DateTime(
                    int.parse(documentData['Ano']),
                    int.parse(documentData['Mes']) + 1,
                    0); // Último dia do mês atual

                for (int dia = 1; dia <= ultimoDia.day; dia++) {
                  print(dia);
                  DateTime data = DateTime(int.parse(documentData['Ano']),
                      int.parse(documentData['Mes']), dia);

                  // Verificar se é quarta-feira
                  if (data.weekday == DateTime.wednesday) {
                    _firestore.collection('Form_Mes_Cultos').add({
                      'culto': "Culto Fé",
                      'horario': "20:30",
                      'data':
                          data, // Armazena a data no formato correto 'yyyy-MM-dd'
                      'mes_id': widget.id_form,
                    });
                  }

                  // Verificar se é domingo
                  if (data.weekday == DateTime.sunday) {
                    _firestore.collection('Form_Mes_Cultos').add({
                      'culto': "Culto Familia",
                      'horario': "10:30",
                      'data':
                          data, // Armazena a data no formato correto 'yyyy-MM-dd'
                      'mes_id': widget.id_form,
                    });

                    _firestore.collection('Form_Mes_Cultos').add({
                      'culto': "Culto Familia",
                      'horario': "19:30",
                      'data':
                          data, // Armazena a data no formato correto 'yyyy-MM-dd'
                      'mes_id': widget.id_form,
                    });
                  }
                }
              },
              child: Text("Gerar todos os cultos do mes")),
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

  Future<DocumentReference> _addCulto(
      String mesId, String nome, String horario, String data) async {
    DocumentReference docRef =
        await _firestore.collection('Form_Mes_Cultos').add({
      'culto': nome,
      'horario': horario,
      'data': data, // Armazena a data no formato correto 'yyyy-MM-dd'
      'mes_id': mesId,
    });
    print(data + " - " + horario + " Adicionado");

    return docRef;
  }
}
