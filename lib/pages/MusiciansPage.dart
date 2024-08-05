import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MusiciansPage extends StatefulWidget {
  @override
  _MusiciansPageState createState() => _MusiciansPageState();
}

class _MusiciansPageState extends State<MusiciansPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Músico excluído com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var musicianData = widget.musician.data() as Map<String, dynamic>;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white30, width: 1),
      ),
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  musicianData['name'],
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
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
                  Text('Instrumento: ${musicianData['instrument']}',
                      style: TextStyle(color: Colors.white70)),
                  Text('Tipo: ${musicianData['tipo']}',
                      style: TextStyle(color: Colors.white70)),
                  Text('User ID: ${musicianData['user_id']}',
                      style: TextStyle(color: Colors.white70)),
                  Text(
                      'Ver Formulário: ${musicianData['ver_formulario'] ? "Sim" : "Não"}',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
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
  bool _verFormulario = false;

  Future<void> _addMusician() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('musicos').add({
        'name': _nameController.text,
        'instrument': _instrumentController.text,
        'tipo': _tipoController.text,
        'user_id': int.tryParse(_userIdController.text) ?? 0,
        'password': _passwordController.text, // Adicionando o campo de senha
        'ver_formulario': _verFormulario,
      });

      Navigator.of(context).pop();
    }
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
              TextFormField(
                controller: _instrumentController,
                decoration: InputDecoration(
                  labelText: 'Instrumento',
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
                    return 'Por favor, insira o instrumento';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tipoController,
                decoration: InputDecoration(
                  labelText: 'Tipo',
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
                    return 'Por favor, insira o tipo';
                  }
                  return null;
                },
              ),
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
                obscureText: true, // Oculta o texto da senha
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
