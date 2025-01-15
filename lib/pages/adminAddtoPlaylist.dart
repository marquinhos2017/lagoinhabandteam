import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/pages/login.dart';

//Esse aqui

class AddtoPlaylist extends StatefulWidget {
  final String document_id;

  const AddtoPlaylist({required this.document_id});

  @override
  State<AddtoPlaylist> createState() => _AddtoPlaylistState();
}

class _AddtoPlaylistState extends State<AddtoPlaylist> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedKey; // Armazena o tom selecionado
  TextEditingController _searchController =
      TextEditingController(); // Controlador de busca
  String _searchText = ""; // Texto de busca
  Set<String> _selectedMusicIds =
      Set(); // Armazena IDs das músicas já selecionadas
  List<Map<String, dynamic>> _addedMusics =
      []; // Armazena informações das músicas adicionadas

  Future<List<String>> _getPlaylistMusicIds() async {
    try {
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.document_id);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      List<dynamic> playlist = cultoDoc['playlist'] ?? [];
      _addedMusics = playlist
          .map((item) => {
                'id': item['music_document'],
                'key': item['key'],
              })
          .toList();

      return playlist.map((item) => item['music_document'] as String).toList();
    } catch (e) {
      print('Erro ao obter IDs das músicas na playlist: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getPlaylistMusicsDetails() async {
    try {
      // Referência para o documento de culto
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.document_id);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      // Pegando a playlist do culto
      List<dynamic> playlist = cultoDoc['playlist'] ?? [];

      // A lista para armazenar as músicas com os detalhes
      List<Map<String, String>> musicsDetails = [];

      for (var item in playlist) {
        String musicDocument = item['music_document'];
        print("Documento");
        print(musicDocument);

        // Buscar o documento da música na coleção music_database
        DocumentSnapshot musicSnapshot = await FirebaseFirestore.instance
            .collection('music_database')
            .doc(musicDocument)
            .get();

        if (musicSnapshot.exists) {
          var musicData = musicSnapshot.data() as Map<String, dynamic>;

          // Adicionando os detalhes da música à lista
          musicsDetails.add({
            'id': musicDocument,
            'key': item['key'],
            'Author': musicData['Author'] ?? 'Autor desconhecido',
            'Music': musicData['Music'] ?? 'Título não disponível',
          });
        }
      }

      // Retorna a lista com os detalhes das músicas
      return musicsDetails;
    } catch (e) {
      print('Erro ao obter detalhes das músicas na playlist: $e');
      return [];
    }
  }

  Future<void> _showKeyDialog(String documentId) async {
    setState(() {
      selectedKey = 'C'; // Set default key to "C"
    });

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: const Text(
              'Selecione o tom',
            ),
          ),
          titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          backgroundColor: Colors.white,
          content: KeySelectorGrid(
            initialKey: selectedKey,
            onSelect: (String key) {
              setState(() {
                selectedKey = key; // Update selected key
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SALVAR', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _saveToPlaylist(documentId);
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
            _firestore.collection('Cultos').doc(widget.document_id);
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

        setState(() {
          _selectedMusicIds
              .add(documentId); // Adiciona a música à lista de selecionados
        });

        // Atualiza a lista de músicas adicionadas
        await _getPlaylistMusicsDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color(0xff4465D9),
            content: Text('Música adicionada à playlist com sucesso'),
            duration: Duration(seconds: 2),
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
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddedMusics() async {
    // Chama o método assíncrono que retorna os detalhes das músicas
    List<Map<String, String>> musicsDetails = await _getPlaylistMusicsDetails();

    // Mostra o bottom sheet com as músicas
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Músicas Adicionadas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // Exibe as músicas usando um ListView
              Expanded(
                child: ListView.builder(
                  itemCount: musicsDetails.length,
                  itemBuilder: (context, index) {
                    var music = musicsDetails[index];
                    return ListTile(
                      title: Text(music['Music'] ?? 'Título não disponível'),
                      subtitle:
                          Text('Autor: ${music['Author'] ?? 'Desconhecido'}'),
                    );
                  },
                ),
              ),
              TextButton(
                child:
                    const Text('FECHAR', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        leading: Container(
          child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
              )),
        ),
        centerTitle: true,
        title: Text(
          "Adicionar à Playlist",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            color: Colors.black,
            onPressed: _showAddedMusics,
          ),
        ],
        foregroundColor: Colors.black,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar músicas...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.black),
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _getPlaylistMusicIds(),
                builder: (context, playlistSnapshot) {
                  if (!playlistSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final List<String> playlistMusicIds = playlistSnapshot.data!;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('music_database').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final List<DocumentSnapshot> documents =
                          snapshot.data!.docs;

                      // Filtrar músicas que já estão na playlist
                      final List<DocumentSnapshot> filteredDocuments =
                          documents.where(
                        (doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final musicName = data['Music'] ?? '';
                          final authorName = data['Author'] ?? '';
                          return !playlistMusicIds.contains(doc.id) &&
                              (musicName
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()) ||
                                  authorName
                                      .toLowerCase()
                                      .contains(_searchText.toLowerCase()));
                        },
                      ).toList();

                      return LayoutBuilder(
                        // Adicionado para garantir que o ListView preencha o espaço disponível
                        builder: (context, constraints) {
                          return ListView.builder(
                            padding: EdgeInsets.all(0),
                            itemCount: filteredDocuments.length,
                            itemBuilder: (context, index) {
                              final data = filteredDocuments[index].data()
                                  as Map<String, dynamic>;
                              var documentId = filteredDocuments[index].id;

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            const Color.fromARGB(17, 0, 0, 0),
                                        spreadRadius: 2,
                                        blurRadius: 15,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: ListTile(
                                            leading: Container(
                                              width:
                                                  40, // Defina a largura do quadrado
                                              height:
                                                  40, // Defina a altura do quadrado para ser igual à largura
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(
                                                    8), // Opcional: bordas arredondadas
                                              ),
                                              child: Image.asset(
                                                  "assets/placeholderalbumcover.png"),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                            trailing: GestureDetector(
                                              onTap: () async {
                                                await _showKeyDialog(
                                                    documentId);
                                              },
                                              child: Icon(
                                                Icons.add,
                                                color: _selectedMusicIds
                                                        .contains(documentId)
                                                    ? Colors.green
                                                    : Color(0xff4465D9),
                                              ),
                                            ),
                                            title: Text(
                                              data['Author'] ?? 'No title',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              data['Music'] ?? 'No artist',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w200,
                                              ),
                                            ),
                                          ),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Novo Widget para Seleção de Tons com Botões Quadrados
class KeySelectorGrid extends StatefulWidget {
  final Function(String) onSelect;
  final String? initialKey;

  const KeySelectorGrid({required this.onSelect, this.initialKey, Key? key})
      : super(key: key);

  @override
  _KeySelectorGridState createState() => _KeySelectorGridState();
}

class _KeySelectorGridState extends State<KeySelectorGrid> {
  late String selectedKey; // Make it late to initialize in initState

  @override
  void initState() {
    super.initState();
    selectedKey = widget.initialKey ?? 'C'; // Set default to "C"
  }

  @override
  Widget build(BuildContext context) {
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

    return SizedBox(
      width: 200, // Specify a width for the grid
      height: 400, // Specify a height for the grid
      child: Center(
        child: GridView.builder(
          shrinkWrap: true, // Allow the grid to be as small as possível
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          itemCount: keys.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Number of columns in the grid
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedKey = key; // Update the selected key
                });
                widget.onSelect(key);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: key == selectedKey
                        ? Colors.blue
                        : const Color.fromARGB(255, 238, 238, 238),
                  ),
                  color: key == selectedKey
                      ? Colors.white
                      : const Color.fromARGB(255, 238, 238, 238),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
