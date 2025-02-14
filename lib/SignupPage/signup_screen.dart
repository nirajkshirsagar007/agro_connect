import 'dart:io';
import 'package:agro_connect/Services/global_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../Services/global_variables.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with TickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;


  final _signupFormKey = GlobalKey<FormState>();
  bool _obscureText = true;
  File? imageFile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? imageUrl;

  final TextEditingController _nameTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();
  final TextEditingController _phoneTextController = TextEditingController();
  final TextEditingController _addressTextController = TextEditingController();



  @override
  void dispose() {
    _animationController.dispose();
    _nameTextController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneTextController.dispose();
    _addressTextController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.linear)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((animationStatus) {
            if (animationStatus == AnimationStatus.completed) {
              _animationController.reset();
              _animationController.forward();
            }
          });
    _animationController.forward();
    super.initState();
  }
  void _showImageDialog()
  {
    showDialog(
      context: context,
      builder:(context)
        {
          return  AlertDialog(
            title: const Text('Please choose an option'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: (){
                    _getFromCamera();
                  },
                  child: const Row(
                    children: [
                      Padding(
                          padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.camera,
                              color: Colors.purple,
                            )
                      ),
                      Text(
                        'Camera',
                        style: TextStyle(color: Colors.purple),

                      )
                    ],
                  ),

                ),
                InkWell(
                  onTap: (){
                    _getFromGallery();
                  },
                  child: const Row(
                    children: [
                      Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.image,
                            color: Colors.purple,
                          )
                      ),
                      Text(
                        'Gallery',
                        style: TextStyle(color: Colors.purple),

                      )
                    ],
                  ),

                )
              ],
            ),
          );
        }
    );
  }

  void _getFromCamera() async
  {
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }
  void _getFromGallery() async
  {
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(filePath) async
  {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: filePath, maxHeight: 1080, maxWidth: 1080
    );
    if(croppedImage != null)
      {
        setState(()
        {
          imageFile = File(croppedImage.path);
        });
      }
  }

  void _submitFormonSignUp() async
  {
    final isValid = _signupFormKey.currentState!.validate();
    if(isValid)
      {
        if(imageFile == null)
          {
            GlobalMethod.showErrorDialog(
            error: 'Please pick an image',
            ctx: context
            );
            return;
          }
        setState(() {
          _isLoading = true;
        });

        try {
          await _auth.createUserWithEmailAndPassword(
            email: _emailTextController.text.trim().toLowerCase(),
            password: _passTextController.text.trim(),
          );
          final User? user = _auth.currentUser;
          final _uid = user!.uid;
          final ref = FirebaseStorage.instance.ref().child('userImages').child(
              _uid + '.jpg');
          await ref.putFile(imageFile!);
          imageUrl = await ref.getDownloadURL();
          FirebaseFirestore.instance.collection('users').doc(_uid).set({
            'id': _uid,
            'name': _nameTextController.text,
            'email': _emailTextController.text,
            'userImage': imageUrl,
            'phoneNumber': _phoneTextController.text,
            'createdAt': Timestamp.now(),
          });
          Navigator.canPop(context) ? Navigator.of(context) : null;
        }catch (error)
          {
            setState(() {
              _isLoading = false;
            });
            GlobalMethod.showErrorDialog(error: error.toString(), ctx: context);
          }
      }
    setState(() {
      _isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: signUpUrlImage,
            placeholder: (context, url) => Image.asset(
              'assets/images/farm.jpg',
              fit: BoxFit.fill,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(_animation.value, 0),
          ),
          Container(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
              child: ListView(
                children: [
                  Form(
                    key: _signupFormKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showImageDialog();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: size.width * 0.24,
                              height: size.width * 0.24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1,
                                  color: Colors.cyanAccent,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: imageFile == null
                                    ? const Icon(Icons.camera_enhance_sharp,
                                        color: Colors.cyan, size: 30)
                                    : Image.file(
                                        imageFile!,
                                        fit: BoxFit.fill,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Name TextField
                        TextFormField(
                          controller: _nameTextController,
                          keyboardType: TextInputType.name,
                          decoration: const InputDecoration(
                            hintText: 'Full Name',
                            hintStyle: TextStyle(color: Colors.white),
                               enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),

                        // Email TextField
                        TextFormField(
                          controller: _emailTextController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),

                        // Password TextField
                        TextFormField(
                          controller: _passTextController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.white),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              child: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),

                        // Phone Number TextField
                        TextFormField(
                          controller: _phoneTextController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Phone Number',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            // Check if the phone number contains only digits
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Please enter a valid phone number (digits only)';
                            }
                            // Check if the phone number length is correct (e.g., 10 digits)
                            if (value.length != 10) {
                              return 'Phone number must be 10 digits long';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                        ),

                        // Address TextField
                        TextFormField(
                          controller: _addressTextController,
                          keyboardType: TextInputType.streetAddress,
                          decoration: const InputDecoration(
                            hintText: 'Address',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyan),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your address';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // Signup Button
                        MaterialButton(
                          onPressed: () {
                            _submitFormonSignUp();
                          },
                          color: Colors.cyan,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Center(
                          child: RichText(
                            text: TextSpan(children: [
                              const TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                              const TextSpan(text: '        '),
                              TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => Navigator.canPop(context)
                                        ? Navigator.pop(context)
                                        : null,
                                  text: 'Login',
                                  style: const TextStyle(
                                    color: Colors.cyan,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                            ]),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
