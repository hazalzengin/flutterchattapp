import 'package:flutter/material.dart';
import 'package:messagepart/components/my_button.dart';
import 'package:messagepart/components/my_text_field.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
class LoginPage extends StatefulWidget{
  final void Function()? onTap;
  const LoginPage({super.key,required this.onTap});
  @override
  State<LoginPage> createState()=>_LoginPageState();
}


class _LoginPageState extends State<LoginPage>{
final emailController =TextEditingController();
final passwordController= TextEditingController();
void signin() async{
  final authService =Provider.of<AuthService>(context,listen:false);
  try{
    await authService.signInWithEmailandPassword(emailController.text, passwordController.text);
  }
  catch (e){
    ScaffoldMessenger.of(context).showSnackBar(
        (SnackBar(
          content: Text(
            e.toString(),
          ),
        )));
  }
}
  @override
  Widget build (BuildContext context){
    return Scaffold(
      backgroundColor: Colors.grey,
     body:SafeArea(
       child:Center(
         child:Padding(
           padding: const EdgeInsets.symmetric(horizontal: 25.0),
           child: Column(
             children:[
               Icon(
                  Icons.message,
                 size:80,
                 color:Colors.grey,

               ),
               const Text(
                 "Hello",
                 style:TextStyle(
                   fontSize: 16,

                 ),
               ),
               MyTextField(controller: emailController, hintText: 'Email', obsurceText: false),
               const SizedBox(height:10),
               MyTextField(controller: passwordController, hintText: 'Password', obsurceText: true),
               const SizedBox(height:25),
               MyButton(onTap:signin,text:'Sign In'),
               const SizedBox(height:25),
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                 const  Text('Not member'),
                 const  SizedBox(width:4),
                   GestureDetector(
                     onTap: widget.onTap,
                     child:const  Text(
                       "rEGİSTER OL",
                       style:TextStyle(
                         fontWeight: FontWeight.bold,
                       )
                     ),
                   ),

                 ],
               )




             ]

           ),
         )
       )
     )
    );
  }
}