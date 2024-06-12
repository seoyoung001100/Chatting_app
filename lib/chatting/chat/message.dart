import 'package:chatting_app/chatting/chat/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chat")
          .orderBy(
            "time",
            descending: true,
          ) // timestamp대로 정렬시켜준다
          .snapshots(),
      builder: (context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final chatDocs = snapshot.data!.docs;

        // for (var doc in chatDocs) {
        //   print(doc.data()); // 전체 문서 데이터를 출력합니다.
        // }
        return ListView.builder(
          reverse: true, // 메세지가 밑에서부터 쌓아올라간다.
          // 아이템의 개수는 저장되는 다큐먼트의 개수에 의해서 매번 달라질 것이기 때문에 반드시 length값을 가져와야 한다
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            return ChatBubbles(
                chatDocs[index]['text'],
                chatDocs[index]['userID'].toString() == user!.uid,
                chatDocs[index]['userName']);
          },
        );
      },
    );
  }
}
