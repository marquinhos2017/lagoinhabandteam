import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importe o pacote intl

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart'; //For creating the SMTP Server

// Esse

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}

class MusicianSelect2 extends StatefulWidget {
  final String document_id;
  final String instrument;

  MusicianSelect2({required this.document_id, required this.instrument});

  @override
  State<MusicianSelect2> createState() => _MusicianSelect2State();
}

class _MusicianSelect2State extends State<MusicianSelect2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? date;
  String? horario;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    obterDataDocumento(widget.document_id).then((value) {
      if (mounted) {
        setState(() {
          if (value != null) {
            date = value['data'];
            horario = value['horario'];
          }
          isLoading = false; // Dados carregados
        });
      }
    });
  }

  Future<void> adicionarMusico(
      String cultoId, int userId, String instrument) async {
    try {
      DocumentReference cultoRef = _firestore.collection('Cultos').doc(cultoId);
      DocumentSnapshot cultoDoc = await cultoRef.get();

      if (!cultoDoc.exists) {
        throw Exception('Documento de culto não encontrado');
      }

      // Cria uma identificação única para cada entrada no array
      final entryId = DateTime.now()
          .millisecondsSinceEpoch
          .toString(); // Exemplo de ID único usando timestamp

      // Adiciona a nova entrada ao array de músicos
      await cultoRef.update({
        'musicos': FieldValue.arrayUnion([
          {
            'id': entryId, // Identificador único
            'user_id': userId,
            'instrument':
                instrument // Se você quer armazenar o instrumento aqui também
          }
        ])
      }).then((_) {
        print('Músico adicionado com sucesso ao culto.');
      }).catchError((error) {
        print('Erro ao adicionar músico ao culto: $error');
        throw Exception('Erro ao adicionar músico ao culto.');
      });

      CollectionReference userCultoInstrument =
          _firestore.collection('user_culto_instrument');
      await userCultoInstrument.add({
        'idCulto': cultoId,
        'idUser': userId,
        'Instrument': instrument,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Músico adicionado!'),
            backgroundColor: Color(0xff4465D9),
          ),
        );
      }

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
        ..subject = 'Você acabou de ser escalado' //subject of the email
        ..html =
            '<!doctype html> <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"> <head> <title></title> <!--[if !mso]><!--> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <!--<![endif]--> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1"> <style type="text/css"> #outlook a { padding:0; } body { margin:0;padding:0;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%; } table, td { border-collapse:collapse;mso-table-lspace:0pt;mso-table-rspace:0pt; } img { border:0;height:auto;line-height:100%; outline:none;text-decoration:none;-ms-interpolation-mode:bicubic; } p { display:block;margin:13px 0; } </style> <!--[if mso]> <noscript> <xml> <o:OfficeDocumentSettings> <o:AllowPNG/> <o:PixelsPerInch>96</o:PixelsPerInch> </o:OfficeDocumentSettings> </xml> </noscript> <![endif]--> <!--[if lte mso 11]> <style type="text/css"> .mj-outlook-group-fix { width:100% !important; } </style> <![endif]--> <!--[if !mso]><!--> <link href="https://fonts.googleapis.com/css?family=Ubuntu:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Cabin:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Bitter:400,700" rel="stylesheet" type="text/css"> <style type="text/css"> @import url(https://fonts.googleapis.com/css?family=Ubuntu:400,700); @import url(https://fonts.googleapis.com/css?family=Cabin:400,700); @import url(https://fonts.googleapis.com/css?family=Bitter:400,700); </style> <!--<![endif]--> <style type="text/css"> @media only screen and (min-width:480px) { .mj-column-per-100 { width:100% !important; max-width: 100%; } } </style> <style media="screen and (min-width:480px)"> .moz-text-html .mj-column-per-100 { width:100% !important; max-width: 100%; } </style> <style type="text/css"> </style> <style type="text/css"> .hide_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_on_mobile { display: block !important;} } .hide_section_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_section_on_mobile { display: table !important; } div.hide_section_on_mobile { display: block !important; } } .hide_on_desktop { display: block !important;} @media only screen and (min-width: 480px) { .hide_on_desktop { display: none !important;} } .hide_section_on_desktop { display: table !important; width: 100%; } @media only screen and (min-width: 480px) { .hide_section_on_desktop { display: none !important;} } p, h1, h2, h3 { margin: 0px; } ul, li, ol { font-size: 11px; font-family: Ubuntu, Helvetica, Arial; } a { text-decoration: none; color: inherit; } @media only screen and (max-width:480px) { .mj-column-per-100 { width:100%!important; max-width:100%!important; }.mj-column-per-100 > .mj-column-per-100 { width:100%!important; max-width:100%!important; } } </style> </head> <body style="word-spacing:normal;background-color:#FFFFFF;"> <div style="background-color:#FFFFFF;"> <!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="" role="presentation" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--> <div style="margin:0px auto;max-width:600px;"> <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"> <tbody> <tr> <td style="direction:ltr;font-size:0px;padding:9px 0px 9px 0px;text-align:center;"> <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--> <div class="mj-column-per-100 mj-outlook-group-fix" style="font-size:0px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"> <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"> <tbody> <tr> <td align="left" style="font-size:0px;padding:15px 15px 15px 15px;word-break:break-word;"> <div style="font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:13px;line-height:1.5;text-align:left;color:#000000;"><p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;&nbsp;<br>&nbsp;<br>&nbsp;<br><span style="font-size: 21px;">Voc&ecirc; acabou de ser escalado</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br><span style="font-size: 12px;"><strong>Voc&ecirc; foi escalado(a) para o Culto que ocorrer&aacute; no dia $date $horario para a fun&ccedil;&atilde;o $instrument.</strong></span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><span style="font-family: Bitter, Georgia, serif;">Para que voc&ecirc; possa visualizar suas escalas, baixe o aplicativo de acordo com seu smartphone.</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><em>&copy; 2024&nbsp; Lake Music Todos os Direitos Reservados</em></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;</p></div> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </div> <div style="color: #ccc; font-size: 12px; width: 600px; margin: 15px auto; text-align: center;"><a href="https://wordtohtml.net/email/designer">Created with WordToHTML.net Email Designer</a></div> </body> </html>'
        ..text =
            'Olá, tudo bem ? Você acabou de ser escalado para o Culto dia: $date, Horàrio: $horario no instrumento: $instrument.\n  This is line 2 of the text part.<!doctype html> <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"> <head> <title></title> <!--[if !mso]><!--> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <!--<![endif]--> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"> <meta name="viewport" content="width=device-width, initial-scale=1"> <style type="text/css"> #outlook a { padding:0; } body { margin:0;padding:0;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%; } table, td { border-collapse:collapse;mso-table-lspace:0pt;mso-table-rspace:0pt; } img { border:0;height:auto;line-height:100%; outline:none;text-decoration:none;-ms-interpolation-mode:bicubic; } p { display:block;margin:13px 0; } </style> <!--[if mso]> <noscript> <xml> <o:OfficeDocumentSettings> <o:AllowPNG/> <o:PixelsPerInch>96</o:PixelsPerInch> </o:OfficeDocumentSettings> </xml> </noscript> <![endif]--> <!--[if lte mso 11]> <style type="text/css"> .mj-outlook-group-fix { width:100% !important; } </style> <![endif]--> <!--[if !mso]><!--> <link href="https://fonts.googleapis.com/css?family=Ubuntu:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Cabin:400,700" rel="stylesheet" type="text/css"> <link href="https://fonts.googleapis.com/css?family=Bitter:400,700" rel="stylesheet" type="text/css"> <style type="text/css"> @import url(https://fonts.googleapis.com/css?family=Ubuntu:400,700); @import url(https://fonts.googleapis.com/css?family=Cabin:400,700); @import url(https://fonts.googleapis.com/css?family=Bitter:400,700); </style> <!--<![endif]--> <style type="text/css"> @media only screen and (min-width:480px) { .mj-column-per-100 { width:100% !important; max-width: 100%; } } </style> <style media="screen and (min-width:480px)"> .moz-text-html .mj-column-per-100 { width:100% !important; max-width: 100%; } </style> <style type="text/css"> </style> <style type="text/css"> .hide_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_on_mobile { display: block !important;} } .hide_section_on_mobile { display: none !important;} @media only screen and (min-width: 480px) { .hide_section_on_mobile { display: table !important; } div.hide_section_on_mobile { display: block !important; } } .hide_on_desktop { display: block !important;} @media only screen and (min-width: 480px) { .hide_on_desktop { display: none !important;} } .hide_section_on_desktop { display: table !important; width: 100%; } @media only screen and (min-width: 480px) { .hide_section_on_desktop { display: none !important;} } p, h1, h2, h3 { margin: 0px; } ul, li, ol { font-size: 11px; font-family: Ubuntu, Helvetica, Arial; } a { text-decoration: none; color: inherit; } @media only screen and (max-width:480px) { .mj-column-per-100 { width:100%!important; max-width:100%!important; }.mj-column-per-100 > .mj-column-per-100 { width:100%!important; max-width:100%!important; } } </style> </head> <body style="word-spacing:normal;background-color:#FFFFFF;"> <div style="background-color:#FFFFFF;"> <!--[if mso | IE]><table align="center" border="0" cellpadding="0" cellspacing="0" class="" role="presentation" style="width:600px;" width="600" ><tr><td style="line-height:0px;font-size:0px;mso-line-height-rule:exactly;"><![endif]--> <div style="margin:0px auto;max-width:600px;"> <table align="center" border="0" cellpadding="0" cellspacing="0" role="presentation" style="width:100%;"> <tbody> <tr> <td style="direction:ltr;font-size:0px;padding:9px 0px 9px 0px;text-align:center;"> <!--[if mso | IE]><table role="presentation" border="0" cellpadding="0" cellspacing="0"><tr><td class="" style="vertical-align:top;width:600px;" ><![endif]--> <div class="mj-column-per-100 mj-outlook-group-fix" style="font-size:0px;text-align:left;direction:ltr;display:inline-block;vertical-align:top;width:100%;"> <table border="0" cellpadding="0" cellspacing="0" role="presentation" style="vertical-align:top;" width="100%"> <tbody> <tr> <td align="left" style="font-size:0px;padding:15px 15px 15px 15px;word-break:break-word;"> <div style="font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:13px;line-height:1.5;text-align:left;color:#000000;"><p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;&nbsp;<br>&nbsp;<br>&nbsp;<br><span style="font-size: 21px;">Voc&ecirc; acabou de ser escalado</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br><span style="font-size: 12px;"><strong>Voc&ecirc; foi escalado(a) para o evento Culto Celebra&ccedil;&atilde;o que ocorrer&aacute; no dia 5 de Janeiro de 2025 19h30 para a fun&ccedil;&atilde;o Tecladista.</strong></span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><span style="font-family: Bitter, Georgia, serif;">Para que voc&ecirc; possa visualizar suas escalas, baixe o aplicativo de acordo com seu smartphone.</span></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><em>&copy; 2024&nbsp; Lake Music Todos os Direitos Reservados</em></p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;">&nbsp;</p> <p style="font-family: Ubuntu, sans-serif; font-size: 11px; text-align: center;"><br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;</p></div> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </td> </tr> </tbody> </table> </div> <!--[if mso | IE]></td></tr></table><![endif]--> </div> <div style="color: #ccc; font-size: 12px; width: 600px; margin: 15px auto; text-align: center;"><a href="https://wordtohtml.net/email/designer">Created with WordToHTML.net Email Designer</a></div> </body> </html>'; //body of the email

      try {
        final sendReport = await send(message, smtpServer);
        print('Message sent: ' +
            sendReport.toString()); //print if the email is sent
      } on MailerException catch (e) {
        print('Message not sent. \n' +
            e.toString()); //print if the email is not sent
        // e.toString() will show why the email is not sending
      }

      Navigator.pop(context, true); // Indica que algo mudou
    } catch (e) {
      print('Erro ao adicionar músico: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar músico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> verificaDisponibilidade(
      String date, String horario, String musicoId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Form_Voluntario_Culto')
          .where('musico_id', isEqualTo: musicoId)
          .get();

      for (var doc in querySnapshot.docs) {
        var disponibilidadeCultoId = doc['disponibilidade_culto'];
        DocumentSnapshot formMesCultosDoc = await _firestore
            .collection('Form_Mes_Cultos')
            .doc(disponibilidadeCultoId)
            .get();

        if (formMesCultosDoc.exists) {
          var dataCulto = DateFormat('dd-MM-yyyy')
              .format(formMesCultosDoc['data'].toDate());
          var horarioCulto = formMesCultosDoc['horario'];

          if (dataCulto == date && horarioCulto == horario) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  Future<Map<String, String>?> obterDataDocumento(String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('Cultos').doc(documentId).get();

      if (documentSnapshot.exists) {
        var data =
            DateFormat('dd-MM-yyyy').format(documentSnapshot['date'].toDate());
        var horario = documentSnapshot['horario'];
        return {'data': data, 'horario': horario};
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao buscar documento: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Exibe o carregamento até que os dados estejam prontos
          : Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Container(
                      margin: EdgeInsets.only(top: 60, bottom: 40),
                      child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Função: " + widget.instrument,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Escolha uma pessoa",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      margin: EdgeInsets.only(top: 2),
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
                            Container(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Cultos')
                                    .doc(widget.document_id)
                                    .snapshots(),
                                builder: (context, cultoSnapshot) {
                                  if (cultoSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (!cultoSnapshot.hasData ||
                                      !cultoSnapshot.data!.exists) {
                                    return Center(
                                      child: Text(
                                        'Dados do culto não encontrados',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }

                                  var cultoData = cultoSnapshot.data!.data()
                                      as Map<String, dynamic>;
                                  var musicosAtuais =
                                      List<Map<String, dynamic>>.from(
                                          cultoData['musicos'] ?? []);

                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('musicos')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.docs.isEmpty) {
                                        return Center(
                                          child: Text(
                                            'Nenhum Músico cadastrado',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        );
                                      }

                                      var musicosDisponiveis = snapshot
                                          .data!.docs
                                          .where((musicoDoc) {
                                        var musicoData = musicoDoc.data()
                                            as Map<String, dynamic>;
                                        var musicoId = musicoData['user_id'];

                                        // Verifica se o músico é "md" ou está na lista de IDs específicos
                                        var isMd = musicoData['role'] == 'md';
                                        var alwaysIncludedIds = [
                                          100,
                                          131,
                                          133,
                                          187
                                        ];
                                        var isAlwaysIncluded = alwaysIncludedIds
                                            .contains(musicoId);

                                        return isMd ||
                                            isAlwaysIncluded ||
                                            !musicosAtuais.any((musicoAtual) =>
                                                musicoAtual['user_id'] ==
                                                musicoId);
                                      }).toList();

                                      return ListView.builder(
                                        physics: ClampingScrollPhysics(),
                                        itemCount: musicosDisponiveis.length,
                                        padding: EdgeInsets.zero,
                                        itemBuilder: (context, index) {
                                          var data = musicosDisponiveis[index];
                                          var musicos = data.data()
                                              as Map<String, dynamic>;
                                          var musicoId = musicos['user_id'];
                                          var nomeMusico = musicos['name'];
                                          var isMd = musicos['role'] == 'md';

                                          return FutureBuilder<bool>(
                                            future: (date != null &&
                                                    horario != null)
                                                ? verificaDisponibilidade(
                                                    date!,
                                                    horario!,
                                                    musicoId.toString())
                                                : Future.value(
                                                    false), // or handle the null case appropriately
                                            builder: (context,
                                                disponibilidadeSnapshot) {
                                              if (disponibilidadeSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return Container(); // Não exibe nada enquanto verifica disponibilidade
                                              }

                                              if (disponibilidadeSnapshot
                                                  .hasError) {
                                                return ListTile(
                                                  title: Text(
                                                    nomeMusico,
                                                  ),
                                                  subtitle: Text(
                                                      'Erro ao verificar disponibilidade.'),
                                                );
                                              }

                                              bool disponivel =
                                                  disponibilidadeSnapshot
                                                          .data ??
                                                      false;

                                              return Container(
                                                padding: EdgeInsets.all(8),
                                                child: GestureDetector(
                                                  onTap: () async {
                                                    if (!mounted) return;

                                                    String mensagem;
                                                    if (disponivel || isMd) {
                                                      mensagem =
                                                          "Quer convidar $nomeMusico para ser o ${widget.instrument}?";
                                                    } else {
                                                      mensagem =
                                                          "$nomeMusico está indisponível. Quer convidar mesmo assim?";
                                                    }

                                                    bool? resposta =
                                                        await showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          backgroundColor: Colors
                                                              .white, // Fundo branco
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(20.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                // Ícone principal
                                                                Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: disponivel
                                                                        ? Colors.blue[
                                                                            50]
                                                                        : Colors
                                                                            .red[50], // Fundo azul claro ou vermelho claro
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          16),
                                                                  child: Icon(
                                                                    disponivel
                                                                        ? Icons
                                                                            .check_circle
                                                                        : Icons
                                                                            .error,
                                                                    size: 48,
                                                                    color: disponivel
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 16),
                                                                // Título
                                                                Text(
                                                                  mensagem,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .black, // Texto preto
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 16),
                                                                // Opções
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceEvenly,
                                                                  children: [
                                                                    // Botão de Cancelar
                                                                    ElevatedButton
                                                                        .icon(
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          false),
                                                                      icon: Icon(
                                                                          Icons
                                                                              .cancel,
                                                                          color:
                                                                              Colors.black),
                                                                      label: Text(
                                                                          'Cancelar'),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.white, // Fundo branco
                                                                        foregroundColor:
                                                                            Colors.black, // Texto preto
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                          side:
                                                                              BorderSide(color: Colors.black), // Borda preta
                                                                        ),
                                                                        padding: EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                16,
                                                                            vertical:
                                                                                10),
                                                                      ),
                                                                    ),
                                                                    // Botão de OK/Adicionar
                                                                    ElevatedButton
                                                                        .icon(
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          true),
                                                                      icon: Icon(
                                                                          Icons
                                                                              .add,
                                                                          color:
                                                                              Colors.white),
                                                                      label: Text(disponivel
                                                                          ? 'OK'
                                                                          : 'Adicionar'),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.blue, // Fundo azul
                                                                        foregroundColor:
                                                                            Colors.white, // Texto branco
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(12),
                                                                        ),
                                                                        padding: EdgeInsets.symmetric(
                                                                            horizontal:
                                                                                16,
                                                                            vertical:
                                                                                10),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );

                                                    if (resposta == true) {
                                                      if (!mounted) return;

                                                      await adicionarMusico(
                                                          widget.document_id,
                                                          musicoId,
                                                          widget.instrument);

                                                      // Aguarda o fechamento do SnackBar
                                                      await Future.delayed(
                                                          Duration(seconds: 1));

                                                      if (!mounted) return;

                                                      Navigator.pop(context,
                                                          true); // Retorna o resultado para a página anterior
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            Color(0xffebebeb),
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    24)),
                                                        border: Border.all(
                                                            width: 1,
                                                            color: Color(
                                                                0xffebebeb))),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            nomeMusico
                                                                .toString()
                                                                .toCapitalized(),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          Icon(
                                                            disponivel
                                                                ? Icons
                                                                    .confirmation_num
                                                                : Icons.error,
                                                            color: disponivel
                                                                ? Colors.green
                                                                : Colors.black,
                                                          ),
                                                        ],
                                                      ),
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
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
