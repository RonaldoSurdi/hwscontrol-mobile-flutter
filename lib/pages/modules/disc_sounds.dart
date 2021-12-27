import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hwscontrol/core/components/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:hwscontrol/core/models/sound_model.dart';

class DiscSounds extends StatefulWidget {
  final String itemId;
  final String itemTitle;
  const DiscSounds({
    Key? key,
    required this.itemId,
    required this.itemTitle,
  }) : super(key: key);

  @override
  _DiscSoundsState createState() => _DiscSoundsState();
}

class _DiscSoundsState extends State<DiscSounds> {
  final TextEditingController _trackController = MaskedTextController(
    mask: '00',
    text: '',
  );
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _movieController = TextEditingController();
  final TextEditingController _lyricController = TextEditingController();
  final TextEditingController _cipherController = TextEditingController();

  final List<SoundModel> _widgetList = [];

  // seleciona a música do computador
  Future _selectSound(idSound) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      EasyLoading.showInfo(
        'enviando arquivo...',
        maskType: EasyLoadingMaskType.custom,
      );

      Uint8List? fileBytes = result.files.first.bytes;
      String? fileName = result.files.first.name;
      String? fileExt = result.files.first.extension;
      String? filePut = '${idSound.toString().padLeft(2, '0')}$fileExt';

      // Upload file
      await firebase_storage.FirebaseStorage.instance
          .ref('discs/${widget.itemId}/$filePut')
          .putData(fileBytes!);

