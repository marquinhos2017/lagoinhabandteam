import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:lagoinha_music/main.dart';
import 'package:lagoinha_music/pages/MusicianPage/musicianPageNewUI.dart';
import 'package:lagoinha_music/pages/adminWorshipTeamSelect2.dart';
import 'package:provider/provider.dart';

String capitalize(String text) {
  if (text == null || text.isEmpty) {
    return text;
  }
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

class EditProfilePage extends StatefulWidget {
  final String userId;

  EditProfilePage({required this.userId});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _instrumentController = TextEditingController();
  File? _profileImage; // Armazena a nova imagem escolhida
  bool _isLoading = false;
  String _photoUrl = ""; // URL da imagem do Firestore
  String? _documentId; // ID do documento no Firestore

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // Carregar dados do Firestore com base no campo user_id
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('musicos')
        .where('user_id', isEqualTo: int.parse(widget.userId))
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot userDoc = querySnapshot.docs.first;

      setState(() {
        _nameController.text = userDoc['name'];
        _passwordController.text = userDoc['password'];
        _instrumentController.text = userDoc['instrument'];
        _photoUrl = userDoc['photoUrl'] ?? "";
        _documentId = userDoc.id; // Armazena o ID do documento
      });
    }
  }

  Future<void> _uploadImageToFirebase() async {
    if (_profileImage == null) return;

    try {
      String fileName = '${widget.userId}_profile.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');
      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Atualizar o Firestore com o URL da nova imagem
      await FirebaseFirestore.instance
          .collection('musicos')
          .doc(_documentId)
          .update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
      });
    } catch (e) {
      print('Erro ao enviar imagem: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Na página de edição
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_profileImage != null) {
          await _uploadImageToFirebase();
        }

        await FirebaseFirestore.instance
            .collection('musicos')
            .doc(_documentId)
            .update({
          'name': _nameController.text,
          'password': _passwordController.text,
          'instrument': _instrumentController.text,
          'tipo': 'user',
          'ver_formulario': false,
        });

        Navigator.pop(context, true); // Indica que os dados foram atualizados
      } catch (e) {
        print('Erro ao salvar perfil: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Seu Perfil'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 75, // Ajuste o raio conforme necessário
                        backgroundColor: Colors
                            .grey[200], // Cor de fundo quando não há imagem
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : _photoUrl.isNotEmpty
                                ? NetworkImage(_photoUrl)
                                    as ImageProvider<Object>
                                : null,
                        child: _profileImage == null && _photoUrl.isEmpty
                            ? Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey[800],
                              )
                            : null,
                      ),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Center(
                        child: Text(
                      _nameController.text.toCapitalized(),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )),
                    Center(
                      child: Text(
                        _instrumentController.text,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      height: 42,
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        fillColor: Color(0xfff7f6f9), // Cor do fundo
                        filled: true, // Habilita a cor de fundo
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              8.0), // Arredondamento dos cantos
                          borderSide: BorderSide.none, // Remove a borda padrão
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .blue), // Cor da borda quando o campo está focado
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .grey), // Cor da borda quando o campo está habilitado
                        ),
                        suffixIcon: Icon(
                          Icons.person, // Ícone que você deseja adicionar
                          color: Colors.grey[600], size: 12, // Cor do ícone
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        suffixIcon: Icon(
                          Icons.lock,
                          size: 12,
                        ),
                        labelText: 'Senha',
                        fillColor: Color(0xfff7f6f9), // Cor do fundo
                        filled: true, // Habilita a cor de fundo
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              8.0), // Arredondamento dos cantos
                          borderSide: BorderSide.none, // Remove a borda padrão
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .blue), // Cor da borda quando o campo está focado
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .grey), // Cor da borda quando o campo está habilitado
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a senha';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    TextFormField(
                      controller: _instrumentController,
                      decoration: InputDecoration(
                        labelText: 'Instrumento',
                        fillColor: Colors.grey[200], // Cor do fundo
                        filled: true, // Habilita a cor de fundo
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              8.0), // Arredondamento dos cantos
                          borderSide: BorderSide.none, // Remove a borda padrão
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .blue), // Cor da borda quando o campo está focado
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                              color: Colors
                                  .grey), // Cor da borda quando o campo está habilitado
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o instrumento';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    SizedBox(height: 20),

                    /* GestureDetector(
                      onTap: _pickImage,
                      child: _profileImage == null
                          ? (_photoUrl.isNotEmpty
                              ? Image.network(_photoUrl, height: 150)
                              : Text('Nenhuma foto selecionada'))
                          : Image.file(_profileImage!, height: 150),
                    ),*/
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('Salvar Perfil'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
