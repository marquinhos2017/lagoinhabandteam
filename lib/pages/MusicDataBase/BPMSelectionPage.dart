import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

String removeDecimal(String value) {
  double number = double.parse(value);
  return number.toStringAsFixed(0);
}

class BPMSelectorPage extends StatefulWidget {
  final String documentId;

  BPMSelectorPage({required this.documentId});

  @override
  _BPMSelectorPageState createState() => _BPMSelectorPageState();
}

class _BPMSelectorPageState extends State<BPMSelectorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _bpm = 120; // Valor inicial do BPM
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escolher BPM'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: Offset(0, 10), // changes position of shadow
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${_bpm.toStringAsFixed(0)} BPM',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Slider(
                value: _bpm,
                min: 60,
                max: 200,
                divisions: 140,
                label: _bpm.toStringAsFixed(0),
                onChanged: (value) {
                  setState(() {
                    _bpm = value;
                  });
                },
              ),
              SizedBox(height: 20),
              _isSaving
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveBPM,
                      child: Text('Salvar BPM'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBPM() async {
    setState(() {
      _isSaving = true;
    });

    String result = removeDecimal(_bpm.toString());
    try {
      // Atualizar o documento diretamente usando o documentId
      await _firestore
          .collection('music_database')
          .doc(widget.documentId) // Usando o documentId diretamente
          .update({'bpm': result});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BPM salvo com sucesso!')),
      );
    } catch (e) {
      print('Error saving BPM: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar BPM.')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
