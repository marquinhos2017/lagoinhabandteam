import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';

class MusiciansPage extends StatefulWidget {
  @override
  _MusiciansPageState createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  @override
  Widget build(BuildContext context) {
    if (!mounted)
      return Container(); // Early exit if the widget is no longer mounted
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: Text('Músicos'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AddMusicianPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('musicos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var musicians = snapshot.data!.docs;

          return ListView.builder(
            itemCount: musicians.length,
            itemBuilder: (context, index) {
              var musician = musicians[index];
              return MusicianTile(musician);
            },
          );
        },
      ),
    );
  }
}

class MusicianTile extends StatefulWidget {
  final QueryDocumentSnapshot musician;

  MusicianTile(this.musician);

  @override
  _MusicianTileState createState() => _MusicianTileState();
}

class _MusicianTileState extends State<MusicianTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteMusician() async {
    await FirebaseFirestore.instance
        .collection('musicos')
        .doc(widget.musician.id)
        .delete();
    if (mounted) {
      // Check if the widget is still mounted before showing the SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Músico excluído com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var musicianData = widget.musician.data() as Map<String, dynamic>;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white30, width: 1),
      ),
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF1A237E),
                  child: Text(
                    musicianData['name'][0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    musicianData['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.grey[900], // Fundo escuro
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Ícone de confirmação
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red[
                                    50], // Fundo vermelho claro para exclusão
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.delete_forever,
                                size: 48,
                                color: Colors.red, // Ícone vermelho
                              ),
                            ),
                            SizedBox(height: 16),
                            // Título
                            Text(
                              'Excluir Músico',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white, // Texto branco
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Mensagem
                            Text(
                              'Tem certeza que deseja excluir este músico?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white, // Texto branco
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Botões de ação
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Botão Cancelar
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor:
                                        Colors.white, // Texto preto
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                          color: Colors.black), // Borda preta
                                    ),
                                  ),
                                  child: Text('Cancelar'),
                                ),
                                // Botão Excluir
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context, true);
                                    await _deleteMusician(); // Ação de exclusão
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red, // Texto branco
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),
                  Text('Instrumento: ${musicianData['instrument']}'),
                  Text('Nome: ${musicianData['name']}'),
                  Text('Senha: ${musicianData['password']}'),
                  Text('Foto de Perfil:'),
                  Image.network(
                    musicianData['photoUrl'],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Text('Tipo: ${musicianData['tipo']}'),
                  Text('ID de Usuário: ${musicianData['user_id']}'),
                  Text(
                      'Ver Formulário: ${musicianData['ver_formulario'] ? "Sim" : "Não"}'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(Icons.delete, color: Colors.red),
                      label:
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text(
                                'Excluir Músico',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Tem certeza que deseja excluir este músico?',
                                style: TextStyle(color: Colors.white),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Cancelar'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                TextButton(
                                  child: Text('Excluir'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _deleteMusician();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AddMusicianPage extends StatefulWidget {
  @override
  _AddMusicianPageState createState() => _AddMusicianPageState();
}

class _AddMusicianPageState extends State<AddMusicianPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isAdmin = false;
  bool _verFormulario = false;
  List<String> _selectedInstruments = [];
  final List<String> _instruments = [
    'Guitarra',
    'Violão',
    'Baixo',
    'Violino',
    'Vocal',
    'Bateria',
    'Percussionista',
    'Teclado',
  ];

  final List<String> _avatars = [
    'assets/profile_drum.png',
    'assets/profile_guitar.png',
    'assets/profile_bass.png',
    'assets/profile_piano.png',
    'assets/profile_violao.png',
    'assets/profile_vocal1.png',
    'assets/profile_vocal2.png',
    'assets/profile_vocal3.png',
    'assets/profile_vocal4.png',
  ];
  String? _selectedAvatar = 'assets/profile_vocal1.png';
  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');

      // Adicionando metadata explícita
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      // Enviando com metadata
      UploadTask uploadTask = storageRef.putFile(image, metadata);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return null;
    }
  }

  Future<void> _addMusician() async {
    if (_formKey.currentState!.validate()) {
      String? downloadUrl;
      if (_selectedAvatar != null) {
        File avatarFile = await _getFileFromAsset(_selectedAvatar!);
        downloadUrl = await _uploadImageToFirebase(avatarFile);
      }

      if (downloadUrl != null) {
        await FirebaseFirestore.instance.collection('musicos').add({
          'name': _nameController.text,
          'email': _emailController.text,
          'user_id': int.tryParse(_userIdController.text) ?? 0,
          'password': _passwordController.text,
          'instrument': _selectedInstruments.join(', '),
          'tipo': _isAdmin ? 'Admin' : 'user',
          'ver_formulario': _verFormulario,
          'photoUrl':
              downloadUrl, // Agora você só salva se o downloadUrl não for nulo
        });

        // Exibindo o AlertDialog
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Sucesso"),
              content: Text("Músico adicionado com sucesso!"),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o diálogo
                    Navigator.of(context).pop(); // Fecha a página atual
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Caso não tenha foto de avatar
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Erro"),
              content: Text(
                  "Não foi possível fazer o upload da imagem. Tente novamente."),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o diálogo
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

/* se usar apenas esse, no android nao funciona o upload de photos ou acesso ao firestore, apenas no ios
  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      // Gerando o nome do arquivo com timestamp
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');

      // Fazendo o upload do arquivo
      UploadTask uploadTask = storageRef.putFile(image);

      // Esperando o upload finalizar
      TaskSnapshot snapshot = await uploadTask;

      // Obtendo o URL de download do arquivo
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return null;
    }
  }*/

  Future<File> _getFileFromAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    Directory tempDir = await getTemporaryDirectory();
    File file = File('${tempDir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(data.buffer.asUint8List());
    return file;
  }

  void _showAvatarSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _avatars.length,
          itemBuilder: (context, index) {
            String avatar = _avatars[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatar = avatar;
                });
                Navigator.pop(context);
              },
              child: CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage(avatar),
                child: _selectedAvatar == avatar
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff3f3f7),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xfff3f3f7),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          children: [
            GestureDetector(
              onTap: _showAvatarSelectionSheet,
              child: Container(
                width: 100, // Duplicando o raio (2 * radius)
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: _selectedAvatar != null
                      ? DecorationImage(
                          image: AssetImage(_selectedAvatar!),
                          fit: BoxFit
                              .contain, // Contém a imagem dentro do círculo
                        )
                      : null,
                  color: _selectedAvatar == null
                      ? Colors.grey[200]
                      : null, // Cor de fundo para o ícone
                ),
                child: _selectedAvatar == null
                    ? Icon(Icons.person, color: Colors.grey) // Ícone padrão
                    : null,
              ),
            ),
            //       _buildSectionTitle('Informações Básicas'),
            SizedBox(
              height: 24,
            ),

            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      'Nome',
                      TextInputType.text,
                      placeholder: 'Nome',
                    ),
                    _buildTextField(
                        _emailController, 'Email', TextInputType.emailAddress,
                        placeholder: 'Email'),
                    _buildTextField(
                        _userIdController, 'User ID', TextInputType.number,
                        placeholder: 'Number'),
                    _buildTextField(
                        _passwordController, 'Senha', TextInputType.text,
                        obscureText: true, placeholder: 'Senha'),
                    _buildSectionTitle('Instrumentos'),
                    _buildInstrumentSelection(),
                    //   _buildSectionTitle('Avatar'),
                  ],
                ),
              ),
            ),

            /*
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: _selectedAvatar != null
                    ? AssetImage(_selectedAvatar!)
                    : null,
                child: _selectedAvatar == null
                    ? Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              title: Text('Selecionar Avatar'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _showAvatarSelectionSheet,
            ),*/
            Divider(),
            SwitchListTile(
              title: Text('Admin'),
              value: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value),
            ),
            SwitchListTile(
              title: Text('Ver Formulário'),
              value: _verFormulario,
              onChanged: (value) => setState(() => _verFormulario = value),
            ),
            SizedBox(height: 32),

            /*     Center(
              child: ElevatedButton(
                onPressed: _addMusician,
                child: Text('Adicionar'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),*/
            GestureDetector(
              child: Text(
                  "Clique aqui para adicionar novo usuario ou no botao flutuante"),
              onTap: () => {
                print("Adicionado"),
                _addMusician(),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ação para o botão flutuante
          _addMusician();
          print("Botão flutuante pressionado");
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue, // Cor de fundo do botão flutuante
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    TextInputType keyboardType, {
    bool obscureText = false,
    required String placeholder, // Novo parâmetro opcional
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(label, style: TextStyle(fontSize: 16, color: Colors.grey)),
        TextFormField(
          style: TextStyle(fontSize: 12),
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: (value) => value == null || value.isEmpty
              ? 'Por favor, insira $label'
              : null,
          decoration: InputDecoration(
            hintText: placeholder, // Define o placeholder
            hintStyle: TextStyle(
                fontSize: 12,
                color: const Color.fromARGB(
                    255, 132, 132, 132)), // Estilo do placeholder
            border: UnderlineInputBorder(),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: const Color.fromARGB(255, 132, 132, 132)),
            ),
          ),
        ),
        //  SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInstrumentSelection() {
    return Wrap(
      spacing: 8.0, // Espaçamento horizontal entre os itens
      runSpacing: 8.0, // Espaçamento vertical entre as linhas
      children: _instruments.map((instrument) {
        final isSelected = _selectedInstruments.contains(instrument);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInstruments.remove(instrument);
              } else {
                _selectedInstruments.add(instrument);
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
            child: Text(
              instrument,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
