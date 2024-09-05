import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  File? _profileImage;
  bool _isLoading = false;
  String _photoUrl = "";
  String? _documentId; // Armazenar o ID do documento aqui

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

    setState(() {
      _isLoading = true;
    });

    try {
      // Subir imagem para o Firebase Storage
      String fileName = '${widget.userId}_profile.jpg';
      Reference storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');
      UploadTask uploadTask = storageRef.putFile(_profileImage!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Atualizar Firestore com o URL da imagem
      await FirebaseFirestore.instance
          .collection('musicos')
          .doc(_documentId)
          .update({'photoUrl': downloadUrl});

      setState(() {
        _photoUrl = downloadUrl;
      });
    } catch (e) {
      print('Erro ao enviar imagem: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore.instance.collection('musicos').doc(_documentId).update({
        'name': _nameController.text,
        'password': _passwordController.text,
        'instrument': _instrumentController.text,
        'tipo': 'user',
        'ver_formulario': false,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Nome'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a senha';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _instrumentController,
                      decoration: InputDecoration(labelText: 'Instrumento'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o instrumento';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _profileImage == null
                        ? (_photoUrl.isNotEmpty
                            ? Image.network(_photoUrl, height: 150)
                            : Text('Nenhuma foto selecionada'))
                        : Image.file(_profileImage!, height: 150),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Selecionar Foto'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadImageToFirebase,
                      child: Text('Fazer Upload da Foto'),
                    ),
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
