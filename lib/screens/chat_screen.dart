import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText = '';

  void getCurrentUser() async {
    try {
      final user = User;
      if (user != null) {
        loggedUser = _auth.currentUser;
        print(loggedUser?.email);
      }
    } catch (e) {
      print(e);
    }
  }

/*  void getMessages() async {
    QuerySnapshot querySnapshot = await _firestore.collection('messages').get();
    final messages = querySnapshot.docs.map((doc) => doc.data()).toList();
    for (var message in messages) {
      print(message);
    }
  }*/

  void messagesStream() async {
    var snapshotList = await _firestore.collection('messages').snapshots();
    await for (var snapshot in snapshotList) {
      for (var messages in snapshot.docChanges) {
        print(messages.doc.data());
      }
    }
  }

  @override
  void initState() {
    getCurrentUser();
    messagesStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                //_auth.signOut();
                //Navigator.pop(context);
                messagesStream();
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //Implement send functionality.
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedUser?.email,
                      });
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data?.docs.reversed;

        for (var message in messages!) {
          final messageText = message.get('text');
          final messageSender = message.get('sender') as String;

          final currentUser = loggedUser?.email;
          bool isMe;
          if (currentUser == messageSender) {
            isMe = true;
          } else {
            isMe = false;
          }

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: isMe,
          );
          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {Key? key, required this.sender, required this.text, required this.isMe})
      : super(key: key);

  final String sender;
  final String text;
  final bool isMe;

  Color bubbleColor() {
    if (isMe == true) {
      return Colors.white;
    } else {
      return Colors.lightBlueAccent;
    }
  }

  Color textColor() {
    if (isMe == true) {
      return Colors.black54;
    } else {
      return Colors.white;
    }
  }

  BorderRadiusGeometry typeOfBorder() {
    if (isMe) {
      return const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0));
    } else {
      return const BorderRadius.only(
          topRight: Radius.circular(30.0),
          bottomLeft: Radius.circular(30.0),
          bottomRight: Radius.circular(30.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12.0,
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: typeOfBorder(),
            color: bubbleColor(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18.0,
                  color: textColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
