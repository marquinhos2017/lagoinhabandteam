import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lagoinha_music/main.dart';
import 'package:provider/provider.dart';

class CultosScreen extends StatefulWidget {
  @override
  _CultosScreenState createState() => _CultosScreenState();
}

class _CultosScreenState extends State<CultosScreen> {
  @override
  void initState() {
    super.initState();
  }

  Stream<List<Map<String, dynamic>>> _getCultos() {
    // Obter o userId do AuthProvider
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) {
      print("Erro: userId é null");
      return Stream.value([]); // Retorna uma lista vazia em vez de um erro
    }

    print("UserID: $userId");

    // Escutar as alterações na coleção 'user_culto_instrument'
    return FirebaseFirestore.instance
        .collection('user_culto_instrument')
        .where('idUser', isEqualTo: int.parse(userId))
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return [];
      }
      print(userId);

      // Obter todos os idCulto dos registros encontrados
      List<String> idCultos =
          snapshot.docs.map((doc) => doc['idCulto'] as String).toList();
      print("ID Cultos encontrados: $idCultos");

      // Agora, buscamos os cultos com os idCultos, mas uma consulta por vez
      List<Map<String, dynamic>> cultosData = [];

      for (String idCulto in idCultos) {
        final cultoDoc = await FirebaseFirestore.instance
            .collection('Cultos')
            .doc(idCulto)
            .get();

        if (cultoDoc.exists) {
          // Encontrar o 'instrument' relacionado ao culto
          // Acesse corretamente o campo 'instrument' diretamente da coleção user_culto_instrument
          final instrument = snapshot.docs
              .firstWhere((doc) => doc['idCulto'] == idCulto)['Instrument'];
          cultosData.add({
            'id': idCulto ?? 'Nome não disponível',
            'nome': cultoDoc['nome'] ?? 'Nome não disponível',
            'date': cultoDoc['date'] ?? Timestamp.now(),
            'horario': cultoDoc['horario'] ?? 'Horário não disponível',
            'playlist': cultoDoc['playlist'] ?? [],
            'Instrument': instrument ?? 'Instrumento não disponível',
          });
        } else {
          print("Culto não encontrado: $idCulto");
        }
      }

      return cultosData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cultos Escalados'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "12/04/24",
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xffD9D9D9),
                            fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Bom dia,',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 30),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.abc),
                                  title: Text('Editar Perfil'),
                                  onTap: () {
                                    // Ação para Opção 1

                                    Navigator.pop(context);
                                    //       _navigateToEditProfile();
                                  },
                                ),
                                /*ListTile(
                                                    leading: Icon(Icons.abc),
                                                    title: Text('Afinador'),
                                                    onTap: () {
                                                      // Ação para Opção 1
        
                                                      Navigator.pop(context);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                Afinador()),
                                                      );
                                                    },
                                                  ),*/
                                ListTile(
                                  leading: Icon(Icons.logout),
                                  title: Text('Sair'),
                                  onTap: () {
                                    // Ação para Opção 2
                                    // Usando Provider.of com listen: false para evitar reconstruções desnecessárias
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);

                                    // Acessa o authProvider e faz algo com ele
                                    if (authProvider.userId != null) {
                                      // Faça algo com authProvider.userId
                                      authProvider.logout();
                                    }
                                    /*
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => login()),
                                      (Route<dynamic> route) => false,*/
                                    //   );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.notifications,
                                      color: const Color.fromARGB(
                                          255, 248, 237, 237)),
                                  onPressed: () {
                                    // Lógica para abrir notificações
                                    // Você pode adicionar a navegação ou exibir um modal, por exemplo
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Column(
                                          children: [
                                            ListTile(
                                              leading:
                                                  Icon(Icons.notifications),
                                              title: Text('Notificações'),
                                              onTap: () {
                                                // Ação para visualizar as notificações
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50, // Largura do ícone
                            height: 50, // Altura do ícone
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(60, 0, 0,
                                      0), // Sombra alaranjada com 50% de opacidade
                                  blurRadius: 15,
                                  offset:
                                      Offset(0, 10), // Deslocamento da sombra
                                ),
                              ],
                            ),
                            child: ProfileAvatar(avatarUrl: "asd"),
                          ),
                          SizedBox(height: 20),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        Container(
                          height: 40,
                          child: Icon(Icons.notifications, color: Colors.black),
                        ),
                        if (0 > 0)
                          Positioned(
                            right: 0,
                            top: -0,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Text(
                                '2',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      // Lógica para abrir notificações
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.notifications),
                                title: Text('Notificações'),
                                onTap: () {
                                  // Ação para visualizar as notificações
                                  Navigator.pop(context);
                                },
                              ),
                              // Lista de notificações
                              Expanded(
                                child: ListView(
                                  children: [
                                    // Notificação 1
                                    ListTile(
                                      leading: Icon(Icons.event_available),
                                      title: Text('Novo evento no culto!'),
                                      subtitle: Text(
                                          'Não perca a próxima reunião de louvor.'),
                                      trailing: Text(
                                        "17:00",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        // Ação ao clicar na notificação
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Notificação 2
                                    ListTile(
                                      leading: Icon(Icons.group_add),
                                      title: Text('Novo voluntário escalado!'),
                                      subtitle: Text(
                                          'Você foi escalado para o culto de amanhã.'),
                                      trailing: Text(
                                        "17:00",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Notificação 3
                                    ListTile(
                                      leading: Icon(Icons.update),
                                      title: Text('Atualização no perfil'),
                                      subtitle: Text(
                                          'Seu perfil foi atualizado com sucesso.'),
                                      trailing: Text(
                                        "17:00",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    // Notificação 4
                                    ListTile(
                                      leading: Icon(Icons.message),
                                      title: Text('Nova mensagem recebida'),
                                      subtitle: Text(
                                          'Você tem uma mensagem nova no seu perfil.'),
                                      trailing: Text(
                                        "17:00",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "NESSA SEMANA",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 800,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getCultos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar os cultos.'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text('Nenhum culto escalado encontrado.'));
                  }

                  final cultosData = snapshot.data!;

                  // Divida os cultos em cultos da semana e outros cultos
                  DateTime today = DateTime.now();
                  DateTime startOfWeek =
                      today.subtract(Duration(days: today.weekday - 1));
                  DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

                  // Filtrar cultos da semana
                  List<Map<String, dynamic>> cultosDaSemana =
                      cultosData.where((culto) {
                    DateTime cultoDate = (culto['date'] as Timestamp).toDate();
                    return cultoDate.isAfter(startOfWeek) &&
                        cultoDate.isBefore(endOfWeek.add(Duration(days: 1)));
                  }).toList();

                  // Filtrar cultos futuros
                  List<Map<String, dynamic>> cultosFuturos =
                      cultosData.where((culto) {
                    DateTime cultoDate = (culto['date'] as Timestamp).toDate();
                    return cultoDate.isAfter(endOfWeek);
                  }).toList();

                  return ListView(
                    children: [
                      if (cultosDaSemana.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Cultos da Semana',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: cultosDaSemana.length,
                          itemBuilder: (context, index) {
                            final culto = cultosDaSemana[index];
                            final nome = culto['nome'];
                            final date = culto['date'].toDate();
                            final horario = culto['horario'];
                            final playlist = culto['playlist'];
                            final instrument = culto['Instrument'];
                            final id = culto['id'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 10.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nome,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      Text(
                                        instrument,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Data: ${date.toLocal()}'),
                                      Text('Horário: $horario'),
                                      Text(
                                        horario,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.black),
                                      ),
                                      Text(
                                          'Playlist: ${playlist.isNotEmpty ? playlist.join(', ') : 'Sem playlist'}'),
                                    ],
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            Colors.white),
                                        iconColor: WidgetStatePropertyAll(
                                            Colors.black)),
                                    icon: Icon(Icons.info_outline),
                                    onPressed: () => {
                                      // Navega para a página de detalhes do culto
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PlaylistScreen(idCulto: id),
                                        ),
                                      ),
                                    },
                                    label: Text(
                                      "Saiba Mais",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  onTap: () {
                                    // Ação ao clicar no culto
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (cultosFuturos.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Todos os Cultos',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: cultosFuturos.length,
                          itemBuilder: (context, index) {
                            final culto = cultosFuturos[index];
                            final nome = culto['nome'];
                            final date = culto['date'].toDate();
                            final horario = culto['horario'];
                            final playlist = culto['playlist'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 10.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(nome,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Data: ${date.toLocal()}'),
                                      Text('Horário: $horario'),
                                      Text(
                                          'Playlist: ${playlist.isNotEmpty ? playlist.join(', ') : 'Sem playlist'}'),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward),
                                  onTap: () {
                                    // Ação ao clicar no culto
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 0),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "NESSA SEMANA",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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

class PlaylistScreen extends StatelessWidget {
  final String idCulto;

  const PlaylistScreen({Key? key, required this.idCulto}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getPlaylist(String idCulto) async {
    try {
      // Recuperar o documento do culto
      final doc = await FirebaseFirestore.instance
          .collection('Cultos')
          .doc(idCulto)
          .get();

      if (!doc.exists) {
        return [];
      }

      // Obter a playlist como lista de mapas
      List<dynamic> playlistData = doc['playlist'] ?? [];
      List<Map<String, dynamic>> playlist = [];

      // Garantir que cada item seja um mapa válido e buscar detalhes das músicas
      for (var item in playlistData) {
        if (item is Map<String, dynamic> &&
            item.containsKey('music_document')) {
          final musicDocId = item['music_document'];

          // Buscar o documento da música
          final musicDoc = await FirebaseFirestore.instance
              .collection('music_database')
              .doc(musicDocId)
              .get();

          if (musicDoc.exists) {
            playlist.add({
              'key': item['key'] ?? 'Sem nota',
              'Music': musicDoc['Music'] ?? 'Sem nome',
              'Author': musicDoc['Author'] ?? 'Sem artista',
            });
          } else {
            playlist.add({
              'key': item['key'] ?? 'Sem nota',
              'name': 'Música não encontrada',
              'artist': '',
            });
          }
        }
      }

      return playlist;
    } catch (e) {
      print('Erro ao buscar a playlist: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getEscalados(String idCulto) async {
    try {
      // Buscar documentos em 'user_culto_instrument' com idCulto correspondente
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_culto_instrument')
          .where('idCulto', isEqualTo: idCulto)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Obter os idUser e instrumentos dos documentos encontrados
      List<Map<String, dynamic>> escaladosData = querySnapshot.docs.map((doc) {
        return {
          'idUser': doc['idUser'].toString(), // Converter idUser para String
          'instrument': doc['Instrument'] ?? 'Instrumento não informado',
        };
      }).toList();

      // Lista para armazenar os detalhes dos usuários
      List<Map<String, dynamic>> escalados = [];

      // Buscar nomes dos usuários na coleção 'musicos'
      for (var escaladoData in escaladosData) {
        final userId = escaladoData['idUser'];
        final instrument =
            escaladoData['instrument']; // Instrumento do documento

        final musicoDoc = await FirebaseFirestore.instance
            .collection('musicos')
            .where('user_id', isEqualTo: int.parse(userId))
            .get();

        if (musicoDoc.docs.isNotEmpty) {
          final musico = musicoDoc.docs.first.data();
          escalados.add({
            'nome': musico['name'] ?? 'Nome não disponível',
            'instrument':
                instrument, // Usando o instrumento da tabela 'user_culto_instrument'
          });
        } else {
          escalados.add({
            'nome': 'Músico não encontrado',
            'instrument': instrument, // Mesmo sem nome, exibir o instrumento
          });
        }
      }

      return escalados;
    } catch (e) {
      print('Erro ao buscar escalados: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Músicas da Playlist'),
      ),
      body: Column(
        children: [
          Container(
            height: 300,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getEscalados(idCulto),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar os escalados.'));
                }

                final escalados = snapshot.data ?? [];

                if (escalados.isEmpty) {
                  return Center(child: Text('Nenhum músico escalado.'));
                }

                return ListView.builder(
                  itemCount: escalados.length,
                  itemBuilder: (context, index) {
                    final musico = escalados[index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(musico['nome']),
                      subtitle: Text('Instrumento: ${musico['instrument']}'),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 300,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPlaylist(idCulto),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar a playlist'));
                }

                final playlist = snapshot.data ?? [];

                if (playlist.isEmpty) {
                  return Center(child: Text('Nenhuma música na playlist.'));
                }

                return ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final music = playlist[index];
                    return ListTile(
                      leading: Icon(Icons.music_note),
                      title: Text(music['Music']),
                      subtitle: Text(
                        'Artista: ${music['Author']}\nNota: ${music['key']}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  String avatarUrl;

  ProfileAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == "") {
      avatarUrl =
          "https://icons.veryicon.com/png/o/miscellaneous/standard/avatar-15.png";
    }
    return CircleAvatar(
      radius: 100, // Ajuste o tamanho conforme necessário
      backgroundColor: Colors.grey[200], // Cor de fundo do círculo
      backgroundImage: NetworkImage(avatarUrl),
      child: avatarUrl.isEmpty
          ? CircularProgressIndicator() // Exibe o indicador de carregamento se a URL estiver vazia
          : null,
    );
  }
}