      setState(() {
        Timer(const Duration(milliseconds: 1500), () {
          _getData();
        });
      });
    }
  }

  Future<void> _addNewSound(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (builder, setState) => AlertDialog(
            title: const Text('Adicionar música'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _trackController,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  decoration: const InputDecoration(
                    hintText: "Track",
                  ),
                ),
                TextField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: "Título",
                  ),
                ),
                TextField(
                  controller: _movieController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: "Url Youtube (opcional)",
                  ),
                ),
                TextField(
                  controller: _lyricController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: "Url Letra (opcional)",
                  ),
                ),
                TextField(
                  controller: _cipherController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: "Url Cifra (opcional)",
                  ),
                ),
                TextField(
                  controller: _infoController,
                  maxLength: 16,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(hintText: "Informações (opcional)"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontFamily: 'WorkSansMedium',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_trackController.text.isEmpty) {
                    CustomSnackBar(
                        context, const Text('Digite o número do álbum.'),
                        backgroundColor: Colors.red);
                  } else if (_titleController.text.isEmpty) {
                    CustomSnackBar(
                        context, const Text('Digite o título do álbum.'),
                        backgroundColor: Colors.red);
                  } else {
                    _saveData(
                        num.parse(_trackController.text),
                        _titleController.text,
                        _movieController.text,
                        _lyricController.text,
                        _cipherController.text,
                        _infoController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16.0,
                    fontFamily: 'WorkSansMedium',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // faz o envio da imagem para o storage
  Future _saveData(
    num _trackValue,
    String _titleValue,
    String _movieValue,
    String _lyricValue,
    String _cipherValue,
    String _infoValue,
  ) async {
    EasyLoading.showInfo(
      'processando...',
      maskType: EasyLoadingMaskType.custom,
    );

    SoundModel soundModel = SoundModel(
      track: _trackValue,
      title: _titleValue,
      info: _infoValue,
      movie: _movieValue,
      lyric: _lyricValue,
      cipher: _cipherValue,
    );

    FirebaseFirestore db = FirebaseFirestore.instance;
    db
        .collection("discs")
        .doc(widget.itemId)
        .collection("sounds")
        .doc(_trackValue.toString().padLeft(2, '0'))
        .set(soundModel.toMap());

    setState(() {
      Timer(const Duration(milliseconds: 1500), () {
        _getData();
      });
    });

    return Future.value(true);
  }

  Future _removeData(itemId) async {
    EasyLoading.showSuccess(
      'processando...',
      maskType: EasyLoadingMaskType.custom,
    );

    await FirebaseFirestore.instance
        .collection("discs")
        .doc(widget.itemId)
        .collection("sounds")
        .doc(itemId.toString().padLeft(2, '0'))
        .delete();

    await firebase_storage.FirebaseStorage.instance
        .ref("discs/${widget.itemId}")
        .child("${itemId.toString().padLeft(2, '0')}.mp3")
        .delete();

    setState(() {
      Timer(const Duration(milliseconds: 500), () {
        _getData();
      });
    });
  }

  Future _getData() async {
    _widgetList.clear();
    /*FirebaseFirestore db = FirebaseFirestore.instance;
    var data = await db
        .collection("discs")
        .doc(widget.itemId)
        .collection("sounds")
        .orderBy('track')
        .get();
    var response = data.docs;
    setState(() {
      if (response.isNotEmpty) {
        _trackController.text = (response.length + 1).toString();
        for (int i = 0; i < response.length; i++) {
          SoundModel soundModel = SoundModel(
            track: response[i]["track"],
            title: response[i]["title"],
            info: response[i]["info"].toString().replaceAll('null', ''),
            movie: response[i]["movie"].toString().replaceAll('null', ''),
            lyric: response[i]["lyric"].toString().replaceAll('null', ''),
            cipher: response[i]["cipher"].toString().replaceAll('null', ''),
            audio: response[i]["audio"].toString().replaceAll('null', ''),
          );
          _widgetList.add(soundModel);
        }
      } else {
        _trackController.text = '1';
      }
      _titleController.text = '';
      _movieController.text = '';
      _lyricController.text = '';
      _cipherController.text = '';
      _infoController.text = '';
      if (EasyLoading.isShow) {
        Timer(const Duration(milliseconds: 2000), () {
          EasyLoading.dismiss(animation: true);
        });
      }
    });*/
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final double itemWidth = size.width;
    const double itemHeight = 100;

    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          '${widget.itemId} - ${widget.itemTitle}',
        ),
        backgroundColor: Colors.black38,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 40,
            color: Colors.amber,
            splashColor: Colors.yellow,
            tooltip: 'Adicionar música',
            onPressed: () {
              _addNewSound(context);
            },
          ),
        ],
      ),
      body: /*_widgetList.isNotEmpty
          ? GridView.count(
              crossAxisCount: 1,
              childAspectRatio: (itemWidth / itemHeight),
              controller: ScrollController(keepScrollOffset: false),
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: _widgetList.map((SoundModel value) {
                return Container(
                  color: Colors.black26,
                  margin: const EdgeInsets.all(1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                        child: Text(
                          value.track.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontFamily: 'WorkSansLigth',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                          child: Text(
                            '${value.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontFamily: 'WorkSansLigth',
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                        child: SizedBox(
                          height: 40.0,
                          width: 40.0,
                          child: FloatingActionButton(
                            mini: false,
                            tooltip: 'Adicionar música',
                            child: const Icon(Icons.add_a_photo),
                            backgroundColor: Colors.green,
                            onPressed: () => _selectSound(value.track),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 5, 15, 5),
                        child: SizedBox(
                          height: 25.0,
                          width: 25.0,
                          child: FloatingActionButton(
                            mini: true,
                            tooltip: 'Remover música',
                            child: const Icon(Icons.close),
                            backgroundColor: Colors.red,
                            onPressed: () => showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: const Text('Remover música'),
                                content: Text(
                                    'Tem certeza que deseja remover a música\n${value.track.toString().padLeft(2, '0')} - ${value.title}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16.0,
                                        fontFamily: 'WorkSansMedium',
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _removeData(value.track);
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Excluir',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16.0,
                                        fontFamily: 'WorkSansMedium',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList())
          : */
          Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(5, 20, 20, 5),
            alignment: Alignment.center,
            child: Text(
              EasyLoading.isShow
                  ? 'sincronizando...'
                  : 'Nenhum registro cadastrado.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontFamily: 'WorkSansLigth',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
