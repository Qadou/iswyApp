import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dashboard.dart';
import 'package:xml/xml.dart' as xml;

void _logout(BuildContext context) async {
  try {
    // Perform the logout operation here (e.g., clear user session, etc.)
    await FirebaseAuth.instance.signOut();

    // Clear the entire navigation stack and push the login page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  } catch (e) {
    print('Error logging out: $e');
  }
}

class FacturePage extends StatefulWidget {
  @override
  _FacturePageState createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  //add regime anne periode
  final TextEditingController anneeController = TextEditingController();
  final TextEditingController periodeController = TextEditingController();
  final TextEditingController regimeController = TextEditingController();

  final TextEditingController orderController = TextEditingController();
  final TextEditingController numController = TextEditingController();
  final TextEditingController desController = TextEditingController();
  final TextEditingController mhtController = TextEditingController();
  final TextEditingController tvaController = TextEditingController();
  final TextEditingController ttcController = TextEditingController();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController iceController = TextEditingController();
  final TextEditingController tauxController = TextEditingController();
  final TextEditingController mpIdController = TextEditingController();
  final TextEditingController dpaiController = TextEditingController();
  final TextEditingController dfacController = TextEditingController();

  // Field validation functions

  String? validateAnnee(String? value) {
    if (value == null || value.isEmpty) {
      return 'Année is required';
    }
    if (value.length != 4) {
      return 'Année must have 4 characters';
    }
    if (int.tryParse(value) == null) {
      return 'Année must be a valid integer';
    }
    return null;
  }

  String? validatePeriode(String? value) {
    if (value != null && value.length > 2) {
      return 'Période must have at most 2 characters';
    }
    if (value != null && int.tryParse(value) == null) {
      return 'Période must be a valid integer';
    }
    return null;
  }

  String? validateRegime(String? value) {
    if (value != null && (int.tryParse(value) == null || int.parse(value) < 0 || int.parse(value) > 9)) {
      return 'Régime must be an integer between 0 and 9';
    }
    return null;
  }

