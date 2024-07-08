import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/form_cultos_disponibilidade.dart';

class forms_disponiblidade extends StatefulWidget {
  const forms_disponiblidade({super.key});

  @override
  State<forms_disponiblidade> createState() => _forms_disponiblidadeState();
}

class _forms_disponiblidadeState extends State<forms_disponiblidade> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addDocument() async {
    // Obtém o mês atual
    String mesAtual = DateTime.now().month.toString();
    String anoAtual = DateTime.now().year.toString();

    // Adiciona um novo documento com o campo 'Mes' e um ID gerado automaticamente
    DocumentReference docRef =
        await _firestore.collection('Forms_Disponibilidades').add({
      'Mes': mesAtual,
      'Ano': anoAtual,
    });

    print("Documento adicionado com o mês atual: $mesAtual");
    print("Documento adicionado com o mês atual: $anoAtual");

    String docId = docRef.id;

    // Adiciona um documento na coleção 'Form_Mes_Cultos' referenciando o documento 'Forms_Disponibilidades'
    // await _firestore.collection('Form_Mes_Cultos').add({
    //   'culto': 'Culto de Exemplo',
    //  'horario': '19:00',
    //   'mes_id': docId,
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Documento'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore.collection('Forms_Disponibilidades').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar os dados'));
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Form_Culto_Disponibilidade(
                              id_form: doc.id,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        // title: Text('ID: ${doc.id}'),
                        subtitle: Column(
                          children: [
                            Text('Mês:  ${doc['Mes']}, Ano ${doc['Ano']}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _addDocument,
              child: Text('CRIAR NOVO FORMULARIO'),
            ),
          ),
        ],
      ),
    );
  }
}
