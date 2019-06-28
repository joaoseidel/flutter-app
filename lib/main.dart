import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final ThemeData androidTheme = new ThemeData(
  primarySwatch: Colors.blue,
  accentColor: Colors.green,
);

String defaultUserName = "Padrão";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: "Bate-papo", theme: androidTheme, home: new LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameFilter = new TextEditingController();
  String _username = "";

  _LoginPageState() {
    _usernameFilter.addListener(_usernameListen);
  }

  void _usernameListen() {
    if (_usernameFilter.text.isEmpty) {
      _username = "";
    } else {
      _username = _usernameFilter.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: _buildBar(context),
      body: new Container(
        padding: EdgeInsets.all(16.0),
        child: new Column(
          children: <Widget>[
            _buildTextFields(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      title: new Text("Identifique-se"),
      centerTitle: true,
    );
  }

  Widget _buildTextFields() {
    return new Container(
      child: new Column(
        children: <Widget>[
          new Container(
            child: new TextField(
              controller: _usernameFilter,
              decoration: new InputDecoration(labelText: 'Digite seu nome'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return new Container(
      margin: new EdgeInsets.all(12),
      child: new Column(
        children: <Widget>[
          new RaisedButton(
            child: new Text('Login'),
            onPressed: _loginPressed,
          )
        ],
      ),
    );
  }

  void _loginPressed() {
    defaultUserName = _username;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Chat()),
    );
  }
}

// CHAT

class Chat extends StatefulWidget {
  @override
  State createState() => new ChatWindow();
}

class ChatWindow extends State<Chat> with TickerProviderStateMixin {
  final List<Msg> _messages = <Msg>[];
  final TextEditingController _textController = new TextEditingController();
  bool _isWriting = false;

  @override
  void initState() {
    Firestore.instance.collection('messages').getDocuments().then((myDocuments) {
      myDocuments.documents.forEach((doc) => _submitMsg(doc["name"], doc["message"]));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Bate-papo"),
          elevation: 6.0,
        ),
        body: new Column(children: <Widget>[
          new Flexible(
              child: new ListView.builder(
                itemBuilder: (_, int index) => _messages[index],
                itemCount: _messages.length,
                reverse: true,
                padding: new EdgeInsets.all(6.0),
              )),
          new Divider(height: 1.0),
          new Container(
            child: _buildComposer(),
            decoration: new BoxDecoration(color: Theme.of(context).cardColor),
          )
        ]));
  }

  Widget _buildComposer() {
    return new IconTheme(
        data: new IconThemeData(color: Theme.of(context).accentColor),
        child: new Container(
            margin: const EdgeInsets.symmetric(horizontal: 9),
            child: new Row(
              children: <Widget>[
                new Flexible(
                    child: new TextField(
                      controller: _textController,
                      onChanged: (String text) {
                        setState(() {
                          _isWriting = text.length > 0;
                        });
                      },
                      onSubmitted: (msg) {
                        _submitMsg(defaultUserName, msg);
                        _storeMessage(msg);
                      },
                      decoration: new InputDecoration.collapsed(
                          hintText: "Digite uma mensagem"),
                    )),
                new Container(
                    margin: new EdgeInsets.symmetric(horizontal: 3),
                    child: new IconButton(
                      icon: new Icon(Icons.message),
                      onPressed: _isWriting
                          ? () {
                        String msg = _textController.text;
                        _submitMsg(defaultUserName, msg);
                        _storeMessage(msg);
                      }
                          : null,
                    ))
              ],
            )));
  }

  void _submitMsg(String username, String text) {
    _textController.clear();

    setState(() {
      _isWriting = false;
    });

    Msg msg = new Msg(
      username: username,
      text: text,
      animationController: new AnimationController(
          vsync: this, duration: new Duration(milliseconds: 800)),
    );

    setState(() {
      _messages.insert(0, msg);
    });

    msg.animationController.forward();
  }

  void _storeMessage(String text) {
    Firestore.instance
        .collection('messages')
        .document()
        .setData({'name': defaultUserName, 'message': text});
  }

  @override
  void dispose() {
    for (Msg msg in _messages) {
      msg.animationController.dispose();
    }
    super.dispose();
  }
}

class Msg extends StatelessWidget {
  Msg({this.username, this.text, this.animationController});

  final String username;
  final String text;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animationController, curve: Curves.bounceOut),
      axisAlignment: 0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 18),
              child: new CircleAvatar(child: new Text(username)),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(username,
                      style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 6),
                    child: new Text(text),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}