  String? validateInt(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid integer';
    }
    return null;
  }

  String? validateString(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validatePercent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Taux is required';
    }
    final double? parsedValue = double.tryParse(value.replaceFirst('%', ''));
    if (parsedValue == null || parsedValue < 0 || parsedValue > 100) {
      return 'Taux must be a valid percentage between 0% and 100%';
    }
    return null;
  }

  String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    final pattern = r'^\d{2}-\d{2}-\d{4}$';
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid $fieldName format. Use DD-MM-YYYY';
    }
    return null;
  }

  Future<Map> fetchData() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final email = FirebaseAuth.instance.currentUser!.email;

    final DatabaseEvent event = await ref.child('users').once();
    final DataSnapshot snapshot = event.snapshot;
    final dynamic data = snapshot.value;
    String? idFiscal;

    data.forEach(
      (key, value) {
        if (value['email'] == email) {
          idFiscal = value['idFiscal'];
        }
      },
    );

    return {
      'idFiscal': idFiscal,
    };
  }

  void generateXML(String idFiscal) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final builder = xml.XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
      builder.element('DeclarationReleveDeduction', nest: () {
        builder.element('identifiantFiscal', nest: idFiscal ?? '');
        builder.element('annee', nest: anneeController.text);
        builder.element('periode', nest: periodeController.text);
        builder.element('regime', nest: regimeController.text);
        builder.element('releveDeductions', nest: () {
          builder.element('rd', nest: () {
            builder.element('ord', nest: orderController.text);
            builder.element('num', nest: numController.text);
            builder.element('des', nest: desController.text);
            builder.element('mht', nest: mhtController.text);
            builder.element('tva', nest: tvaController.text);
            builder.element('ttc', nest: ttcController.text);
            builder.element('refF', nest: () {
              builder.element('if', nest: idFiscal);
              builder.element('nom', nest: nomController.text);
              builder.element('ice', nest: iceController.text);
            });
            builder.element('tx', nest: tauxController.text);
            builder.element('mp', nest: () {
              builder.element('id', nest: mpIdController.text);
            });
            builder.element('dpai', nest: dpaiController.text);
            builder.element('dfac', nest: dfacController.text);
          });
        });
      });

      final xmlDoc = builder.build();
      final xmlString = xmlDoc.toXmlString(pretty: true);
      print(xmlString);

      saveXmlFile(xmlString); // Save the generated XML file
    } catch (e) {
      print('Error generating XML: $e');
      // TODO: Handle the error appropriately (e.g., show an error message to the user)
    }
  }

  Future<void> saveXmlFile(String xmlString) async {
    try {
      final permissionStatus = await Permission.storage.status;

      if (permissionStatus.isDenied) {
        // Here just ask for the permission for the first time
        await Permission.storage.request();
        // I noticed that sometimes the popup won't show after the user presses deny,
        // so I do the check once again but now go straight to appSettings
        if (permissionStatus.isDenied) {
          await openAppSettings();
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        // Here open app settings for the user to manually enable permission
        await openAppSettings();
      } else if (permissionStatus.isGranted) {
        final directory = Directory('/storage/emulated/0/ISWY'); // Change the directory path
        final timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9a-zA-Z]+'), '');
        final fileName = 'ISWY-$timestamp.xml';
        final filePath = '${directory.path}/$fileName';

        final folderExists = await directory.exists();
        if (!folderExists) {
          await directory.create(recursive: true);
        }

        final file = File(filePath);
        await file.writeAsString(xmlString);

        print('XML file saved: ${file.path}');
      } else {
        print('Permission not granted');
        // TODO: Handle the case where permission is not granted
      }
    } catch (e) {
      print('Error saving XML file: $e');
      // TODO: Handle the error appropriately (e.g., show an error message to the user)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        title: Text('New Declaration'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
            
          },
          
        ),
         actions: [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () {
        // Add your desired functionality when the "+" button is pressed
      },
    ),
  ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo[900],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage('assets/logo.png'),
                        radius: 50,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'ISWY \nConsulting',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Nouvelle Déclaration'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FacturePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Liste de Déclaration'),
              onTap: () {
                // Add your onTap functionality here
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: FutureBuilder<Map>(
          future: fetchData(),
          builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData) {
              return const Text('No orders available');
            }
            final data = snapshot.data!;
            print(data);
            String idFiscal = data['idFiscal'];

            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Releve Deductions', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16.0),
                  FactureFormField(
                    label: 'Année',
                    fieldName: 'annee',
                    controller: anneeController,
                    validator: validateAnnee,
                  ),
                  FactureFormField(
                    label: 'Période',
                    fieldName: 'periode',
                    controller: periodeController,
                    validator: validatePeriode,
                  ),
                  FactureFormField(
                    label: 'Régime',
                    fieldName: 'regime',
                    controller: regimeController,
                    validator: validateRegime,
                  ),
                  FactureFormField(
                    label: 'Numéro de commande',
                    fieldName: 'order',
                    controller: orderController,
                    validator: (value) => validateInt(value, 'Numéro de commande'),
                  ),
                  FactureFormField(
                    label: 'Fact num',
                    fieldName: 'num',
                    controller: numController,
                    validator: (value) => validateInt(value, 'Fact num'),
                  ),
                  FactureFormField(
                    label: 'Designation',
                    fieldName: 'des',
                    controller: desController,
                    validator: (value) => validateString(value, 'Designation'),
                  ),
                  FactureFormField(
                    label: 'Montant HT',
                    fieldName: 'mht',
                    controller: mhtController,
                    validator: (value) => validateInt(value, 'Montant HT'),
                  ),
                  FactureFormField(
                    label: 'TVA',
                    fieldName: 'tva',
                    controller: tvaController,
                    validator: (value) => validateInt(value, 'TVA'),
                  ),
                  FactureFormField(
                    label: 'TTC',
                    fieldName: 'ttc',
                    controller: ttcController,
                    validator: (value) => validateInt(value, 'TTC'),
                  ),
                  SizedBox(height: 16.0),
                  Text('Référence Fournisseur', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16.0),
                  FactureFormField(
                    label: 'Nom Fournisseur',
                    fieldName: 'nom',
                    controller: nomController,
                    validator: (value) => validateString(value, 'Nom Fournisseur'),
                  ),
                  FactureFormField(
                    label: 'ICE',
                    fieldName: 'ice',
                    controller: iceController,
                    validator: (value) => validateInt(value, 'ICE'),
                  ),
                  SizedBox(height: 16.0),
                  FactureFormField(
                    label: 'Taux',
                    fieldName: 'taux',
                    controller: tauxController,
                    validator: validatePercent,
                  ),
                  FactureFormField(
                    label: 'Mode Paiement',
                    fieldName: 'mpId',
                    controller: mpIdController,
                    validator: (value) => validateInt(value, 'Mode Paiement'),
                  ),
                  FactureFormField(
                    label: 'Date Paiement',
                    fieldName: 'dpai',
                    controller: dpaiController,
                    validator: (value) => validateDate(value, 'Date Paiement'),
                  ),
                  FactureFormField(
                    label: 'Date Facture',
                    fieldName: 'dfac',
                    controller: dfacController,
                    validator: (value) => validateDate(value, 'Date Facture'),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        generateXML(idFiscal);
                      }
                    },
                    child: Text('Generate XML'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class FactureFormField extends StatelessWidget {
  final String label;
  final String fieldName;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const FactureFormField({
    required this.label,
    required this.fieldName,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
      validator: validator,
    );
  }
}
