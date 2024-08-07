import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/pages/login.dart';
import 'dart:math';

class AddtoPlaylist extends StatefulWidget {
  final String document_id;

  const AddtoPlaylist({required this.document_id});

  @override
  State<AddtoPlaylist> createState() => _AddtoPlaylistState();
}

class _AddtoPlaylistState extends State<AddtoPlaylist> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedKey; // Armazena o tom selecionado

  Future<List<String>> _getPlaylistMusicIds() async {
    try {
      DocumentReference cultoRef =
          _firestore.collection('Cultos').doc(widget.document_id);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      List<dynamic> playlist = cultoDoc['playlist'] ?? [];
      return playlist.map((item) => item['music_document'] as String).toList();
    } catch (e) {
      print('Erro ao obter IDs das músicas na playlist: $e');
      return [];
    }
  }

  Future<void> _showKeyDialog(String documentId) async {
    // Exibe o diálogo e aguarda o fechamento
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
                selectedKey = key; // Atualiza o tom selecionado
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
                _saveToPlaylist(documentId);
                Navigator.of(context).pop(); // Salva a música na playlist
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              )),
        ),
        centerTitle: true,
        title: Text(
          "Adicionar Canção",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
              onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => login()),
                  ),
              child: Icon(
                Icons.login,
                color: Colors.white,
              )),
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.black,
      ),
      backgroundColor: Color(0xff010101),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(57.0),
              child: Container(
                height: 500,
                child: FutureBuilder<List<String>>(
                  future: _getPlaylistMusicIds(),
                  builder: (context, playlistSnapshot) {
                    if (!playlistSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final List<String> playlistMusicIds =
                        playlistSnapshot.data!;

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore.collection('music_database').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final List<DocumentSnapshot> documents =
                            snapshot.data!.docs;

                        // Filtrar músicas que já estão na playlist
                        final List<DocumentSnapshot> filteredDocuments =
                            documents
                                .where(
                                    (doc) => !playlistMusicIds.contains(doc.id))
                                .toList();

                        return ListView.builder(
                          padding: EdgeInsets.all(0),
                          itemCount: filteredDocuments.length,
                          itemBuilder: (context, index) {
                            final data = filteredDocuments[index].data()
                                as Map<String, dynamic>;
                            var documentId = filteredDocuments[index].id;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 270,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    trailing: GestureDetector(
                                      onTap: () async {
                                        await _showKeyDialog(documentId);
                                      },
                                      child: Icon(
                                        Icons.add,
                                        color: Color(0xff4465D9),
                                      ),
                                    ),
                                    title: Text(
                                      data['Author'] ?? 'No title',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      data['Music'] ?? 'No artist',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w200,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      );

      final double buttonRadius = 30;
      final Paint buttonPaint = Paint()
        ..color = Color(0xff444444)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          textOffset + Offset(textPainter.width / 2, textPainter.height / 2),
          buttonRadius,
          buttonPaint);
      canvas.save();
      canvas.translate(textOffset.dx + textPainter.width / 2,
          textOffset.dy + textPainter.height / 2);
      canvas.rotate(-rotationAngle); // Desfaz a rotação do canvas
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
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
