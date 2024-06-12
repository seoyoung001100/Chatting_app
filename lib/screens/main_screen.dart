import 'dart:io';

import 'package:chatting_app/add_image/add_image.dart';
import 'package:chatting_app/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _authentication = FirebaseAuth.instance; // 사용자 등록과 인증에 사용 할 인스턴스

  bool isSignupScreen = true;
  bool showSpinner = false;
  final _formKey = GlobalKey<FormState>(); // 글로벌 키 생성
  bool showWarning = true;
  String userName = "";
  String userEmail = "";
  String userPassword = "";
  File? userPickedImage;

  void pickedImage(File image) {
    userPickedImage = image;
  }

  void _tryValidation() {
    // validate() 메서드를 통해서 폼 필드에 있는 validate를 작동시킬 수가 있다
    // currentState에 근거해서만 validate가 호출될 수 있기 때문에 null 체크를 해줘야 한다
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!
          .save(); // 마찬가지로 currentState가 그거해야만 save 호출이 가능하다. 키에서 받아온 값들을 save 메서드를 통해서 저장 할 수 있다.
    } else {
      setState(() {
        showWarning = false;
      });
    } // 이 메서드를 호출하면 onSaved 메서드를 호출하기 때문에 각 텍스트 폼 필드에서 onSaved 메서드를 추가해줘야 한다
  }

  // 이미지를 넣기 위함 다이얼로그 창
  void showAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: AddImage(pickedImage), // 포인터만을 전달해줌
        );
      },
    );
  }

  //구글 로그인 부분 ------------------------------------------------------------
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final email = userCredential.user?.email;
    final userName = userCredential.user?.displayName;

    if (email != null) {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(userCredential.user?.uid)
          .set({
        "email": email,
        'userName': userName,
      });
    }
    print("로그인 성공! 유저 : $userName");
    return userCredential;
  }

  //카카오 로그인 부분 -----------------------------------------------------------
  void signInWithKakao() async {
    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        // 카카오톡 설치 확인
        token = await UserApi.instance
            .loginWithKakaoTalk(); // 설치되어 있는 경우 (카카오톡을 통해서 로그인)
        print('카카오톡으로 로그인 성공');
      } else {
        token = await UserApi.instance
            .loginWithKakaoAccount(); // 설치되어 있지 않은 경우 (카카오 계정을 통해 로그인)
        print('카카오계정으로 로그인 성공');
      }
      await _updateFirebaseAuth(token); // 인증 업데이트
    } catch (error) {
      print('로그인 실패: $error');
    }
  }

  Future<void> _updateFirebaseAuth(OAuthToken token) async {
    // 인증 업데이트 / 사용자 정보 저장
    try {
      var provider =
          OAuthProvider("oidc.readingbuddy"); // OAuthProvider을 사용하여 카카오 인증을 처리
      var credential = provider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final kakaoUser = await UserApi.instance.me();
      final userName =
          kakaoUser.kakaoAccount?.profile?.nickname ?? 'unknown_user';

      await FirebaseFirestore.instance
          .collection("user")
          .doc(userCredential.user!.uid)
          .set(
        {
          "userName": userName,
          "email": kakaoUser.kakaoAccount?.email ?? 'no_email',
        },
      );

      print('카카오 로그인 성공. 유저 네임: $userName');
    } catch (error) {
      print('Firebase Auth 업데이트 실패: $error');
    }
  }

  // 본물 코드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      //Stack 위젯을 사용하면 위젯들을 원하는 곳에 위치할 수 있다
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        progressIndicator: const CircularProgressIndicator(
          // 사용자 지정 로딩 인디케이터 설정
          valueColor: AlwaysStoppedAnimation<Color>(
              Palette.activeColor), // 로딩 인디케이터 색상 설정
        ),
        child: GestureDetector(
          onTap: () {
            // 키보드가 올라오고 화면 밖을 터치했을 때 키보디가 내려가게 하는 부분
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                // width: 300,
                // height: 300,
                child: Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    // color: Colors.red,
                    image: DecorationImage(
                      image: AssetImage("assets/imges/IMG_01.jpeg"),
                      // 상단 여백을 없애는 애 : fit
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 90,
                      left: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: "WelCome",
                            style: const TextStyle(
                              letterSpacing: 1.0,
                              fontSize: 25,
                              color: Colors.white,
                            ),
                            children: [
                              TextSpan(
                                text: isSignupScreen
                                    ? " to AMUZ chat!"
                                    : " back!",
                                style: const TextStyle(
                                  letterSpacing: 1.0,
                                  fontSize: 25,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 4.0,
                        ),
                        Text(
                          isSignupScreen
                              ? "Signup to continue"
                              : "Signin to continue",
                          style: const TextStyle(
                            letterSpacing: 1.0,
                            // fontSize: 25,
                            color: Colors.white,
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 텍스트 폼 필드
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                top: 180,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  padding: const EdgeInsets.all(20),
                  height:
                      isSignupScreen ? (showWarning ? 350.0 : 430.0) : 250.0,
                  //MidiaQuery : 가로 화면으로 돌려도 항상 좌우여백 20씩을 준다
                  width: MediaQuery.of(context).size.width - 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 130, 157, 188)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSignupScreen = false;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: !isSignupScreen
                                        ? Palette.activeColor
                                        : Palette.textColor1,
                                  ),
                                ),
                                if (!isSignupScreen) //이 조건을 붙여줌으로서 조건이 맞으면 아래의 컨테이너를 그리게 된다. (선택한 탭의 밑줄만 보이게 함)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    height: 2,
                                    width: 55,
                                    color: const Color.fromARGB(
                                        255, 129, 161, 201),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isSignupScreen = true;
                                showWarning = true;
                              });
                            },
                            child: Column(
                              children: [
                                Text(
                                  "SIGNUP",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSignupScreen
                                        ? Palette.activeColor
                                        : Palette.textColor1,
                                  ),
                                ),
                                if (isSignupScreen) //이 조건을 붙여줌으로서 조건이 맞으면 아래의 컨테이너를 그리게 된다. (선택한 탭의 밑줄만 보이게 함)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    height: 2,
                                    width: 55,
                                    color: const Color.fromARGB(
                                        255, 129, 161, 201),
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                      if (isSignupScreen) // SIGNUP
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  key: const ValueKey(1),
                                  validator: (value) {
                                    // value가 null이면 안되기 때문에 체크를 해줘야 한다 (null safety)
                                    if (value!.isEmpty || value.length < 4) {
                                      return "Please enter at least 4 characters.";
                                    }
                                    return null;
                                  },
                                  //onSaved : 사용자가 입력한 값을 저장하는 기능을 가지고 있기 때문에 value 값을 인자값으로 전달
                                  onSaved: (value) {
                                    userName = value!;
                                  },
                                  onChanged: (value) {
                                    userName =
                                        value; // userName 라는 변수에 입력 받은 값을 전달
                                  },
                                  cursorColor: Palette.activeColor,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.account_circle,
                                      color: Palette.textColor1,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.textColor1,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.activeColor,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    hintText: "User name",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Palette.textColor1,
                                    ),
                                    // text 필드를 만들때 종종 사용되기 때문에 기억해두는 것이 좋다
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  keyboardType: TextInputType
                                      .emailAddress, // 사용자의 편의를 위한 @이가 들어간 키보드가 올라온다
                                  key: const ValueKey(2),
                                  validator: (value) {
                                    // value가 null이면 안되기 때문에 체크를 해줘야 한다 (null safety)
                                    if (value!.isEmpty ||
                                        !value.contains("@")) {
                                      return "Please enter a valid email address.";
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    userEmail = value!;
                                  },
                                  onChanged: (value) {
                                    userEmail =
                                        value; // userName 라는 변수에 입력 받은 값을 전달
                                  },
                                  cursorColor: Palette.activeColor,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.email_rounded,
                                      color: Palette.textColor1,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.textColor1,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.activeColor,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Palette.textColor1,
                                    ),
                                    // text 필드를 만들때 종종 사용되기 때문에 기억해두는 것이 좋다
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  obscureText: true, // 비밀번호 숨겨주는 역활
                                  key: const ValueKey(3),
                                  validator: (value) {
                                    // value가 null이면 안되기 때문에 체크를 해줘야 한다 (null safety)
                                    if (value!.isEmpty || value.length < 6) {
                                      return "Password must be at least 7 characters long.";
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    userPassword = value!;
                                  },
                                  onChanged: (value) {
                                    userPassword =
                                        value; // userName 라는 변수에 입력 받은 값을 전달
                                  },
                                  cursorColor: Palette.activeColor,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: Palette.textColor1,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.textColor1,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.activeColor,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    hintText: "password",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Palette.textColor1,
                                    ),
                                    // text 필드를 만들때 종종 사용되기 때문에 기억해두는 것이 좋다
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextButton(
                                  onPressed: () {
                                    showAlert(context);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(350, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    backgroundColor: Palette.textColor1,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.start, // 왼쪽으로 정렬
                                    children: [
                                      Icon(Icons.image_rounded),
                                      SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격
                                      Text('Image Add'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!isSignupScreen) // LOGIN
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  keyboardType: TextInputType.emailAddress,
                                  key: const ValueKey(4),
                                  validator: (value) {
                                    // value가 null이면 안되기 때문에 체크를 해줘야 한다 (null safety)
                                    if (value!.isEmpty ||
                                        !value.contains("@")) {
                                      return "Please enter a valid email address.";
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    userEmail = value!;
                                  },
                                  onChanged: (value) {
                                    userEmail =
                                        value; // userName 라는 변수에 입력 받은 값을 전달
                                  },
                                  cursorColor: Palette.activeColor,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.email_rounded,
                                      color: Palette.textColor1,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.textColor1,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.activeColor,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Palette.textColor1,
                                    ),
                                    // text 필드를 만들때 종종 사용되기 때문에 기억해두는 것이 좋다
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  obscureText: true,
                                  key: const ValueKey(5),
                                  validator: (value) {
                                    // value가 null이면 안되기 때문에 체크를 해줘야 한다 (null safety)
                                    if (value!.isEmpty || value.length < 6) {
                                      return "Password must be at least 7 characters long.";
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    userPassword = value!;
                                  },
                                  onChanged: (value) {
                                    userPassword =
                                        value; // userName 라는 변수에 입력 받은 값을 전달
                                  },
                                  cursorColor: Palette.activeColor,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: Palette.textColor1,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.textColor1,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Palette.activeColor,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(35),
                                      ),
                                    ),
                                    hintText: "Password",
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: Palette.textColor1,
                                    ),
                                    // text 필드를 만들때 종종 사용되기 때문에 기억해두는 것이 좋다
                                    contentPadding: EdgeInsets.all(10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
              // ->(전송) 버튼
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                top: isSignupScreen ? (showWarning ? 500.0 : 580.0) : 400,
                right: 0,
                left: 0,
                child: Center(
                  // 배경
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    // 버튼
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          showSpinner = true;
                        });
                        if (isSignupScreen) {
                          _tryValidation();

                          try {
                            final newUser = await _authentication
                                .createUserWithEmailAndPassword(
                              email: userEmail,
                              password: userPassword,
                            );

                            final refImage = FirebaseStorage.instance
                                .ref()
                                .child('picked_image')
                                .child(
                                    '${newUser.user!.uid}.png'); //ref : 이미지 등이 저장되는 클라우드 스토리지 버킷에 접근할 수 있게 해주는 역활

                            await refImage.putFile(userPickedImage!);

                            await FirebaseFirestore.instance
                                .collection("user")
                                .doc(newUser.user!.uid)
                                .set(
                              {"userName": userName, "email": userEmail},
                            ); // doc 메서드로 user ID를 전달 해준다

                            if (newUser.user != null) {
                              // 여기에서 user는 UserCredential 클래스가 가진 속성
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) {
                              //       return const ChatScreen();
                              //     },
                              //   ),
                              // );
                              setState(() {
                                showSpinner = false;
                              });
                            }
                          } catch (e) {
                            print(e); // 콘솔창에서 Exception의 내용이 출력 되도록 해준다
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Please check your email and password."),
                                backgroundColor: Palette.activeColor,
                              ),
                            );
                            setState(() {
                              showSpinner = false;
                            });
                          }
                        }
                        if (!isSignupScreen) {
                          _tryValidation();
                          try {
                            final newUser = await _authentication
                                .signInWithEmailAndPassword(
                              email: userEmail,
                              password: userPassword,
                            );
                            if (newUser.user != null) {
                              // 여기에서 user는 UserCredential 클래스가 가진 속성
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) {
                              //       return const ChatScreen();
                              //     },
                              //   ),
                              // );
                              setState(() {
                                showSpinner = false;
                              });
                            }
                          } catch (e) {
                            print(e);
                            setState(() {
                              showSpinner = false;
                            });
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Palette.textColor1,
                              Palette.textColor2,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // SIGNUP 스크린
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn,
                top: isSignupScreen
                    ? MediaQuery.of(context).size.height - 230
                    : MediaQuery.of(context).size.height - 330,
                right: 40,
                left: 40,
                child: Column(
                  children: [
                    Text(
                      isSignupScreen ? "or Signup with" : "or Signin with",
                      style: TextStyle(
                        color: Palette.activeColor.withOpacity(0.5),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            signInWithGoogle();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            backgroundColor: Palette.googleColor,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Google'),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            backgroundColor: Palette.googleColor,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Apple'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            signInWithKakao();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25)),
                            backgroundColor: Palette.googleColor,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Kakao'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
