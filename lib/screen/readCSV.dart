import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';

class readCSV extends StatefulWidget {
  final ThemeData currentTheme;

  readCSV({required this.currentTheme});

  @override
  _CSVReaderState createState() => _CSVReaderState();
}

class _CSVReaderState extends State<readCSV> {
  late ThemeData _currentTheme;
  ThemeData _lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.cyan.shade50,
  );
  ThemeData _darkTheme = ThemeData.dark();

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.currentTheme;
  }

  void _toggleTheme() {
    setState(() {
      _currentTheme = _currentTheme == _lightTheme ? _darkTheme : _lightTheme;
    });
  }

  List<int> _selectedExtensions = [];
  List<int> _successfulExtensions = [];
  List<String> qrCodes = [];
  String apiResponse = '';
  String? _uploadedFileName;
  bool displayQR = false;

  Future<void> _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String csvText = String.fromCharCodes(result.files.first.bytes!);
      _processCsv(csvText);
      setState(() {
        _uploadedFileName = result.files.single.name;
      });
    }
  }

  List<int> _extractNumbers(String csvText) {
    List<String> lines = csvText.split('\n');
    List<int> numbers = [];
    for (int i = 1; i < lines.length; i++) {
      List<String> row = lines[i].split(',');
      if (row.isNotEmpty && row.length > 0) {
        int number = int.tryParse(row[0]) ?? 0;
        if (number != 0) {
          numbers.add(number);
        }
      }
    }
    return numbers;
  }

  void _processCsv(String csvText) {
    List<int> extensions = _extractNumbers(csvText);
    setState(() {
      _selectedExtensions = extensions;
    });
  }

  Future<void> fetchData(int extension, String domain) async {
    String url = 'http://10.16.1.21:81/crp2.php?ext=$extension&domain=$domain';
    var response = await http.get(Uri.parse(url));
    setState(() {
      apiResponse = response.body;
      String? extractedImgUrl = newCustomFunction(apiResponse);
      if (extractedImgUrl != null) {
        setState(() {
          qrCodes.add(extractedImgUrl);
          _successfulExtensions.add(extension); // Store successful extension
        });
      }
    });
  }

  String? newCustomFunction(String? html) {
    int? srcIndex = html!.indexOf('src=');
    if (srcIndex != null && srcIndex != -1) {
      int urlStartIndex = srcIndex + 5;
      int? urlEndIndex = html.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html.indexOf('"', urlStartIndex);
      }
      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        return "http://10.16.1.21:81/$imageUrl";
      }
    }
    return null;
  }

  Future<void> generateQRCodes() async {
    if (_selectedExtensions.isNotEmpty) {
      _successfulExtensions.clear(); // Clear previous successful extensions
      qrCodes.clear(); // Clear previous QR codes
      for (int extension in _selectedExtensions) {
        await fetchData(extension, "trp.uc.dotdashtech.com");
      }
      if (_successfulExtensions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No available extensions.'),
          ),
        );
      }
      displayQR = true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a CSV file first.'),
        ),
      );
    }
  }

  Future<void> generatePdf() async {
    try {
      if (_selectedExtensions.isNotEmpty && qrCodes.isEmpty) {
        // If selectedExtensions is not empty and qrCodes is empty, generate QR codes implicitly
        await generateQRCodes();
      }

      if (qrCodes.isNotEmpty) {
        // Create a new PDF document
        PdfDocument document = PdfDocument();

        final double qrCodeWidth = 300;
        final double qrCodeHeight = 300;
        final double labelOffset = 20; // Adjust the offset as needed

        // Iterate through all QR codes and add them to the PDF
        for (int i = 0; i < qrCodes.length; i++) {
          // Use qrCodes.length as limit
          String imageUrl = qrCodes[i];

          // Load image data into PDF bitmap object
          var response = await http.get(Uri.parse(imageUrl));
          var data = response.bodyBytes;
          PdfBitmap image = PdfBitmap(data);

          // Add new page for each QR code
          PdfPage page = document.pages.add();

          // Calculate position for centering the QR code and text label
          double centerX = (page.getClientSize().width - qrCodeWidth) / 2;
          double centerY = (page.getClientSize().height - qrCodeHeight) / 2;

          // Draw image on the page graphics centered
          page.graphics.drawImage(
            image,
            Rect.fromLTWH(centerX, centerY, qrCodeWidth, qrCodeHeight),
          );

          // Calculate position for centering the text label below the QR code
          double labelX = centerX;
          double labelY = centerY + qrCodeHeight + labelOffset;

          // Add text label indicating the extension number
          page.graphics.drawString(
            'Extension: ${_successfulExtensions[i]}',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            bounds: Rect.fromLTWH(
              labelX,
              labelY,
              qrCodeWidth,
              20,
            ), // Adjust position and size as needed
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }

        // Save the document
        final List<int> bytes = await document.save();
        // Dispose the document
        document.dispose();

        // Download the PDF
        downloadPdf(Uint8List.fromList(bytes));
      } else {
        print('No QR codes available to generate PDF.');
      }
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  Future<void> downloadPdf(Uint8List bytes) async {
    try {
      final html.Blob blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "output.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }

  Future<void> copyImageToClipboard(String imageUrl) async {
    final html.ImageElement imageElement = html.ImageElement(src: imageUrl);
    await html.document.body!.append(imageElement);
    html.document.execCommand('copy');
    imageElement.remove();
    print('Image copied to clipboard');
  }

  Future<void> downloadImage(String imageUrl, int extension) async {
    try {
      final Uint8List? data = await _readImageBytes(imageUrl);
      final html.Blob blob = html.Blob([data!]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
            "download", "qr_code_$extension.png") // Set filename dynamically
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  Future<Uint8List?> _readImageBytes(String imageUrl) async {
    try {
      // Perform a GET request to fetch the image data
      final response = await http.get(Uri.parse(imageUrl));

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Convert the response body (image data) to bytes
        return response.bodyBytes;
      } else {
        print('Failed to fetch image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error reading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _currentTheme,
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('QR Code Generator from CSV'),
          actions: [
            IconButton(
              icon: Icon(Icons.wb_sunny),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _openFilePicker,
                  icon: Icon(Icons.folder_open),
                  label: Text('Select CSV File'),
                ),
                SizedBox(height: 10),
                if (_uploadedFileName != null)
                  Center(
                    child: Text(
                      'Uploaded File: $_uploadedFileName',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: generateQRCodes,
                      icon: Icon(Icons.qr_code),
                      label: Text('Generate QR Codes'),
                    ),
                    ElevatedButton.icon(
                      onPressed: generatePdf,
                      icon: Icon(Icons.picture_as_pdf),
                      label: Text('Generate PDF'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (displayQR == true)
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: List.generate(
                      qrCodes.length,
                      (index) => Column(
                        children: [
                          Text(
                            'Extension: ${_successfulExtensions[index]}', // Use successful extension number as label
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Image.network(
                            qrCodes[index],
                            width: 200,
                            height: 200,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  copyImageToClipboard(qrCodes[index]);
                                },
                                icon: Icon(Icons.content_copy),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                onPressed: () {
                                  downloadImage(qrCodes[index],
                                      _successfulExtensions[index]);
                                },
                                icon: Icon(Icons.download),
                              ),
                            ],
                          ),
                        ],
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
