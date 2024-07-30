import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:provider/provider.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect2.dart';
import 'package:lagoinha_music/pages/login.dart';

class GerenciamentoCulto extends StatefulWidget {
  final String documentId;

  GerenciamentoCulto({required this.documentId});

  @override
  State<GerenciamentoCulto> createState() => _GerenciamentoCultoState();
}

class _GerenciamentoCultoState extends State<GerenciamentoCulto> {
  late bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _findDocumentId(
      String collectionPath, String fieldName, String value) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionPath)
          .where(fieldName, isEqualTo: value)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
    } catch (e) {
      print('Erro ao buscar documento: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMusiciansData(
      List<Map<String, dynamic>> musicians) async {
    return Future.wait(
      musicians.map((musician) async {
        final userId = musician['user_id'];
        final idCulto = widget.documentId;

        final results = await Future.wait([
          _firestore
              .collection('musicos')
              .where('user_id', isEqualTo: userId)
              .get()
              .then(
                (snapshot) => snapshot.docs.isNotEmpty
                    ? snapshot.docs.first.data() as Map<String, dynamic>
                    : {},
              ),
          _firestore
              .collection('user_culto_instrument')
              .where('idUser', isEqualTo: userId)
              .where('idCulto', isEqualTo: idCulto)
              .get()
              .then(
                (snapshot) => snapshot.docs.isNotEmpty
                    ? snapshot.docs.first.data() as Map<String, dynamic>
                    : {},
              ),
        ]);

        return {
          'name': results[0]['name'] ?? 'Nome não encontrado',
          'instrument':
              results[1]['Instrument'] ?? 'Instrumento não encontrado',
        };
      }).toList(),
    );
  }

  Future<void> _removeMusician(int userId, String idCulto) async {
    try {
      await _firestore.collection('Cultos').doc(idCulto).update({
        'musicos': FieldValue.arrayRemove([
          {'user_id': userId}
        ])
      });

      final userCultoQuery = await _firestore
          .collection('user_culto_instrument')
          .where('idUser', isEqualTo: userId)
          .where('idCulto', isEqualTo: idCulto)
          .get();

      if (userCultoQuery.docs.isNotEmpty) {
        await userCultoQuery.docs.first.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Músico e documento de instrumento removidos com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover músico: $e')),
      );
      print('Erro ao remover músico: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<List<String>> _fetchInstrumentsForCulto(
      List<Map<String, dynamic>> musicians) async {
    try {
      final instruments = <String>{};

      for (var musician in musicians) {
        final userId = musician['user_id'];
        final userInstrumentSnapshot = await _firestore
            .collection('user_culto_instrument')
            .where('idUser', isEqualTo: userId)
            .where('idCulto', isEqualTo: widget.documentId)
            .get();

        if (userInstrumentSnapshot.docs.isNotEmpty) {
          final instrument =
              userInstrumentSnapshot.docs.first.data()['Instrument'] as String;
          instruments.add(instrument);
        }
      }

      return instruments.toList();
    } catch (e) {
      print('Erro ao buscar instrumentos: $e');
      return [];
    }
  }

  Widget _buildInstrumentButtons(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('Cultos').doc(widget.documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.white)),
          );
        }

        if (!snapshot.hasData) {
          return Center(
              child:
                  Text('No data found', style: TextStyle(color: Colors.white)));
        }

        final cultoData = snapshot.data!.data() as Map<String, dynamic>;
        final musicos =
            List<Map<String, dynamic>>.from(cultoData['musicos'] ?? []);

        return FutureBuilder<List<String>>(
          future: _fetchInstrumentsForCulto(musicos),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(
                child: Text('Erro: ${futureSnapshot.error}',
                    style: TextStyle(color: Colors.white)),
              );
            }

            if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInstrumentButton(context, "Keyboard"),
                    _buildInstrumentButton(context, "Guitar"),
                    _buildInstrumentButton(context, "Drums"),
                  ],
                ),
              );
            }

            final instruments = futureSnapshot.data!;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (!instruments.contains('Keyboard'))
                    _buildInstrumentButton(context, "Keyboard"),
                  if (!instruments.contains('Guitar'))
                    _buildInstrumentButton(context, "Guitar"),
                  if (!instruments.contains('Drums'))
                    _buildInstrumentButton(context, "Drums"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstrumentButton(BuildContext context, String instrument) {
    return Container(
      margin: EdgeInsets.only(right: 24),
      width: 300,
      decoration: BoxDecoration(
        color: Color(0xff4465D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MusicianSelect2(
              document_id: widget.documentId,
              instrument: instrument,
            ),
          ),
        ).then((result) {
          if (result == true) {
            setState(() {}); // Atualiza a página se algo mudou
          }
        }),
        child: Text(
          instrument,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMusicianList() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('Cultos').doc(widget.documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
              child:
                  Text('No data found', style: TextStyle(color: Colors.white)));
        }

        final cultoData = snapshot.data!.data() as Map<String, dynamic>;
        final musicos =
            List<Map<String, dynamic>>.from(cultoData['musicos'] ?? []);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMusiciansData(musicos),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (futureSnapshot.hasError) {
              return Center(
                  child: Text('Erro: ${futureSnapshot.error}',
                      style: TextStyle(color: Colors.white)));
            }

            if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
              return Center(
                  child: Text('Dados não encontrados',
                      style: TextStyle(color: Colors.white)));
            }

            final musicoList = futureSnapshot.data!;

            return ListView.builder(
              itemCount: musicoList.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final musico = musicoList[index];
                final name = musico['name'];
                final instrument = musico['instrument'];

                return Column(
                  children: [
                    GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 20),
                                child: Text(
                                  instrument,
                                  style: TextStyle(
                                      color: Color(0xff558FFF), fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () async {
                                  if (_isProcessing || !mounted) return;
                                  setState(() {
                                    _isProcessing = true;
                                  });

                                  final musicoToRemove = musicos[index];
                                  final userId = musicoToRemove['user_id'];
                                  final idCulto = widget.documentId;

                                  setState(() {
                                    musicos.removeAt(index);
                                  });

                                  await _removeMusician(userId, idCulto);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Color(0xff558FFF), thickness: 0.2),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final cultosProvider = Provider.of<CultosProvider>(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Gerenciamento Culto",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {}); // Atualiza a página
            },
          ),
          IconButton(
            icon: Icon(Icons.login, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => login()),
            ),
          ),
        ],
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color(0xff010101),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstrumentButtons(context),
                  _buildMusicianList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}