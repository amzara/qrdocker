import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'readCSV.dart'; // Import the readCSV page
import 'singleQR.dart';
import 'rangeQR.dart';
import 'targetQR.dart';

void main() {
  runApp(homepage());
}

class homepage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<homepage> {
  bool _isDarkTheme = true;

  ThemeData _lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.lightBlue.shade200,
  );

  ThemeData _darkTheme = ThemeData.dark();

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData currentTheme = _isDarkTheme ? _darkTheme : _lightTheme;

    return MaterialApp(
      theme: currentTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text(''),
          actions: [
            IconButton(
              icon: Icon(Icons.wb_sunny),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 0,
              ), // Adjust the space above the image
              Container(
                child: Center(
                  child: Image.asset(
                    'assets/images/123logo.png',
                    height: 300,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: RawMaterialButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      singleQR(currentTheme: currentTheme),
                                ),
                              );
                            },
                            elevation: 2.0,
                            fillColor: Colors.white,
                            child: Icon(
                              Symbols.qr_code_2,
                              size: 30.0,
                              color: Colors.black, // Set the color of the icon
                            ),
                            padding: EdgeInsets.all(15.0),
                            shape: CircleBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate Single QR',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(width: 20), // Adjust the horizontal distance
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: RawMaterialButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      rangeQR(currentTheme: currentTheme),
                                ),
                              );
                            },
                            elevation: 2.0,
                            fillColor: Colors.white,
                            child: Icon(
                              Symbols.arrow_range,
                              size: 30.0,
                              color: Colors.black, // Set the color of the icon
                            ),
                            padding: EdgeInsets.all(15.0),
                            shape: CircleBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate QR Range',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Adjust the vertical distance
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: RawMaterialButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      targetQR(currentTheme: currentTheme),
                                ),
                              );
                            },
                            elevation: 2.0,
                            fillColor: Colors.white,
                            child: Icon(
                              Symbols.qr_code_2_add,
                              size: 30.0,
                              color: Colors.black, // Set the color of the icon
                            ),
                            padding: EdgeInsets.all(15.0),
                            shape: CircleBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate Multiple QR',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(width: 20), // Adjust the horizontal distance
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: RawMaterialButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      readCSV(currentTheme: currentTheme),
                                ),
                              );
                            },
                            elevation: 2.0,
                            fillColor: Colors.white,
                            child: Icon(
                              Symbols.csv,
                              size: 30.0,
                              color: Colors.black, // Set the color of the icon
                            ),
                            padding: EdgeInsets.all(15.0),
                            shape: CircleBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate from CSV',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
