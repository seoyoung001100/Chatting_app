import 'package:chatting_app/chatting/chat/message.dart';
import 'package:chatting_app/chatting/chat/new_message.dart';
import 'package:chatting_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _authentication = FirebaseAuth.instance;
  User? loggedUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser = user;
        print(loggedUser!.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      appBar: AppBar(
        backgroundColor: Palette.appBarBackgroundColor,
        title: const Text(
          "Chat Scrren",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        // flexibleSpace: Container(
        //   decoration: const BoxDecoration(
        //     image: DecorationImage(
        //       image: AssetImage("assets/imges/IMG_01.jpeg"),
        //       // 상단 여백을 없애는 애 : fit
        //       fit: BoxFit.cover,
        //     ),
        //   ),
        // ),
        actions: [
          IconButton(
            onPressed: () {
              _authentication.signOut();
              print("SignOut!");
            },
            icon: const Icon(
              Icons.exit_to_app_rounded,
              size: 27,
              color: Colors.white,
            ),
          )
        ],
      ),
      // 스트림빌더 위젯은 파이어베이스에서 제공하는 것이 아닌 플러터에서 제공하는 위젯이다
      body: Container(
        child: const Column(
          children: [
            Expanded(
              child: Messages(),
            ),
            NewMessage(),
          ],
        ),
      ),
    );
  }
}
