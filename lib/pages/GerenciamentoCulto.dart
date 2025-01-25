//ESSA
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lagoinha_music/pages/MusicianPage/EditProfilePage.dart';
import 'package:lagoinha_music/pages/adminAddtoPlaylist.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect2.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart'; //For creating the SMTP Server

class GerenciamentoCulto extends StatefulWidget {
  final String documentId;

  GerenciamentoCulto({required this.documentId});

  @override
  State<GerenciamentoCulto> createState() => _GerenciamentoCultoState();
}

class _GerenciamentoCultoState extends State<GerenciamentoCulto> {
  Map<String, dynamic>? cultoDetails;

  Future<void> fetchCultoDetails() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Cultos')
          .doc(widget.documentId)
          .get();

      if (snapshot.exists) {
        setState(() {
          cultoDetails = {
            'nome': snapshot.data()?['nome'] ?? 'Sem Nome',
            'date': snapshot
                .data()?['date']
                ?.toDate(), // Converter timestamp para DateTime
            'horario': snapshot.data()?['horario'] ?? 'Sem Horário',
          };
        });
      } else {
        setState(() {
          cultoDetails = {
            'nome': 'Culto não encontrado',
            'date': null,
            'horario': 'Sem Horário',
          };
        });
      }
    } catch (e) {
      print('Erro ao buscar os detalhes do culto: $e');
      setState(() {
        cultoDetails = {
          'nome': 'Erro ao carregar',
          'date': null,
          'horario': 'Erro',
        };
      });
    }
  }

  Future<Map<String, dynamic>> getCultoDetails(String documentId) async {
    try {
      // Buscar o documento no Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('Cultos')
          .doc(documentId)
          .get();

      if (snapshot.exists) {
        // Retornar os dados relevantes
        return {
          'nome': snapshot.data()?['nome'] ?? 'Sem Nome',
          'date': snapshot
              .data()?['date']
              ?.toDate(), // Converter timestamp para DateTime
          'horario': snapshot.data()?['horario'] ?? 'Sem Horário',
        };
      } else {
        return {
          'nome': 'Culto não encontrado',
          'date': null,
          'horario': 'Sem Horário',
        };
      }
    } catch (e) {
      print('Erro ao buscar os detalhes do culto: $e');
      return {
        'nome': 'Erro ao carregar',
        'date': null,
        'horario': 'Erro',
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // _fetchMusicianNames();
    fetchCultoDetails();
  }

  String? selectedKey; // Armazena o tom selecionado
  Future<void> _showKeyDialog(String documentId) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione o tom'),
          backgroundColor: Colors.black,
          content: CircularKeySelector(
            initialKey: selectedKey,
            onSelect: (String key) {
              setState(() {
                selectedKey = key;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _saveToPlaylist(documentId); // Salva a música na playlist
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateKeyInPlaylist(
      int index, String musicDocumentId, String newKey) async {
    try {
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.documentId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      List<dynamic> playlist = cultoDoc['playlist'] ?? [];
      playlist[index]['key'] = newKey;

      await cultoRef.update({'playlist': playlist});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xff4465D9),
          content: Text('Tom atualizado com sucesso'),
        ),
      );
    } catch (e) {
      print('Erro ao atualizar o tom: $e');
    }
  }

  Future<void> _showUpdateKeyDialog(
      BuildContext context, int index, String currentKey) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atualizar tom'),
          backgroundColor: Colors.black,
          content: CircularKeySelector(
            initialKey: currentKey,
            onSelect: (String newKey) {
              setState(() {
                selectedKey = newKey;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _updateKeyInPlaylist(
                    index, widget.documentId, selectedKey!); // Atualiza o tom
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToPlaylist(String documentId) async {
    if (selectedKey != null) {
      try {
        DocumentReference cultoRef =
            _firestore.collection('Cultos').doc(widget.documentId);
        DocumentSnapshot cultoDoc = await cultoRef.get();

        if (!cultoDoc.exists) {
          throw Exception('Documento de culto não encontrado');
        }

        await cultoRef.update({
          'playlist': FieldValue.arrayUnion([
            {
              'music_document': documentId,
              'key': selectedKey,
            }
          ])
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xff4465D9),
            content: Text('Música adicionada à playlist com sucesso'),
            duration: Duration(microseconds: 2000),
          ),
        );
      } catch (e) {
        print('Erro ao adicionar música: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Nenhum tom selecionado'),
          duration: Duration(microseconds: 500),
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    Future<String> getCultoName(String documentId) async {
      try {
        // Buscar o documento no Firestore
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('Cultos')
                .doc(documentId)
                .get();

        if (snapshot.exists) {
          // Obter o nome do culto
          return snapshot.data()?['nome'] ?? 'Sem Nome';
        } else {
          return 'Culto não encontrado';
        }
      } catch (e) {
        print('Erro ao buscar o culto: $e');
        return 'Erro ao carregar';
      }
    }

    print(widget.documentId);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    // final cultosProvider = Provider.of<CultosProvider>(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        // Usar o FutureBuilder para exibir os dados no AppBar
        title: cultoDetails == null
            ? Text('Carregando...')
            : Builder(builder: (context) {
                final cultoNome = cultoDetails?['nome'] ?? '';
                final cultoDate = cultoDetails?['date'] as DateTime?;
                final cultoHorario = cultoDetails?['horario'] ?? '';

                final dateFormatted = cultoDate != null
                    ? '${cultoDate.day}/${cultoDate.month}'
                    : 'Sem Data';

                return Column(
                  children: [
                    Text(
                      '$cultoNome',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    /*
                    MusicianCard(
                        imageUrl:
                            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXJr-fGkiy1DE5A0JNOkcmCNGcXuQXdzENZA&s",
                        musicianName: "Jose",
                        cultosEscalados: 4),*/ //Avatar com numeros cultos escalados
                    Container(
                      decoration: BoxDecoration(color: Colors.black),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '$dateFormatted $cultoHorario',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }),

        //  foregroundColor: Colors.black,
        //   surfaceTintColor: Colors.black,
        // shadowColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {}); // Atualiza a página
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => login()),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        shadowColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            child: Text(
                              "Band",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Band(documentId: widget.documentId)
                      ],
                    ),

                    PopupMenuDivider(), // Linha divisória
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Playlist",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddtoPlaylist(
                                            document_id: widget.documentId,
                                          ),
                                        ),
                                      ).then((value) {
                                        // Após retornar da tela de adicionar música, você pode atualizar a página
                                        setState(() {});
                                        // Ou atualizar de acordo com a necessidade do seu fluxo
                                      });
                                      ;
                                      //Navigator.pushNamed(
                                      //    context, '/adminCultoForm');

                                      //Navigator.pushNamed(
                                      //    context, '/adminCultoForm');
                                    },
                                    child: Center(
                                      child: Container(
                                        // width: MediaQuery.of(context).size.width,
                                        width: 46,
                                        // margin:
                                        //       EdgeInsets.only(top: 24, bottom: 16),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.black,
                                        ),
                                        child: Center(
                                            child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 24,
                                        )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    PopupMenuDivider(), // Linh

                    PlayList(documentId: widget.documentId),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Arquivos",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 24),
                            Container(
                              height: 100,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('arquivos')
                                    .where('culto_especifico',
                                        isEqualTo: widget.documentId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Erro ao carregar arquivos.'));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  final arquivos = snapshot.data!.docs;

                                  if (arquivos.isEmpty) {
                                    return Center(
                                        child:
                                            Text('Nenhum arquivo encontrado.'));
                                  }

                                  return ListView.builder(
                                    itemCount: arquivos.length,
                                    itemBuilder: (context, index) {
                                      var arquivoData = arquivos[index].data()
                                          as Map<String, dynamic>;
                                      var arquivoUrl =
                                          arquivoData['arquivo_url'] ?? '';
                                      var name =
                                          arquivoData['nome_arquivo'] ?? '';

                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              if (arquivoUrl.isNotEmpty) {
                                                // Baixar o arquivo quando o ícone é clicado
                                                await _downloadFile(
                                                    arquivoUrl, name);
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Icon(Icons.file_present),
                                                SizedBox(width: 12),
                                                Text(name,
                                                    style: TextStyle(
                                                        color: Colors.black)),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.download,
                                                    color: Colors.black),
                                                onPressed: () async {
                                                  // Confirmar exclusão
                                                  bool confirmar =
                                                      await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Excluir Arquivo'),
                                                        content: Text(
                                                            'Tem certeza de que deseja excluir o arquivo "$name"?'),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                                'Cancelar'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child:
                                                                Text('Excluir'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirmar) {
                                                    try {
                                                      // Excluir o arquivo do Firebase Storage
                                                      if (arquivoUrl
                                                          .isNotEmpty) {
                                                        Reference
                                                            storageReference =
                                                            FirebaseStorage
                                                                .instance
                                                                .refFromURL(
                                                                    arquivoUrl);
                                                        await storageReference
                                                            .delete();
                                                      }

                                                      // Excluir o documento do Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'arquivos')
                                                          .doc(arquivos[index]
                                                              .id)
                                                          .delete();

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Arquivo excluído com sucesso!'),
                                                      ));
                                                    } catch (e) {
                                                      // Tratar possíveis erros
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Erro ao excluir o arquivo: $e'),
                                                      ));
                                                    }
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () async {
                                                  // Confirmar exclusão
                                                  bool confirmar =
                                                      await showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Excluir Arquivo'),
                                                        content: Text(
                                                            'Tem certeza de que deseja excluir o arquivo "$name"?'),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                                'Cancelar'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false);
                                                            },
                                                          ),
                                                          TextButton(
                                                            child:
                                                                Text('Excluir'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirmar) {
                                                    try {
                                                      // Excluir o arquivo do Firebase Storage
                                                      if (arquivoUrl
                                                          .isNotEmpty) {
                                                        Reference
                                                            storageReference =
                                                            FirebaseStorage
                                                                .instance
                                                                .refFromURL(
                                                                    arquivoUrl);
                                                        await storageReference
                                                            .delete();
                                                      }

                                                      // Excluir o documento do Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'arquivos')
                                                          .doc(arquivos[index]
                                                              .id)
                                                          .delete();

                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Arquivo excluído com sucesso!'),
                                                      ));
                                                    } catch (e) {
                                                      // Tratar possíveis erros
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(
                                                            'Erro ao excluir o arquivo: $e'),
                                                      ));
                                                    }
                                                  }
                                                },
                                              )
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UploadPage(culto: widget.documentId),
                                  ),
                                ).then((value) {
                                  setState(() {});
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.only(),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.black,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Center(
                                    child: Text(
                                      "+",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      child: Text(
                        "Arquivos",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Container(
                      height: 300,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('arquivos')
                            .where('culto_especifico',
                                isEqualTo: widget.documentId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Erro ao carregar arquivos.'));
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          final arquivos = snapshot.data!.docs;

                          if (arquivos.isEmpty) {
                            return Center(
                                child: Text('Nenhum arquivo encontrado.'));
                          }

                          return ListView.builder(
                            itemCount: arquivos.length,
                            itemBuilder: (context, index) {
                              var arquivoData = arquivos[index].data()
                                  as Map<String, dynamic>;
                              var arquivoUrl = arquivoData['arquivo_url'] ?? '';
                              var cultoEspecifico =
                                  arquivoData['culto_especifico'] ?? '';

                              return ListTile(
                                title: Text(
                                  'Arquivo ${index + 1}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(cultoEspecifico),
                                onTap: () {
                                  //     _baixarArquivo(context, arquivoUrl,
                                  //       'arquivo_${index + 1}.ext'); // Substitua ".ext" pela extensão apropriada
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Solicita permissão para acessar o armazenamento (necessário no Android)
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Permissão para acessar o armazenamento negada');
        }
      }

      // Obtém o diretório correto para salvar o arquivo
      final directory = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception('Falha ao obter o diretório de armazenamento');
      }

      // Caminho completo para salvar o arquivo
      final filePath = '${directory.path}/$fileName';

      // Faz o download do arquivo
      Dio dio = Dio();
      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print((received / total * 100).toStringAsFixed(0) + "%");
        }
      });

      print('Arquivo salvo em: $filePath');
    } catch (e) {
      print('Erro ao baixar o arquivo: $e');
    }
  }
}

class CircularKeySelector extends StatefulWidget {
  final Function(String) onSelect;
  final String? initialKey;

  const CircularKeySelector({required this.onSelect, this.initialKey, Key? key})
      : super(key: key);

  @override
  _CircularKeySelectorState createState() => _CircularKeySelectorState();
}

class _CircularKeySelectorState extends State<CircularKeySelector> {
  final List<String> keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  String? selectedKey;
  double currentAngle = 0.0;
  Offset? currentOffset;

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialKey;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          currentOffset = details.localPosition;
          _updateSelectedKey();
        });
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: CirclePainter(keys, selectedKey, currentAngle),
            ),
            Center(
              child: Text(
                selectedKey ?? 'Selecione o tom',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSelectedKey() {
    if (currentOffset != null) {
      final center = Offset(100, 100);
      final dx = currentOffset!.dx - center.dx;
      final dy = currentOffset!.dy - center.dy;
      final angle =
          atan2(dy, dx) + pi / 2; // Ajusta o ângulo para começar no topo
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < 80) {
        // Garante que o movimento está dentro do círculo
        final index = ((angle / (2 * pi) * keys.length).floor() % keys.length);
        setState(() {
          selectedKey = keys[index];
          currentAngle = -angle; // Rotaciona o círculo para a posição do dedo
        });
        widget
            .onSelect(selectedKey!); // Atualiza o tom selecionado no widget pai
      }
    }
  }
}

class CirclePainter extends CustomPainter {
  final List<String> keys;
  final String? selectedKey;
  final double rotationAngle;

  CirclePainter(this.keys, this.selectedKey, this.rotationAngle);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint selectedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final double radius = size.width / 2;
    final double circleRadius = radius - 20;
    final double centerX = radius;
    final double centerY = radius;

    canvas.translate(centerX, centerY);
    canvas.rotate(rotationAngle);

    for (int i = 0; i < keys.length; i++) {
      final angle = 2 * pi * i / keys.length;
      final offset = Offset(
        cos(angle) * circleRadius,
        sin(angle) * circleRadius,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: keys[i],
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    if (selectedKey != null) {
      final selectedIndex = keys.indexOf(selectedKey!);
      final selectedAngle = 2 * pi * selectedIndex / keys.length;
      final selectedOffset = Offset(
        cos(selectedAngle) * circleRadius,
        sin(selectedAngle) * circleRadius,
      );

      canvas.drawCircle(selectedOffset, 10, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class UploadPage extends StatefulWidget {
  final String culto;

  UploadPage({required this.culto});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _file;
  bool _uploading = false;
  double _progress = 0;
  String? _downloadURL;
  String? _cultoEspecifico;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cultoEspecifico = widget.culto;
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _uploadFile();
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null || _cultoEspecifico == null || _cultoEspecifico!.isEmpty)
      return;

    setState(() {
      _uploading = true;
    });

    String fileName = _file!.path.split('/').last;
    Reference storageRef =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    UploadTask uploadTask = storageRef.putFile(_file!);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });
    });

    try {
      await uploadTask;

      String downloadURL = await storageRef.getDownloadURL();
      setState(() {
        _downloadURL = downloadURL;
      });

      await _firestore.collection('arquivos').add({
        'arquivo_url': downloadURL,
        'culto_especifico': _cultoEspecifico,
        'nome_arquivo': fileName,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('File uploaded and saved to Firestore: $downloadURL')),
      );
    } catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file')),
      );
    } finally {
      setState(() {
        _uploading = false;
        _progress = 0;
        _file = null;
        _cultoEspecifico = null;
      });
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _uploading
                    ? Column(
                        children: [
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(
                              strokeWidth: 6,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text('${_progress.toStringAsFixed(2)}% uploaded'),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); // Close the dialog
                          _pickFile(); // Open file picker
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: Icon(
                            Icons.upload_file,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload and Save to Firestore'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _uploading
                ? Column(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text('${_progress.toStringAsFixed(2)}% uploaded'),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      //  Navigator.of(context).pop(); // Close the dialog
                      _pickFile(); // Open file picker
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      child: Icon(
                        Icons.upload_file,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class CultoEspecificoPage extends StatelessWidget {
  final String cultoEspecifico;

  CultoEspecificoPage({required this.cultoEspecifico});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arquivos do Culto Específico'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('arquivos')
            .where('culto_especifico', isEqualTo: cultoEspecifico)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar arquivos.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final arquivos = snapshot.data!.docs;

          if (arquivos.isEmpty) {
            return Center(child: Text('Nenhum arquivo encontrado.'));
          }

          return ListView.builder(
            itemCount: arquivos.length,
            itemBuilder: (context, index) {
              var arquivoData = arquivos[index].data() as Map<String, dynamic>;
              var arquivoUrl = arquivoData['arquivo_url'] ?? '';
              var cultoEspecifico = arquivoData['culto_especifico'] ?? '';

              return ListTile(
                title: Text('Arquivo ${index + 1}'),
                subtitle: Text(cultoEspecifico),
                onTap: () {
                  _baixarArquivo(context, arquivoUrl,
                      'arquivo_${index + 1}.ext'); // Substitua ".ext" pela extensão apropriada
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _baixarArquivo(
      BuildContext context, String url, String fileName) async {
    try {
      // Obter o diretório para salvar o arquivo
      Directory dir =
          await getApplicationDocumentsDirectory(); // Usado para iOS e Android

      // Configurar o caminho do arquivo
      String filePath = path.join(dir.path, fileName);

      // Fazer o download do arquivo
      Dio dio = Dio();
      await dio.download(url, filePath);

      // Mostrar uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Download concluído: $filePath'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao baixar arquivo: $e'),
      ));
    }
  }
}

class PlayList extends StatefulWidget {
  final String documentId;
  const PlayList({super.key, required this.documentId});

  @override
  State<PlayList> createState() => _PlayListState();
}

class _PlayListState extends State<PlayList> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _fetchPlaylistDetails(
      List<Map<String, dynamic>> playlist) async {
    final firestore = FirebaseFirestore.instance;
    final futures = playlist.map((item) async {
      final musicDocumentId = item['music_document'] as String;
      final key = item['key'] ?? 'key Desconhecido';
      final link = item['link'] ?? '';

      try {
        final musicDoc = await firestore
            .collection('music_database')
            .doc(musicDocumentId)
            .get();

        if (musicDoc.exists) {
          final musicData = musicDoc.data() as Map<String, dynamic>;
          return {
            'musica': musicData['Music'] ?? 'Música Desconhecida',
            'author': musicData['Author'] ?? 'Autor Desconhecido',
            'key': key,
            'link': link,
            'musicDocumentId': musicDocumentId,
          };
        }
      } catch (e) {
        print('Erro ao carregar música: $e');
      }

      return {
        'musica': 'Música não encontrada',
        'author': '',
        'key': key,
        'link': link,
        'musicDocumentId': musicDocumentId,
      };
    }).toList();

    return await Future.wait(futures);
  }

  Future<void> _updatePlaylistLink(int index, String newLink) async {
    try {
      DocumentReference documentRef = FirebaseFirestore.instance
          .collection('Cultos')
          .doc(widget.documentId);

      // Obtenha o documento
      DocumentSnapshot doc = await documentRef.get();

      if (doc.exists) {
        // Obtenha o array de playlists
        List<dynamic> playlist = doc['playlist'] ?? [];

        // Verifique se o índice está dentro dos limites
        if (index >= 0 && index < playlist.length) {
          // Atualize o campo 'link' do item específico no array
          playlist[index]['link'] = newLink;

          // Atualize o documento com o novo array
          await documentRef.update({
            'playlist': playlist,
          });

          setState(() {
            // Atualize o estado local se necessário
          });

          print('Link atualizado com sucesso.');
        } else {
          print('Índice fora dos limites.');
        }
      } else {
        print('Documento não encontrado.');
      }
    } catch (e) {
      print('Erro ao atualizar o link: $e');
    }
  }

  // Função para remover um item da playlist
  Future<void> _removeItemFromPlaylist(BuildContext context, int index,
      String documentId, String musicDocumentId) async {
    try {
      // Obtém o documento atual da coleção 'Cultos'
      DocumentSnapshot cultoSnapshot = await FirebaseFirestore.instance
          .collection('Cultos')
          .doc(documentId)
          .get();

      if (cultoSnapshot.exists) {
        // Obtém os dados do documento
        Map<String, dynamic> cultoData =
            cultoSnapshot.data() as Map<String, dynamic>;
        List<dynamic> playlist = cultoData['playlist'] ?? [];

        // Remove o item da lista com base no índice
        playlist.removeAt(index);

        // Atualiza o documento com a nova lista de playlist
        await FirebaseFirestore.instance
            .collection('Cultos')
            .doc(documentId)
            .update({'playlist': playlist});

        // Atualiza a UI se necessário
        setState(() {});
      }
    } catch (e) {
      // Lida com erros
      print('Erro ao remover item da playlist: $e');
    }
  }

  void _showUpdateLinkDialog(BuildContext context, int index, String link) {
    final TextEditingController _linkController = TextEditingController();
    _linkController.text = link; // Carrega o link atual no TextField

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Link Youtube'),
          content: TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Link',
              hintText: 'Cole aqui o link do youtube',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String newLink = _linkController.text;
                if (newLink.isNotEmpty) {
                  await _updatePlaylistLink(index, newLink);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Atualizar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Cultos')
                .doc(widget.documentId)
                .get(),
            builder: (context, cultoSnapshot) {
              if (cultoSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (cultoSnapshot.hasError) {
                return Center(
                    child: Text('Erro ao carregar os dados do culto'));
              }

              if (!cultoSnapshot.hasData || !cultoSnapshot.data!.exists) {
                return Center(
                    child: Text('Nenhum documento de culto encontrado'));
              }

              final cultoData =
                  cultoSnapshot.data!.data() as Map<String, dynamic>;
              final List<dynamic> playlist = cultoData['playlist'] ?? [];

              return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true, // Ajusta o tamanho da ListView ao conteúdo
                physics:
                    NeverScrollableScrollPhysics(), // Desativa o scroll interno
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  final musicDocumentId =
                      playlist[index]['music_document'] as String;
                  final key = playlist[index]['key'] ?? 'key Desconhecido';
                  final link = playlist[index]['link'] ?? '';

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('music_database')
                        .doc(musicDocumentId)
                        .get(),
                    builder: (context, musicSnapshot) {
                      if (!mounted) {
                        return SizedBox.shrink();
                      }
                      if (musicSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                              color: const Color.fromARGB(255, 0, 46, 83)),
                        );
                      }

                      if (musicSnapshot.hasError) {
                        return Text(
                          'Erro ao carregar música',
                          style: TextStyle(color: Colors.red),
                        );
                      }

                      if (!musicSnapshot.hasData ||
                          !musicSnapshot.data!.exists) {
                        return Text(
                          'Música não encontrada',
                          style: TextStyle(color: Colors.black),
                        );
                      }

                      final musicData =
                          musicSnapshot.data!.data() as Map<String, dynamic>;
                      final musica =
                          musicData['Music'] ?? 'Música Desconhecida';
                      final author =
                          musicData['Author'] ?? 'Autor Desconhecido';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          tileColor: Color(0xfff9fafc), // Fundo branco
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                key,
                                style: TextStyle(
                                  color: Colors
                                      .white, // Texto branco no fundo azul
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            musica,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Título preto
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Autor: $author',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Colors.black87, // Subtítulo cinza escuro
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            color: Colors.white,
                            icon: Icon(Icons.more_vert, color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  12), // Borda arredondada
                            ),
                            onSelected: (String value) async {
                              if (value == 'update') {
                                _showUpdateLinkDialog(context, index, link);
                              } else if (value == 'delete') {
                                await _removeItemFromPlaylist(
                                  context,
                                  index,
                                  widget.documentId,
                                  musicDocumentId,
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                height: 0.0,
                                value: 'update',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alterar Link do Vídeo',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 4.0),
                                      child: Text(
                                        'Clique aqui para atualizar o link do vídeo associado.',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(), // Linha divisória
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Deletar Canção',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 4.0),
                                      child: Text(
                                        'Remova esta música da lista de forma permanente.',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        )
      ]),
    );
  }
}

class Band extends StatefulWidget {
  final String documentId;
  const Band({super.key, required this.documentId});

  @override
  State<Band> createState() => _BandState();
}

class _BandState extends State<Band> {
  void _showSnackBar(String message) {
    // Usa a referência salva
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  late ScaffoldMessengerState _scaffoldMessenger;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Salva a referência ao ScaffoldMessenger
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Agora, você pode usar a referência salva no dispose() sem problemas
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //_fetchMusicianNames();
    //fetchCultoDetails();
  }

  Future<void> _fetchMusicianNames() async {
    final _firestore = FirebaseFirestore.instance;
    try {
      // Passo 1: Obter todos os documentos de user_culto_instrument
      final userCultoSnapshot =
          await _firestore.collection('user_culto_instrument').get();

      if (userCultoSnapshot.docs.isEmpty) {
        setState(() {
          _musicianNames = [];
          _isLoading = false;
        });
        return;
      }

      // Passo 2: Criar uma lista de user_id a partir dos documentos
      final userIds =
          userCultoSnapshot.docs.map((doc) => doc['user_id'] as int).toSet();
      print(userIds);

      if (userIds.isEmpty) {
        setState(() {
          _musicianNames = [];
          _isLoading = false;
        });
        return;
      }

      // Passo 3: Buscar os nomes dos músicos usando os user_id
      final musicianSnapshots = await Future.wait(userIds.map((userId) =>
          _firestore
              .collection('musicos')
              .where('user_id', isEqualTo: userId)
              .get()));

      // Extrair nomes dos músicos
      final musicianNames = <String>{};
      for (final snapshot in musicianSnapshots) {
        for (final doc in snapshot.docs) {
          final name = doc['name'] as String?;
          if (name != null) {
            musicianNames.add(name);
          }
        }
      }

      // Atualizar o estado com os nomes dos músicos
      setState(() {
        _musicianNames = musicianNames.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao buscar dados: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMusiciansData() async {
    final _firestore = FirebaseFirestore.instance;
    try {
      // Passo 1: Buscar todos os documentos da coleção 'user_culto_instrument'
      final idCulto = widget.documentId;
      final userCultoSnapshot = await _firestore
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: idCulto)
          .get();

      // Lista para armazenar os futuros resultados
      final List<Future<Map<String, dynamic>>> futureList =
          userCultoSnapshot.docs.map((userCultoDoc) async {
        final userId = userCultoDoc['idUser'];

        // Passo 2: Buscar o nome do usuário na coleção 'musicos'
        final musicianSnapshot = await _firestore
            .collection('musicos')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        final name = musicianSnapshot.docs.isNotEmpty
            ? musicianSnapshot.docs.first.data()['name'] ??
                'Nome não encontrado'
            : 'Nome não encontrado';

        // Passo 3: Obter o instrumento do documento 'user_culto_instrument'
        final instrument =
            userCultoDoc.data()['Instrument'] ?? 'Instrumento não encontrado';

        return {
          'name': name,
          'instrument': instrument,
          'referenciacultoinstrumentouser': userCultoDoc.id,
        };
      }).toList();

      // Passo 4: Aguardar todos os futuros e retornar os resultados
      return Future.wait(futureList);
    } catch (e) {
      // Em caso de erro, retornar uma lista vazia ou lançar a exceção
      print('Erro ao buscar dados: $e');
      return [];
    }
  }

  Future<void> _removeMusician2(int userId, String idCulto, String id,
      int index, String instrument) async {
    final _firestore = FirebaseFirestore.instance;
    print("Removendo: $userId");
    print("Removendo Culto: $idCulto");
    print("Removendo Documento: $id");

    try {
      // Remove o documento da coleção 'user_culto_instrument' usando o id
      final documentRef =
          _firestore.collection('user_culto_instrument').doc(id);
      await documentRef.delete();

      // Atualiza o array 'musicos' no documento do culto
      final cultoRef = _firestore.collection('Cultos').doc(idCulto);
      final cultoDoc = await cultoRef.get();

      if (cultoDoc.exists) {
        final musicosList = cultoDoc.data()?['musicos'] as List<dynamic>? ?? [];

        if (index < 0 || index >= musicosList.length) {
          throw Exception('Índice fora do intervalo');
        }

        // Remove o músico específico pelo índice
        final updatedMusicosList = List.from(musicosList)..removeAt(index);

        // Atualiza o documento do culto com a lista de músicos modificada
        await cultoRef.update({
          'musicos': updatedMusicosList,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Músico removido com sucesso')));

        // Configura o servidor SMTP
        final smtpServer =
            gmail("marcosrodriguescorreiajc@gmail.com", "dpec dpql isvc wkau");

        final message = Message()
          ..from = Address("marcosrodriguescorreiajc@gmail.com")
          ..recipients.add('marcos.rodrigues2015@yahoo.com.br')
          ..subject = 'Você acabou de ser removido da escala'
          ..html = '''[HTML Content]'''
          ..text = 'Olá, tudo bem ? Você acabou de ser removido do culto.';

        try {
          // Envia o email
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
        } on MailerException catch (e) {
          print('Message not sent. \n' + e.toString());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Documento do culto não encontrado')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao remover músico: $e')));
      print('Erro ao remover músico: $e');
    } finally {
      if (mounted) {
        setState(() {
          // Atualiza o estado do widget, caso necessário
        });
      }
    }
  }

  Future<void> _removeMusician(int userId, String idCulto, String id, int index,
      String instrument) async {
    final _firestore = FirebaseFirestore.instance;
    print("Removendo: $userId");
    print("Removendo Culto: $idCulto");
    print("Removendo Documento: $id");

    try {
      // Remove o documento da coleção 'user_culto_instrument' usando o id
      final documentRef =
          _firestore.collection('user_culto_instrument').doc(id);
      await documentRef.delete();

      // Atualiza o array 'musicos' no documento do culto
      final cultoRef = _firestore.collection('Cultos').doc(idCulto);
      final cultoDoc = await cultoRef.get();

      if (cultoDoc.exists) {
        final musicosList = cultoDoc.data()?['musicos'] as List<dynamic>? ?? [];

        if (index < 0 || index >= musicosList.length) {
          throw Exception('Índice fora do intervalo');
        }

        // Remove o músico específico pelo índice
        final updatedMusicosList = List.from(musicosList)..removeAt(index);

        // Atualiza o documento do culto com a lista de músicos modificada
        await cultoRef.update({
          'musicos': updatedMusicosList,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Músico removido com sucesso'),
          ),
        );

        final smtpServer =
            gmail("marcosrodriguescorreiajc@gmail.com", "dpec dpql isvc wkau");
        // Creating the Gmail server

        // Create our email message.
        final message = Message()
          ..from = Address("marcosrodriguescorreiajc@gmail.com")
          ..recipients.add('marcos.rodrigues2015@yahoo.com.br') //recipent email
          //   ..ccRecipients.addAll([
          //      'destCc1@example.com',
          //      'destCc2@example.com'
          //    ]) //cc Recipents emails
          //   ..bccRecipients.add(
          //       Address('marcos.rodrigues2015@yahoo.com.br')) //bcc Recipents emails
          ..subject =
              'Você acabou de ser removido da escala' //subject of the email

          ..html =
              '<!doctype html> <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"> <head> <title></title> <!--[if !mso]><!--> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <!--<![endif]--> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1"> <style type="text/css"> #outlook a { padding:0; } body { margin:0;padding:0;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%; } table, td { border-collapse:collapse;mso-table-lspace:0pt;mso-table-rspace:0pt; } img { border:0;height:auto;line-height:100%; outline:none;text-decoration:none;-ms-interpolation-mode:bicubic; } p { display:block;margin:13px 0; } </style> <!--[if mso]> <noscript> <xml> <o:OfficeDocumentSettings> <o:AllowPNG/> <o:PixelsPerInch>96</o:PixelsPerInch> </o:OfficeDocumentSettings> </xml> </noscript> <![endif]--> <!--[if lte mso 11]> <style type="text/css"> .mj-outlook-group-fix { width:100% !important; } </style> <![endif]--> <!--[if !mso]><!--> <link href="https://fonts.googleapis.com/css?family=Ubuntu:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Cabin:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Bitter:400,700" rel="stylesheet" type="text/css"> <style type="text/css"> @import url(https://fonts.googleapis.com/css?family=Ubuntu:400,700); @import url(https://fonts.googleapis.com/css?family=Cabin:400,700); @import url(https://fonts.googleapis.com/css?family=Bitter:400,700); </style> <!--<![endif]--> <style type="text/css"> @media only screen and (min-width:480px) { .mj-column-per-100 { width:100% !important; max-width: 100%; } } </style> <style media="screen and (min-width:480px)"> .moz-text-html .mj-column-per-100 { width:100% !important; max-width: 100%; } </style> <style type="text/css"> </style> <style type="text/css"> .hide_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_on_mobile { display: block !important;} } .hide_section_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_section_on_mobile { display: table !important; } div.hide_section_on_mobile { display: block !important; } } .hide_on_desktop { display: block !important;} @media only screen and (min-width: 480px) { .hide_on_desktop { display: none !important;} } .hide_section_on_desktop { display: table !important; width: 100%; } @media only screen and (min-width: 480px) { .hide_section_on_desktop { display: none !important;} } p, h1, h2, h3 { margin: 0px; } ul, li, ol { font-size: 11px; font-family: Ubuntu, Helvetica, Arial; } a { text-decoration: none; color: inherit; } @media only screen and (max-width:480px) { .mj-column-per-100 { width:100%!important; max-width:100%!important; }.mj-column-per-100 > .mj-column-per-100 { width:100%!important; max-width:100%!important; } } </style> </head> <body style="word-spacing:normal;background-color:#FFFFFF;"> <div style="background-color:#FFFFFF;"> <!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="" role="presentation" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--> <div style="margin:0px auto;max-width:600px;"> <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"> <tbody> <tr> <td style="direction:ltr;font-size:0px;padding:9px 0px 9px 0px;text-align:center;"> <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--> <div class="mj-column-per-100 mj-outlook-group-fix" style="font-size:0px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"> <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"> <tbody> <tr> <td align="left" style="font-size:0px;padding:15px 15px 15px 15px;word-break:break-word;"> <div style="font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:13px;line-height:1.5;text-align:left;color:#000000;"><p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;&nbsp;<br>&nbsp;<br>&nbsp;<br><span style="font-size: 21px;">Voc&ecirc; acabou de ser escalado</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br><span style="font-size: 12px;"><strong>Voc&ecirc; foi removido do Culto que ocorreria no dia  para a fun&ccedil;&atilde;o $instrument.</strong></span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><span style="font-family: Bitter, Georgia, serif;">Para que voc&ecirc; possa visualizar suas escalas, baixe o aplicativo de acordo com seu smartphone.</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><em>&copy; 2024&nbsp; Lake Music Todos os Direitos Reservados</em></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;</p></div> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </div> <div style="color: #ccc; font-size: 12px; width: 600px; margin: 15px auto; text-align: center;"><a href="https://wordtohtml.net/email/designer">Created with WordToHTML.net Email Designer</a></div> </body> </html>'
          ..text =
              'Olá, tudo bem ? Você acabou de ser escalado para o Culto dia: , Horàrio: no instrumento: .\n  This is line 2 of the text part.<!doctype html> <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"> <head> <title></title> <!--[if !mso]><!--> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <!--<![endif]--> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1"> <style type="text/css"> #outlook a { padding:0; } body { margin:0;padding:0;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%; } table, td { border-collapse:collapse;mso-table-lspace:0pt;mso-table-rspace:0pt; } img { border:0;height:auto;line-height:100%; outline:none;text-decoration:none;-ms-interpolation-mode:bicubic; } p { display:block;margin:13px 0; } </style> <!--[if mso]> <noscript> <xml> <o:OfficeDocumentSettings> <o:AllowPNG/> <o:PixelsPerInch>96</o:PixelsPerInch> </o:OfficeDocumentSettings> </xml> </noscript> <![endif]--> <!--[if lte mso 11]> <style type="text/css"> .mj-outlook-group-fix { width:100% !important; } </style> <![endif]--> <!--[if !mso]><!--> <link href="https://fonts.googleapis.com/css?family=Ubuntu:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Cabin:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Bitter:400,700" rel="stylesheet" type="text/css"> <style type="text/css"> @import url(https://fonts.googleapis.com/css?family=Ubuntu:400,700); @import url(https://fonts.googleapis.com/css?family=Cabin:400,700); @import url(https://fonts.googleapis.com/css?family=Bitter:400,700); </style> <!--<![endif]--> <style type="text/css"> @media only screen and (min-width:480px) { .mj-column-per-100 { width:100% !important; max-width: 100%; } } </style> <style media="screen and (min-width:480px)"> .moz-text-html .mj-column-per-100 { width:100% !important; max-width: 100%; } </style> <style type="text/css"> </style> <style type="text/css"> .hide_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_on_mobile { display: block !important;} } .hide_section_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_section_on_mobile { display: table !important; } div.hide_section_on_mobile { display: block !important; } } .hide_on_desktop { display: block !important;} @media only screen and (min-width: 480px) { .hide_on_desktop { display: none !important;} } .hide_section_on_desktop { display: table !important; width: 100%; } @media only screen and (min-width: 480px) { .hide_section_on_desktop { display: none !important;} } p, h1, h2, h3 { margin: 0px; } ul, li, ol { font-size: 11px; font-family: Ubuntu, Helvetica, Arial; } a { text-decoration: none; color: inherit; } @media only screen and (max-width:480px) { .mj-column-per-100 { width:100%!important; max-width:100%!important; }.mj-column-per-100 > .mj-column-per-100 { width:100%!important; max-width:100%!important; } } </style> </head> <body style="word-spacing:normal;background-color:#FFFFFF;"> <div style="background-color:#FFFFFF;"> <!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="" role="presentation" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--> <div style="margin:0px auto;max-width:600px;"> <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"> <tbody> <tr> <td style="direction:ltr;font-size:0px;padding:9px 0px 9px 0px;text-align:center;"> <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--> <div class="mj-column-per-100 mj-outlook-group-fix" style="font-size:0px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"> <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"> <tbody> <tr> <td align="left" style="font-size:0px;padding:15px 15px 15px 15px;word-break:break-word;"> <div style="font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:13px;line-height:1.5;text-align:left;color:#000000;"><p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;&nbsp;<br>&nbsp;<br>&nbsp;<br><span style="font-size: 21px;">Voc&ecirc; acabou de ser escalado</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br><span style="font-size: 12px;"><strong>Voc&ecirc; foi escalado(a) para o evento Culto Celebra&ccedil;&atilde;o que ocorrer&aacute; no dia 5 de Janeiro de 2025 19h30 para a fun&ccedil;&atilde;o Tecladista.</strong></span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><span style="font-family: Bitter, Georgia, serif;">Para que voc&ecirc; possa visualizar suas escalas, baixe o aplicativo de acordo com seu smartphone.</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><em>&copy; 2024&nbsp; Lake Music Todos os Direitos Reservados</em></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;</p></div> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </div> <div style="color: #ccc; font-size: 12px; width: 600px; margin: 15px auto; text-align: center;"><a href="https://wordtohtml.net/email/designer">Created with WordToHTML.net Email Designer</a></div> </body> </html>'; //body of the email

        try {
          /*Aqui envia o email, retirei pois estava enchendo meu email
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' +
              sendReport.toString()); //print if the email is sent

              */

          print("Removido");
        } on MailerException catch (e) {
          print('Message not sent. \n' +
              e.toString()); //print if the email is not sent
          // e.toString() will show why the email is not sending
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(microseconds: 2000),
            content: Text('Documento do culto não encontrado'),
          ),
        );
      }
    } catch (e) {
      // Feedback para o usuário sobre erro na remoção
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover músico: $e'),
        ),
      );
      print('Erro ao remover músico: $e');
    } finally {
      // Atualiza o estado do widget, se ainda estiver montado
      if (mounted) {
        setState(() {
          //  _isProcessing = false;
        });
      }
    }
  }

  Future<List<String>> _fetchInstrumentsForCulto(
      List<Map<String, dynamic>> musicians) async {
    final _firestore = FirebaseFirestore.instance;
    try {
      final instruments = <String>{};

      for (var musician in musicians) {
        final userId = musician['user_id'];
        final userInstrumentSnapshot = await _firestore
            .collection('user_culto_instrument')
            .where('idUser', isEqualTo: userId)
            .where('idCulto', isEqualTo: widget.documentId)
            .get();

        for (var doc in userInstrumentSnapshot.docs) {
          final instrument = doc.data()['Instrument'] as String;
          instruments.add(instrument);
        }
      }

      return instruments.toList();
    } catch (e) {
      print('Erro ao buscar instrumentos: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> buscarMusicosPorCulto(String idCulto) {
    return FirebaseFirestore.instance
        .collection('user_culto_instrument')
        .where('idCulto', isEqualTo: idCulto)
        .snapshots() // Usamos snapshots para escutar mudanças em tempo real
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> musicosEncontrados = [];
      print("---------------------- Pessoas no culto :");
      print(querySnapshot
          .docs.length); // Verifique a quantidade de documentos encontrados
      print(idCulto);

      // Armazenar todos os idUser em uma lista
      List<int> idUsers = [];
      for (var documento in querySnapshot.docs) {
        int idUser =
            documento['idUser']; // Pega o idUser do documento encontrado
        idUsers.add(idUser); // Adiciona o idUser à lista
      }
      print("Usuarios");
      print(idUsers);

      // Agora, faça uma única consulta para todos os idUsers
      if (idUsers.isNotEmpty) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('musicos')
            .where('user_id',
                whereIn: idUsers) // Buscar todos os usuários de uma vez
            .get();

        print(userSnapshot.docs);

        // Agora, criamos um mapa de músicos usando os dados dos usuários
        Map<int, String> userMap = {};
        for (var userDoc in userSnapshot.docs) {
          int idUser = userDoc['user_id'];
          String nomeUser = userDoc['name'];
          userMap[idUser] = nomeUser; // Mapear idUser para nome

          print(userDoc['name'] + " " + userDoc['instrument']);
        }

        // Agora, adicionamos as informações de músicos encontrados
        for (var documento in querySnapshot.docs) {
          int idUser = documento['idUser'];
          String instrumento =
              documento['Instrument']; // Pega o instrumento do culto
          if (userMap.containsKey(idUser)) {
            musicosEncontrados.add({
              'idUser': idUser,
              'name': userMap[idUser],
              'Instrument': instrumento,
            });
          }
        }
        print(musicosEncontrados);
      }

      return musicosEncontrados; // Retorna a lista de músicos encontrados
    });
  }

  List<String> _musicianNames = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Widget _buildInstrumentButtons(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('Cultos').doc(widget.documentId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            child: Center(
                child: CircularProgressIndicator(
              color: Colors.black,
            )),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.white)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
              child:
                  Text('No data found', style: TextStyle(color: Colors.white)));
        }

        final cultoData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
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

            final instruments = futureSnapshot.data ?? [];

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (!instruments.contains('Piano'))
                    _buildInstrumentButton(context, "Piano"),
                  if (!instruments.contains('Guitarra'))
                    _buildInstrumentButton(context, "Guitarra"),
                  if (!instruments.contains('Bateria'))
                    _buildInstrumentButton(context, "Bateria"),
                  if (!instruments.contains('Violão'))
                    _buildInstrumentButton(context, "Violão"),
                  if (!instruments.contains('Baixo'))
                    _buildInstrumentButton(context, "Baixo"),
                  if (!instruments.contains('MD'))
                    _buildInstrumentButton(context, "MD"),
                  if (!instruments.contains('Ministro'))
                    _buildInstrumentButton(context, "Ministro"),
                  if (!instruments.contains('BV 1'))
                    _buildInstrumentButton(context, "BV 1"),
                  if (!instruments.contains('BV 2'))
                    _buildInstrumentButton(context, "BV 2"),
                  if (!instruments.contains('BV 3'))
                    _buildInstrumentButton(context, "BV 3"),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInstrumentButton(BuildContext context, String instrument) {
    print(instrument);
    String instrumenta = instrument;
    String a = "";
    if (instrumenta == "Piano") {
      a = "keyboard.png";
    }
    if (instrumenta == "Guitarra") {
      a = "guitarra.png";
    }
    if (instrumenta == "Violão") {
      a = "violao.png";
    }
    if (instrumenta == "Baixo") {
      a = "bass.png";
    }
    if (instrumenta == "Bateria") {
      a = "drum.png";
    }
    if (instrumenta == "MD") {
      a = "md.png";
    }

    if (instrumenta == "Ministro") {
      a = "cantor.png";
    }

    if (instrumenta == "BV 1") {
      a = "cantor.png";
    }

    if (instrumenta == "BV 2") {
      a = "cantor.png";
    }

    if (instrumenta == "BV 3") {
      a = "cantor.png";
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(60)),
        /* boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(
                60, 0, 0, 0), // Sombra alaranjada com 50% de opacidade
            blurRadius: 15,
            offset: Offset(0, 10), // Deslocamento da sombra
          ),
        ],,*/
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
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
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
              border: Border.all(
                color: Color(0xff0A7AFF),
              )),
          margin: EdgeInsets.only(right: 24),
          child: Column(
            children: [
              Icon(
                Icons.music_off_sharp,
                color: Colors.white,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image(
                    height: 50, width: 50, image: AssetImage("assets/" + a)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusicianList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idCulto',
              isEqualTo: widget.documentId) // Filtrando pelo idCulto
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 40,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 40,
            child: Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 40,
            child: Center(
              child: Text(
                'Nenhum dado encontrado.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Processando os dados obtidos
        final userCultoData = snapshot.data!.docs;

        return ListView.builder(
          itemCount: userCultoData.length,
          itemBuilder: (context, index) {
            final userCulto =
                userCultoData[index].data() as Map<String, dynamic>;

            // Garantir que os campos existam, caso contrário, usar valores padrão
            final userId = userCulto['idUser'] ?? 'Sem user_id';
            final instrument = userCulto['Instrument'] ?? 'Sem instrumento';

            // Consultando a coleção "musicos" usando o campo 'user_id'
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('musicos')
                  .where('user_id',
                      isEqualTo: userId) // Pesquisar pelo campo 'user_id'
                  .snapshots(),
              builder: (context, musicianSnapshot) {
                if (musicianSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              instrument,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.deepPurple,
                              ),
                            ),
                            CircularProgressIndicator(), // Indicador de carregamento
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (musicianSnapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              instrument,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              'Erro ao carregar o nome do músico',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (!musicianSnapshot.hasData ||
                    musicianSnapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 2.0, horizontal: 5.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              instrument,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              'Nome do músico não encontrado',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Obtendo o nome do músico
                final musicianName = musicianSnapshot.data!.docs[0]['name'] ??
                    'Nome não disponível';

                // Obtendo o nome do músico
                final avatar = musicianSnapshot.data!.docs[0]['photoUrl'] ??
                    'Nome não disponível';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 5.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      tileColor: Colors.white,
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Container(
                                  width: 40,
                                  height: 40,
                                  child: Image.network(avatar)),
                              Text(
                                capitalize(
                                    musicianName), // Exibe o nome do músico
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                instrument,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xff0A7AFF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          // Exemplo de ação
                          await FirebaseFirestore.instance
                              .collection('user_culto_instrument')
                              .doc(userCultoData[index].id)
                              .delete()
                              .then((_) async {
                            _showSnackBar('Registro excluído com sucesso!');

                            final now = DateTime.now();
                            await FirebaseFirestore.instance
                                .collection('notificacoes')
                                .add({
                              'user_id': userId,
                              'data': "${now.year}-${now.month}-${now.day}",
                              'hora': "${now.hour}:${now.minute}:${now.second}",
                              'titulo': "Escala",
                              'mensagem': "Registro excluído com sucesso!",
                            });
                          }).catchError((error) {
                            _showSnackBar('Erro ao excluir o registro: $error');
                          });
                        },
                      ),
                    ),
                  ),
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
    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        Container(height: 200, child: _buildMusicianList()),
        AvailableInstrumentsWidget(documentId: widget.documentId),
      ],
    );
  }
}

class AvailableInstrumentsWidget extends StatefulWidget {
  final String documentId;

  AvailableInstrumentsWidget({required this.documentId});

  @override
  _AvailableInstrumentsWidgetState createState() =>
      _AvailableInstrumentsWidgetState();
}

class _AvailableInstrumentsWidgetState
    extends State<AvailableInstrumentsWidget> {
  // Lista de todos os instrumentos
  final List<String> allInstruments = [
    'Piano',
    'Violão',
    'Guitarra',
    'Vocal 1',
    'Vocal 2',
    'Ministro',
    'Bateria',
    'Baixo',
  ];

  // Lista para armazenar os instrumentos que estão em uso
  List<String> usedInstruments = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: widget.documentId)
          .snapshots(), // Escuta as alterações em tempo real
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        // Caso a coleção esteja vazia, significa que todos os instrumentos estão disponíveis
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          usedInstruments =
              []; // Nenhum instrumento está em uso, todos estão disponíveis
        } else {
          // Coletar os instrumentos em uso e filtrar valores nulos
          final usedInstrumentsSet = snapshot.data!.docs
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['Instrument'] as String?)
              .where((instrument) => instrument != null)
              .toSet();

          // Atualizar a lista de instrumentos usados
          usedInstruments = usedInstrumentsSet.cast<String>().toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Instrumentos disponíveis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            if (usedInstruments.isEmpty) // Verifica se todos estão disponíveis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Todos os instrumentos estão disponíveis.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (usedInstruments.length == allInstruments.length)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Todos os instrumentos já estão em uso.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            // Exibe os botões para os instrumentos disponíveis
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: allInstruments
                  .where((instrument) => !usedInstruments.contains(instrument))
                  .map((instrument) {
                return GestureDetector(
                  onTap: () => Navigator.push(
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChooseMusician(
                            document_id: widget.documentId,
                            instrument: instrument,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          setState(() {}); // Atualiza a página se algo mudou
                        }
                      });
                      print('Instrumento selecionado: $instrument');
                      // Você pode atualizar a coleção do Firestore aqui
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      backgroundColor: Color(0xfff9fafc), // Fundo branco
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ), // Cor do botão
                    ),
                    child: Text(
                      instrument,
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class MusicianCard extends StatelessWidget {
  final String imageUrl;
  final String musicianName;
  final int cultosEscalados;

  MusicianCard({
    required this.imageUrl,
    required this.musicianName,
    required this.cultosEscalados,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Circular image
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(imageUrl),
                backgroundColor: Colors.grey[200],
              ),
              SizedBox(width: 12),
              // Text info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    musicianName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.event_note,
                        color: Colors.deepPurple,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$cultosEscalados cultos escalados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChooseMusician extends StatefulWidget {
  final String document_id;
  final String instrument;

  ChooseMusician({required this.document_id, required this.instrument});

  @override
  _ChooseMusicianState createState() => _ChooseMusicianState();
}

class _ChooseMusicianState extends State<ChooseMusician> {
  late Future<List<Map<String, dynamic>>> _nonEscalados;

  @override
  void initState() {
    super.initState();
    // Carregar os músicos não escalados
    _nonEscalados = _getNonEscalados();
  }

  Future<List<Map<String, dynamic>>> _getNonEscalados() async {
    try {
      // Consulta para obter todos os userId dos usuários escalados
      final escaladosSnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: widget.document_id)
          .get();

      // Se não houver registros de escalados, todos os músicos estão disponíveis
      if (escaladosSnapshot.docs.isEmpty) {
        final musicoSnapshot =
            await FirebaseFirestore.instance.collection('musicos').get();
        return musicoSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      } else {
        // Extrair os userId dos usuários escalados, convertendo para int
        List<int> escaladosUserIds =
            escaladosSnapshot.docs.map((doc) => doc['idUser'] as int).toList();
        print(escaladosUserIds);

        // Consulta para obter os músicos não escalados
        final musicoSnapshot = await FirebaseFirestore.instance
            .collection('musicos')
            .where('user_id', whereNotIn: escaladosUserIds)
            .get();

        // Retorna a lista de músicos não escalados
        return musicoSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      // Caso haja algum erro
      print("Erro ao buscar músicos não escalados: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.instrument),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _nonEscalados,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
                height: 50, child: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Container(
                height: 50,
                child: Center(child: Text('Erro ao carregar os músicos')));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container(
                height: 50,
                child: Center(child: Text('Nenhum músico disponível')));
          }

          final musicoData = snapshot.data!;

          return ListView.builder(
            itemCount: musicoData.length,
            itemBuilder: (context, index) {
              final musico = musicoData[index];

              final userName = musico['name'] ?? 'Sem nome';
              final userId =
                  musico['user_id'] ?? 0; // Asegure-se que user_id seja um int
              final instrument = musico['instrument'] ?? 'Sem instrumento';

              return Card(
                child: ListTile(
                  title: Text(userName),
                  subtitle: Text('Instrumento: $instrument'),
                  trailing: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      // Ação para adicionar esse músico ao culto
                      FirebaseFirestore.instance
                          .collection('user_culto_instrument')
                          .add({
                        'idUser': userId,
                        'idCulto': widget.document_id,
                        'Instrument': widget.instrument,
                      }).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Músico adicionado com sucesso!'),
                          ),
                        );
                        // Volta para a página anterior após adicionar o músico
                        Navigator.pop(context);
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao adicionar músico: $error'),
                          ),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
