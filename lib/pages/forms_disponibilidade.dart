import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/form_cultos_disponibilidade.dart';

class forms_disponiblidade extends StatefulWidget {
  const forms_disponiblidade({super.key});

  @override
  State<forms_disponiblidade> createState() => _forms_disponiblidadeState();
}

class _forms_disponiblidadeState extends State<forms_disponiblidade> {
  String mesAtual = ((DateTime.now().month) % 12 + 1).toString();
  String anoAtual = DateTime.now().year.toString();

  DateTime selectedDate = DateTime.now();

  Future<void> _selectMonthYear(BuildContext context) async {
    int selectedYear = selectedDate.year;
    int selectedMonth = selectedDate.month;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Selecione Mês e Ano'),
              content: Container(
                height: 150,
                child: Column(
                  children: <Widget>[
                    // Dropdown for year
                    Row(
                      children: <Widget>[
                        Text('Ano:'),
                        SizedBox(width: 10),
                        DropdownButton<int>(
                          value: selectedYear,
                          items: List.generate(101, (index) {
                            int year = 2000 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedYear = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // Dropdown for month
                    Row(
                      children: <Widget>[
                        Text('Mês:'),
                        SizedBox(width: 10),
                        DropdownButton<int>(
                          value: selectedMonth,
                          items: List.generate(12, (index) {
                            int month = index + 1;
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month.toString()),
                            );
                          }),
                          onChanged: (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedMonth = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('CANCELAR'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    _addDocument_personalizado(
                        selectedYear.toString(), selectedMonth.toString());
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedDate = DateTime(result['year']!, result['month']!);
      });
    }
  }

  String getMonthName(int monthNumber) {
    switch (monthNumber) {
      case 1:
        return 'Janeiro';
      case 2:
        return 'Fevereiro';
      case 3:
        return 'Março';
      case 4:
        return 'Abril';
      case 5:
        return 'Maio';
      case 6:
        return 'Junho';
      case 7:
        return 'Julho';
      case 8:
        return 'Agosto';
      case 9:
        return 'Setembro';
      case 10:
        return 'Outubro';
      case 11:
        return 'Novembro';
      case 12:
        return 'Dezembro';
      default:
        return 'Número inválido';
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addDocument() async {
    // Obtém o mês atual
    String mesAtual = ((DateTime.now().month) % 12 + 1).toString();
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

    Navigator.of(context).pop(); // Fecha o popup
  }

  Future<void> _addDocument_personalizado(String year, String month) async {
    // Obtém o mês atual

    // Adiciona um novo documento com o campo 'Mes' e um ID gerado automaticamente
    DocumentReference docRef =
        await _firestore.collection('Forms_Disponibilidades').add({
      'Mes': month,
      'Ano': year,
    });

    print("Documento adicionado com o mês atual: $month");
    print("Documento adicionado com o mês atual: $year");

    String docId = docRef.id;

    // Adiciona um documento na coleção 'Form_Mes_Cultos' referenciando o documento 'Forms_Disponibilidades'
    // await _firestore.collection('Form_Mes_Cultos').add({
    //   'culto': 'Culto de Exemplo',
    //  'horario': '19:00',
    //   'mes_id': docId,
    // });

    Navigator.of(context).pop(); // Fecha o popup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff010101),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Forms Mensais',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // Define a cor desejada para o ícone de voltar
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(45.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 18),
              child: Text(
                "Forms",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
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
                      String monthName = getMonthName(int.parse(doc['Mes']));
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
                        child: Container(
                          margin: EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                              color: Color(0xff171717),
                              borderRadius: BorderRadius.circular(25)),
                          child:
                              // title: Text('ID: ${doc.id}'),
                              Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 45.0, vertical: 13),
                            child: Text(
                              '$monthName/${doc['Ano']}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => _selectMonthYear(context),
              child: Text('Selecione Mês e Ano'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            int monthNumber = int.parse(mesAtual);
            String monthName = getMonthName(monthNumber);
            int year = int.parse(anoAtual);

            return AlertDialog(
              title: Text('Deseja adicionar formulario para o proximo mes'),
              content: Text(
                'Mês: $monthName, Ano: $year',
                style: TextStyle(color: Colors.black),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Fechar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Criar Formulario'),
                  onPressed: () {
                    _addDocument();
                  },
                ),
              ],
            );
          },
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
