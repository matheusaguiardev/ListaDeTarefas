import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var _objetivos = List<dynamic>();
  var _ultimoRemovido = Map();
  var _ultimoRemovidoIndex;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        if (data.runtimeType == List<dynamic>()) {
          _objetivos = data;
        }
      });
    });
  }

  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de objetivos"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding:
                EdgeInsets.only(left: 17.0, top: 1.0, right: 7.0, bottom: 1.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            labelText: "Novo objetivo",
                            labelStyle: TextStyle(color: Colors.blueAccent)))),
                IconButton(
                    onPressed: () {
                      addObjetivo();
                    },
                    icon: Icon(
                      Icons.note_add,
                      color: Colors.blue,
                    ))
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: _criarListView(), onRefresh: _refresh))
        ],
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _objetivos.sort((atual, prox) {
        if (atual["concluido"] && !prox["concluido"])
          return 1;
        else if (!atual["concluido"] && prox["concluido"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  Widget _criarListView() {
    return ListView.builder(
        padding: EdgeInsets.only(top: 10.0),
        itemCount: _objetivos.length,
        itemBuilder: (context, index) {
          return _getItemDismissible(context, _objetivos[index]["titulo"],
              _objetivos[index]["concluido"], index);
        });
  }

  void addObjetivo() {
    String obj = controller.text;
    if (obj.isNotEmpty) {
      setState(() {
        var novoObjetivo = Map();
        novoObjetivo["titulo"] = obj;
        novoObjetivo["concluido"] = false;
        _objetivos.add(novoObjetivo);
        controller.text = "";
      });
      _saveData();
    }
  }

  Widget _getItemDismissible(
      BuildContext ctx, String objetivo, bool concluido, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      direction: DismissDirection.startToEnd,
      child: _getItemList(objetivo, concluido, index),
      onDismissed: (direction) {
        setState(() {
          _ultimoRemovido = Map.from(_objetivos[index]);
          _ultimoRemovidoIndex = index;
          _objetivos.removeAt(index);
          _saveData();

          final snack = SnackBar(
            duration: Duration(seconds: 3),
            content: Text("Objetivo ${_ultimoRemovido["titulo"]} removido"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _objetivos.insert(_ultimoRemovidoIndex, _ultimoRemovido);
                  });
                }),
          );
          Scaffold.of(ctx).removeCurrentSnackBar();
          Scaffold.of(ctx).showSnackBar(snack);
        });
      },
      background: Container(
          color: Colors.red,
          child: Align(
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              alignment: Alignment(-0.9, 0))),
    );
  }

  Widget _getItemList(String objetivo, bool concluido, int index) {
    return CheckboxListTile(
      title: Text(objetivo),
      value: concluido,
      onChanged: (value) {
        setState(() {
          _objetivos[index]["concluido"] = value;
        });
        _saveData();
      },
      secondary: CircleAvatar(
        child: concluido
            ? Icon(Icons.check, color: Colors.green, size: 30.0)
            : Icon(Icons.warning, color: Colors.amber, size: 30.0),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_objetivos);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<dynamic> _readData() async {
    try {
      final file = await _getFile();
      return json.decode(await file.readAsString(encoding: utf8));
    } catch (e) {
      return Map();
    }
  }
}
