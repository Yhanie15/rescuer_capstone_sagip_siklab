import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'signup_screen.dart';
import 'home_page.dart';  // Import the home page


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn
  bool isLoading = false;

  // Sign in with Google
  Future<void> signInWithGoogle() async {
  setState(() {
    isLoading = true;
  });

  try {
    // Attempt to sign in with Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User canceled the sign-in process
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Ensure that the authentication details are valid
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw 'Missing Google authentication tokens';
    }

    // Create OAuth credential for Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in with the Google credentials
    UserCredential userCredential = await _auth.signInWithCredential(credential);
    print('User signed in: ${userCredential.user?.displayName}');

    // Navigate to HomePage after successful login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NavigationPage()),
    );
  } catch (e) {
    print('Error during Google sign-in: $e');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  // Sign in with email and password
  Future<void> signInUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Attempt to sign in the user
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Navigate to HomePage after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationPage()),
      );
    } catch (e) {
      print(e);
      // Show error message if login fails
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and App Title
              Container(
  alignment: Alignment.center,
  child: Column(
    children: [
      // Lowering the logo placement by adjusting the SizedBox height
      const SizedBox(height: 40),  // Add space before the logo to lower its placement
      Image.asset('assets/logo.png', height: 120), // Logo from assets
      const SizedBox(height: 20),
      Image.asset('assets/text.png', height: 30), // Text logo from assets
      const SizedBox(height: 20),
      const Text(
        'RESCUER',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 40),

              // Email text field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Password text field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In Button
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: signInUser,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,  // Set the button color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

              const SizedBox(height: 20),

              // Google Sign-In Button with Google Icon
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
  onPressed: signInWithGoogle,
  icon: Image.asset('assets/google_logo.png', height: 30), // Custom Google logo
  label: const Text(
    'Sign in with Google',
    style: TextStyle(fontSize: 18),
  ),
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 50),
    backgroundColor: Colors.grey,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
),


              const SizedBox(height: 20),

              // Forgot Password & Sign Up links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      // Navigate to Forgot Password Screen (Implement if needed)
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
