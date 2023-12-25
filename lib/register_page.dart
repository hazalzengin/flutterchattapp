import 'package:flutter/material.dart';
import 'package:messagepart/components/my_button.dart';
import 'package:messagepart/components/my_text_field.dart';
import 'package:messagepart/services/auth/auth_service.dart';
import 'package:provider/provider.dart';
class RegisterPage extends StatefulWidget{
  final void Function()? onTap;
  const RegisterPage({super.key,required this.onTap});
  @override
  State<RegisterPage>createState()=>_RegisterPageState();

}

class _RegisterPageState extends State<RegisterPage>{
  final emailController =TextEditingController();
  final passwordController= TextEditingController();
  final confirmPasswordController= TextEditingController();
  void signup() async{
    if(passwordController.text != confirmPasswordController.text){
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
        'Şifre eşleşmemektedir.'
      ),),);
      return;

    }
    final authService =Provider.of<AuthService>(context,listen:false);
    try{
      await authService.signUpWithEmailandPassword(emailController.text,passwordController.text);
    }catch (e){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(),
          ),
          ),
      );
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
                        MyTextField(controller: confirmPasswordController, hintText: 'Password Confirm', obsurceText: false),

                        const SizedBox(height:25),
                        MyButton(onTap:signup,text:'Sign Up'),
                        const SizedBox(height:50),
                       Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already a member'),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: widget.onTap,
                              child: Text('Login',
                              style:TextStyle(
                                fontWeight:FontWeight.bold
                              
                              ),),
                            )
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