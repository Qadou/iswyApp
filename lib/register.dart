import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart'; // Import the dashboard.dart file
import 'package:firebase_database/firebase_database.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController raisonSocialeController =
      TextEditingController();
  final TextEditingController idFiscalController = TextEditingController();
  

  bool _emailRequired = false;
  bool _passwordRequired = false;
  bool _confirmPasswordRequired = false;
  bool _raisonSocialeRequired = false;
  bool _idFiscalRequired = false;
  

void _registerUser() async {
  setState(() {
    _emailRequired = emailController.text.isEmpty;
    _passwordRequired = passwordController.text.isEmpty;
    _confirmPasswordRequired = confirmPasswordController.text.isEmpty;
    _raisonSocialeRequired = raisonSocialeController.text.isEmpty;
    _idFiscalRequired = idFiscalController.text.isEmpty;
    
  });

  if (_emailRequired ||
      _passwordRequired ||
      _confirmPasswordRequired ||
      _raisonSocialeRequired ||
      _idFiscalRequired ) {
    return;
  }

  try {
    // Create a new user with email and password
    var authResult =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );

     DatabaseReference databaseReference = FirebaseDatabase.instance.reference();
      DatabaseReference usersReference = databaseReference.child('users');

      var newUserRef = usersReference.push();
      var newUserId = newUserRef.key;

      await newUserRef.set({
        'id': newUserId,
        'raisonSociale': raisonSocialeController.text,
        'idFiscal': idFiscalController.text,       
        'email': emailController.text,
        'password': passwordController.text,
      });

    // Navigate to the dashboard page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
    );

    // Display success message
  showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green), // Success icon
          SizedBox(width: 8), // Add some spacing between the icon and text
          Text('Inscription réussite'),
        ],
      ),
      content: Text('Vous avez été enregistré avec succès.'),
      actions: [
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {
              // Close the dialog
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.green, // Set button background color to green
            ),
            child: Text('Ok'),
          ),
        ),
      ],
    );
  },
);

  } catch (e) {
    print("Erreur lors de l'enregistrement de l'utilisateur : $e");
  }
}

  void _clearError(String field) {
    setState(() {
      if (field == 'email') {
        _emailRequired = false;
      } else if (field == 'password') {
        _passwordRequired = false;
      } else if (field == 'confirmPassword') {
        _confirmPasswordRequired = false;
      } else if (field == 'raisonSociale') {
        _raisonSocialeRequired = false;
      } else if (field == 'idFiscal') {
        _idFiscalRequired = false;
      
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        title: Text('Nouvelle inscription'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: _emailRequired ? 'Email est requis' : null,
                  ),
                  onTap: () {
                    _clearError('email');
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: _passwordRequired ? 'Mot de passe est requis' : null,
                  ),
                  obscureText: true,
                  onTap: () {
                    _clearError('password');
                  },
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le Mot de passe',
                    errorText: _confirmPasswordRequired
                        ? 'Confirmer le mot de passe est requis '
                        : null,
                  ),
                  obscureText: true,
                  onTap: () {
                    _clearError('confirmPassword');
                  },
                ),
                TextFormField(
                  controller: raisonSocialeController,
                  decoration: InputDecoration(
                    labelText: 'Raison Sociale',
                    errorText: _raisonSocialeRequired ? 'Raison Sociale est requise' : null,
                  ),
                  onTap: () {
                    _clearError('raisonSociale');
                  },
                ),
                TextFormField(
                  controller: idFiscalController,
                  decoration: InputDecoration(
                    labelText: 'ID Fiscal',
                    errorText: _idFiscalRequired ? 'ID Fiscal est requis' : null,
                  ),
                  onTap: () {
                    _clearError('idFiscal');
                  },
                ),
                SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _registerUser,
                  child: Text("S'inscrire"),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.indigo[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
