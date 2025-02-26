import 'package:flutter/material.dart';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hwscontrol/core/theme/custom_theme.dart';
import 'package:hwscontrol/core/components/snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hwscontrol/core/models/user_model.dart';
import 'package:hwscontrol/views/dashboard.dart';

class LoginSignup extends StatefulWidget {
  const LoginSignup({Key? key}) : super(key: key);

  @override
  _LoginSignupState createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode focusNodeConfirmPassword = FocusNode();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode focusNodeName = FocusNode();

  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupNameController = TextEditingController();
  final TextEditingController signupPasswordController =
      TextEditingController();
  final TextEditingController signupConfirmPasswordController =
      TextEditingController();

  final _storage = const FlutterSecureStorage();

  bool _obscureTextPassword = true;
  bool _obscureTextConfirmPassword = true;

  _validateFields() {
    String name = signupNameController.text;
    String email = signupEmailController.text;
    String senha = signupPasswordController.text;
    String confirmaSenha = signupConfirmPasswordController.text;

    if (name.trim().isNotEmpty && name.trim().length >= 3) {
      if (email.trim().isNotEmpty && email.trim().contains("@")) {
        if (senha.trim().isNotEmpty && confirmaSenha.trim().isNotEmpty) {
          if (senha.trim() == confirmaSenha.trim()) {
            setState(() {
              CustomSnackBar(context, const Text('Verificando'));
            });

            UserModel userModel =
                UserModel(nome: name, email: email, password: senha);

            _registeruser(userModel);
          } else {
            setState(() {
              CustomSnackBar(context, const Text('As senhas não são iguais!'),
                  backgroundColor: Colors.red);
            });
          }
        } else {
          setState(() {
            CustomSnackBar(context, const Text('Preencha a senha!'));
          });
        }
      } else {
        setState(() {
          CustomSnackBar(context, const Text('Preencha o E-mail utilizando @'),
              backgroundColor: Colors.red);
        });
      }
    } else {
      setState(() {
        CustomSnackBar(context, const Text('Preencha seu nome completo'),
            backgroundColor: Colors.red);
      });
    }
  }

  _registeruser(UserModel userModel) async {
    EasyLoading.showInfo(
      'autenticando...',
      maskType: EasyLoadingMaskType.custom,
      dismissOnTap: false,
      duration: const Duration(seconds: 10),
    );

    FirebaseAuth auth = FirebaseAuth.instance;

    await auth
        .createUserWithEmailAndPassword(
      email: userModel.email!,
      password: userModel.password!,
    )
        .then((firebaseUser) async {
      User? user = firebaseUser.user;
      await user!.updateDisplayName(userModel.nome);
      await user.reload();

      FirebaseFirestore db = FirebaseFirestore.instance;

      await db
          .collection("users")
          .doc(firebaseUser.user!.uid)
          .set(userModel.toMap());

      await _storage.write(key: "keyMail", value: userModel.email);
      await _storage.write(key: "keyPasswd", value: userModel.password);

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
            'Erro ao cadastrar usuário, verifique os campos e tente novamente!'),
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
  void dispose() {
    _focusNodePassword.dispose();
    focusNodeConfirmPassword.dispose();
    _focusNodeEmail.dispose();
    focusNodeName.dispose();
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
                  height: 370.0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 25, 25),
                        child: TextField(
                          focusNode: focusNodeName,
                          controller: signupNameController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          autocorrect: false,
                          style: const TextStyle(
                            fontFamily: 'WorkSansThin',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            icon: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.black,
                            ),
                            hintText: 'Nome completo',
                            hintStyle: TextStyle(
                              fontFamily: 'WorkSansThin',
                              fontSize: 16.0,
                            ),
                          ),
                          onSubmitted: (_) {
                            _focusNodeEmail.requestFocus();
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
                          focusNode: _focusNodeEmail,
                          controller: signupEmailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
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
                            ),
                            hintText: 'E-mail',
                            hintStyle: TextStyle(
                              fontFamily: 'WorkSansThin',
                              fontSize: 16.0,
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
                          controller: signupPasswordController,
                          obscureText: _obscureTextPassword,
                          autocorrect: false,
                          style: const TextStyle(
                            fontFamily: 'WorkSansThin',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: const Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: 'Senha',
                            hintStyle: const TextStyle(
                                fontFamily: 'WorkSansThin', fontSize: 16.0),
                            suffixIcon: GestureDetector(
                              onTap: _toggleSignup,
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
                            focusNodeConfirmPassword.requestFocus();
                          },
                        ),
                      ),
                      Container(
                        width: 250.0,
                        height: 1.0,
                        color: Colors.grey[400],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, bottom: 20.0, left: 25.0, right: 25.0),
                        child: TextField(
                          focusNode: focusNodeConfirmPassword,
                          controller: signupConfirmPasswordController,
                          obscureText: _obscureTextConfirmPassword,
                          autocorrect: false,
                          style: const TextStyle(
                            fontFamily: 'WorkSansThin',
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: const Icon(
                              FontAwesomeIcons.lock,
                              color: Colors.black,
                            ),
                            hintText: 'Confirmar senha',
                            hintStyle: const TextStyle(
                                fontFamily: 'WorkSansThin', fontSize: 16.0),
                            suffixIcon: GestureDetector(
                              onTap: _toggleSignupConfirm,
                              child: Icon(
                                _obscureTextConfirmPassword
                                    ? FontAwesomeIcons.eye
                                    : FontAwesomeIcons.eyeSlash,
                                size: 15.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          onSubmitted: (_) {
                            _toggleLoginSignupButton();
                          },
                          textInputAction: TextInputAction.go,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 350),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
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
                      tileMode: TileMode.clamp),
                ),
                child: MaterialButton(
                  highlightColor: Colors.transparent,
                  splashColor: CustomTheme.loginGradientEnd,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 42),
                    child: Text(
                      'Cadastrar',
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 25.0,
                        fontFamily: 'WorkSansBold',
                      ),
                    ),
                  ),
                  onPressed: () => _toggleLoginSignupButton(),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _toggleLoginSignupButton() {
    CustomSnackBar(context, const Text('Verificando'));
    _validateFields();
  }

  void _toggleSignup() {
    setState(() {
      _obscureTextPassword = !_obscureTextPassword;
    });
  }

  void _toggleSignupConfirm() {
    setState(() {
      _obscureTextConfirmPassword = !_obscureTextConfirmPassword;
    });
  }
}
