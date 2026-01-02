import 'package:get/get.dart';
import 'package:pe/features/auth/views/screens/login_screen.dart';
import 'package:pe/features/home/views/screens/home_screen.dart';

import '../features/auth/views/screens/sign_up_screen.dart';
import '../features/editor/views/screens/document_editor_screen.dart';

class AppRoute {
  static String loginScreen = "/loginScreen";
  static String homeScreen = "/homeScreen";
  static String signupScreen = "/signupScreen";
  static String editorScreen = "/editorScreen";



  static String getLoginScreen() => loginScreen;
  static String getHomeScreen() => homeScreen;
  static String getSignupScreen() => signupScreen;
  static String getEditorScreen() => editorScreen;




  static List<GetPage> routes = [
    GetPage(name: loginScreen, page: () => LoginScreen()),
    GetPage(name: homeScreen, page: () => HomeScreen()),
    GetPage(name: signupScreen, page: () => SignupScreen()),
    GetPage(name: editorScreen, page: () => DocumentEditorScreen()),
  ];
}
