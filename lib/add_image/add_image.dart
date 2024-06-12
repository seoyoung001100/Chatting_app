import 'dart:io';

import 'package:chatting_app/config/palette.dart';
import 'package:flutter/material.dart';
import "package:image_picker/image_picker.dart";

class AddImage extends StatefulWidget {
  const AddImage(this.addImageFunc, {super.key});

  final Function(File pickedImage) addImageFunc;

  @override
  State<AddImage> createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  File? pickedImage;

  void _pickImageCamera() async {
    final imagePicker = ImagePicker();
    final pickedImageFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxHeight: 150, 
    );
    setState(() {
      if (pickedImageFile != null) {
        pickedImage = File(pickedImageFile.path);
      } else {
        pickedImage = const AssetImage("assets/imges/profile.png") as File?;
      }
    });
    widget.addImageFunc(pickedImage!);
  }

  void _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImageFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxHeight: 150,
    );
    setState(() {
      if (pickedImageFile != null) {
        pickedImage = File(pickedImageFile.path);
      } else {
        pickedImage = const AssetImage("assets/imges/profile.png") as File?;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 20,
      ),
      width: 150,
      height: 300,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Palette.textColor1,
            backgroundImage: pickedImage != null
                ? FileImage(pickedImage!)
                : const AssetImage("assets/imges/profile.png") as ImageProvider,
          ),
          const SizedBox(
            height: 10,
          ),
          OutlinedButton.icon(
            onPressed: () {
              _pickImageCamera();
            },
            style: OutlinedButton.styleFrom(
              overlayColor: const Color(0XFFadc1d2),
              side: const BorderSide(
                color: Palette.textColor2, // 원하는 색상으로 변경
              ),
            ),
            icon: const Icon(
              Icons.camera_alt_rounded,
              color: Palette.textColor2,
            ),
            label: const Text(
              "   Camera  ",
              style: TextStyle(
                color: Palette.textColor2,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _pickImage();
            },
            style: OutlinedButton.styleFrom(
              overlayColor: const Color(0XFFadc1d2),
              side: const BorderSide(
                color: Palette.textColor2, // 원하는 색상으로 변경
              ),
            ),
            icon: const Icon(
              Icons.image_rounded,
              color: Palette.textColor2,
            ),
            label: const Text(
              "Add Image",
              style: TextStyle(
                color: Palette.textColor2,
              ),
            ),
          ),
          const SizedBox(
            height: 38,
          ),
          TextButton.icon(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return const Color(0XFFadc1d2).withOpacity(0.1); // 눌렀을 때 색상
                  }
                  return const Color(0XFFadc1d2)
                      .withOpacity(0.1); // 기본 상태 색상 (null이면 기본 색상 사용)
                },
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Palette.activeColor,
            ),
            label: const Text(
              "Close",
              style: TextStyle(
                color: Palette.activeColor,
              ),
            ),
          )
        ],
      ),
    );
  }
}
