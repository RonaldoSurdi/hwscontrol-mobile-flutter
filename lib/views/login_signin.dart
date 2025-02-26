import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hwscontrol/core/theme/custom_theme.dart';
import 'package:hwscontrol/core/components/snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hwscontrol/views/dashboard.dart';

class LoginSignin extends StatefulWidget {
  const LoginSignin({Key? key}) : super(key: key);

  @override
  _LoginSigninState createState() => _LoginSigninState();
}

class _LoginSigninState extends State<LoginSignin> {
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();

  final _storage = const FlutterSecureStorage();
  bool _obscureTextPassword = true;

  void _validateFields() async {
    String email = _loginEmailController.text;
    String password = _loginPasswordController.text;

    if (email.trim().isNotEmpty && email.trim().contains("@")) {
      if (password.isNotEmpty) {
        _logarUsuario();
      } else {
        CustomSnackBar(
          context,
          const Text('Preencha a senha!'),
          backgroundColor: Colors.red,
        );
      }
    } else {
      CustomSnackBar(
        context,
        const Text('Preencha o E-mail utilizando @'),
        backgroundColor: Colors.red,
      );
    }
  }

  void _logarUsuario() async {
    EasyLoading.showInfo(
      'autenticando...',
      maskType: EasyLoadingMaskType.custom,
      dismissOnTap: false,
      duration: const Duration(seconds: 10),
    );

    FirebaseAuth auth = FirebaseAuth.instance;

    String email = _loginEmailController.text;
    String password = _loginPasswordController.text;

    await auth
        .signInWithEmailAndPassword(
      email: email,
      password: password,
    )
        .then((firebaseUser) async {
      await _storage.write(key: "keyMail", value: email);
      await _storage.write(key: "keyPasswd", value: password);

      closeLoading();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (builder) => const Dashboard(title: 'Loading...'),
        ),
      );
    }).catchError((error) {
      closeLoading();

      CustomSnackBar(
        context,
        const Text(
            'Erro ao autenticar usuário, verifique e-mail e senha e tente novamente!'),
        backgroundColor: Colors.red,
      );
    });
  }

  closeLoading() {
    if (EasyLoading.isShow) {
      Timer(const Duration(milliseconds: 500), () {
        EasyLoading.dismiss(animation: true);
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 23),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Card(
                elevation: 2.0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 300.0,
                  height: 200.0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                          bottom: 20.0,
                          left: 25.0,
                          right: 25.0,
                        ),
                        child: TextField(
                          focusNode: _focusNodeEmail,
                          controller: _loginEmailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'WorkSansThin',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.envelope,
                              color: Colors.black,
                              size: 22.0,
                            ),
                            hintText: 'E-mail',
                            hintStyle: TextStyle(
                              fontFamily: 'WorkSansThin',
                              fontSize: 17.0,
                            ),
                          ),
                          onSubmitted: (_) {
                            _focusNodePassword.requestFocus();
                          },
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 25, 25),
                        child: TextField(
                          focusNode: _focusNodePassword,
                          controller: _loginPasswordController,
                          obscureText: _obscureTextPassword,
                          style: const TextStyle(
                            fontFamily: 'WorkSansThin',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: const Icon(
                              FontAwesomeIcons.lock,
                              size: 22.0,
                              color: Colors.black,
                            ),
                            hintText: 'Senha',
                            hintStyle: const TextStyle(
                                fontFamily: 'WorkSansThin', fontSize: 17.0),
                            suffixIcon: GestureDetector(
                              onTap: _toggleLogin,
                              child: Icon(
                                _obscureTextPassword
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                size: 15.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          onSubmitted: (_) {
                            _toggleLoginSigninButton();
                          },
                          textInputAction: TextInputAction.go,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 180),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: CustomTheme.loginGradientStart,
                      offset: Offset(1.0, 6.0),
                      blurRadius: 20.0,
                    ),
                    BoxShadow(
                      color: CustomTheme.loginGradientEnd,
                      offset: Offset(1.0, 6.0),
                      blurRadius: 20.0,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: <Color>[
                      CustomTheme.loginGradientEnd,
                      CustomTheme.loginGradientStart
                    ],
                    begin: FractionalOffset(0.2, 0.2),
                    end: FractionalOffset(1.0, 1.0),
                    stops: <double>[0.0, 1.0],
                    tileMode: TileMode.clamp,
                  ),
                ),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  splashColor: CustomTheme.loginGradientEnd,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 42.0,
                    ),
                    child: Text(
                      'Conectar',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 25.0,
                        fontFamily: 'WorkSansBold',
                      ),
                    ),
                  ),
                  onPressed: () => _toggleLoginSigninButton(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLoginSigninButton() {
    _validateFields();
  }

  void _toggleLogin() {
    setState(() {
      _obscureTextPassword = !_obscureTextPassword;
    });
  }
}
