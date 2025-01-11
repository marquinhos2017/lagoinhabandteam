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
  final _instrumentController = TextEditingController();
  final _tipoController = TextEditingController();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _verFormulario = false;
  String? _selectedAvatar;
  bool _isAdmin = false;

  // Instrumentos disponíveis com checkboxes
  List<String> _selectedInstruments = [];
  final List<String> _instruments = [
    'Bateria',
    'Violão',
    'Guitarra',
    'Vocal',
  ];

  // Avatares disponíveis
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

  Future<void> _addMusician() async {
    if (_formKey.currentState!.validate()) {
      String? downloadUrl;

      if (_selectedAvatar != null) {
        // Converte o asset em um arquivo temporário
        File avatarFile = await _getFileFromAsset(_selectedAvatar!);
        // Faz o upload do arquivo para o Firebase
        downloadUrl = await _uploadImageToFirebase(avatarFile);
      }

      // Adiciona os dados ao Firestore
      await FirebaseFirestore.instance.collection('musicos').add({
        'name': _nameController.text,
        'instrument': _selectedInstruments.join(', '),
        'tipo': _isAdmin ? 'Admin' : 'User',
        'user_id': int.tryParse(_userIdController.text) ?? 0,
        'password': _passwordController.text,
        'ver_formulario': _verFormulario,
        'photoUrl': downloadUrl,
        'email': _emailController.text,
      });

      Navigator.of(context).pop();
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao enviar imagem: $e');
      return null;
    }
  }

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
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Selecione um Avatar',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Divider(color: Colors.white),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _avatars.length,
                itemBuilder: (BuildContext context, int index) {
                  String avatar = _avatars[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = avatar;
                      });
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(avatar),
                      child: _selectedAvatar == avatar
                          ? Icon(Icons.check, color: Colors.green, size: 28)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: Text('Adicionar Músico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... Campos do formulário (email, nome, instrumentos, etc.)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o email';
                  }
                  // Validação de email simples
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Insira um email válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Checkboxes para os instrumentos
              Text(
                'Selecione os instrumentos:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              ..._instruments.map((instrument) {
                return CheckboxListTile(
                  title:
                      Text(instrument, style: TextStyle(color: Colors.white)),
                  value: _selectedInstruments.contains(instrument),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedInstruments.add(instrument);
                      } else {
                        _selectedInstruments.remove(instrument);
                      }
                    });
                  },
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                );
              }).toList(),
              SizedBox(height: 16),

              SizedBox(height: 16),
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o user ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Insira um número válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a senha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Ver Formulário',
                    style: TextStyle(color: Colors.white)),
                value: _verFormulario,
                onChanged: (bool value) {
                  setState(() {
                    _verFormulario = value;
                  });
                },
              ),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Admin', style: TextStyle(color: Colors.white)),
                value: _isAdmin,
                onChanged: (bool value) {
                  setState(() {
                    _isAdmin = value;
                  });
                },
              ),
              SizedBox(height: 16),
              SizedBox(height: 16),
              Text(
                'Avatar Selecionado:',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: _selectedAvatar != null
                        ? AssetImage(_selectedAvatar!)
                        : null,
                    child: _selectedAvatar == null
                        ? Icon(Icons.person, color: Colors.white, size: 32)
                        : null,
                  ),
                  SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: _showAvatarSelectionSheet,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addMusician,
                child: Text('Adicionar'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
