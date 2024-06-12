import 'package:chatting_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_8.dart';

class ChatBubbles extends StatelessWidget {
  const ChatBubbles(this.message, this.isMe, this.userName, {super.key});

  final String message;
  final String userName;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 10, 2),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      color: Palette.activeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ChatBubble(
                  backGroundColor: Palette.googleColor,
                  clipper: ChatBubbleClipper8(type: BubbleType.sendBubble),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        if (!isMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 0, 2),
                  child: Text(
                    userName,
                    style: const TextStyle(
                      color: Palette.activeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ChatBubble(
                  backGroundColor: Colors.white,
                  clipper: ChatBubbleClipper8(type: BubbleType.receiverBubble),
                  child: Text(
                    message,
                    style: const TextStyle(color: Palette.activeColor),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}
