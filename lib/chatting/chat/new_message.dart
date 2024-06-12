import 'package:chatting_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController(); // 텍스트 입력시 텍스트 필드에 남는 텍스트 삭제
  var _userEnterMessage = "";
  void _sendMessage() async {
    // 메세지를 보내기 위한 IconButton의 onPressed 기능
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('user')
        .doc(user!.uid)
        .get();
    FirebaseFirestore.instance.collection('chat').add({
      'text': _userEnterMessage,
      'time': Timestamp.now(),
      'userID': user.uid,
      'userName': userData.data()!['userName'],
    });
    setState(() {
      _userEnterMessage = "";
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLines: null,
              cursorColor: Palette.activeColor,
              controller: _controller, // 텍스트 입력시 텍스트 필드에 남는 텍스트 삭제
              decoration: const InputDecoration(
                labelText: "Sand a message...",
                labelStyle: TextStyle(
                  color: Palette.textColor1,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Palette.activeColor),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // 모든 키 입력에서 seyState 메서드가 실행되게 된다. 값을 입력할 때마다 메세지를 업데이트 할 수 있고, 이 값을 가지고 아이콘 버튼을 잠그거나 활성화 시킬 수도 있다
                  _userEnterMessage = value;
                });
              },
            ),
          ),
          IconButton(
            //_userEnterMessage의 양 끝을 제거한 결과(trim)가, isEmpty일 경우에는 텍스트 필드에 유효한 텍스트가 존재하지 않는다.
            //null일 경우 버튼이 비활성화 하게 한다 / Empty가 아니라면 onPressed에 기능을 전달해준다(버튼을 누를 수 있게 활성화)
            onPressed: _userEnterMessage.trim().isEmpty ? null : _sendMessage,
            icon: const Icon(Icons.send_rounded),
            color: Palette.activeColor,
          ),
        ],
      ),
    );
  }
}
