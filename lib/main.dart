import 'package:flutter/material.dart';
import 'package:messagepart/login_page.dart';
import 'package:messagepart/register_page.dart';
import 'package:messagepart/services/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'services/auth/loginorregister.dart';
import 'package:messagepart/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create:(context)=>AuthService(),
    child:const MyApp(),
    )
  );
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
  Widget build (BuildContext context){
    return const MaterialApp(
      debugShowCheckedModeBanner : false,
      home:AuthGate(),


    );
  }
}