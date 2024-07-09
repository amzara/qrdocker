import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:super_clipboard/super_clipboard.dart';

class singleQR extends StatefulWidget {
  final ThemeData currentTheme;

  singleQR({required this.currentTheme});

  @override
  _singleQRState createState() => _singleQRState();
}

class _singleQRState extends State<singleQR> {
  late ThemeData _currentTheme;
  final ThemeData _lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: Colors.cyan.shade50,
  );
  final ThemeData _darkTheme = ThemeData.dark();

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

  TextEditingController extController = TextEditingController();
  TextEditingController domainController =
      TextEditingController(text: 'trp.uc.dotdashtech.com');
  String qrCodeUrl = '';
  String apiResponse = '';
  bool isQRGenerated = false;

  Future<void> fetchData(int extension, String domain) async {
    String url = 'http://10.16.1.21:81/crp2.php?ext=$extension&domain=$domain';
    try {
      var response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'text/plain'});
      if (response.statusCode == 200) {
        setState(() {
          apiResponse = response.body;
          qrCodeUrl = newCustomFunction(apiResponse) ?? '';
          isQRGenerated = true;
        });
      } else {
        // Show snackbar indicating extension does not exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extension $extension does not exist.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show snackbar indicating an error occurred
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while fetching data.'),
          duration: Duration(seconds: 2),
        ),
      );
      print('Error fetching data: $e');
    }
  }

  String? newCustomFunction(String? html) {
    // MODIFY CODE ONLY BELOW THIS LINE

    // Find the index of 'src' attribute
    int? srcIndex = html!.indexOf('src=');

    // If 'src' attribute is found
    if (srcIndex != null && srcIndex != -1) {
      // Move the index to the start of the URL
      int urlStartIndex = srcIndex + 5; // 5 is the length of 'src='

      // Find the closing quote of the URL
      int? urlEndIndex = html.indexOf("'", urlStartIndex);
      if (urlEndIndex == null || urlEndIndex == -1) {
        urlEndIndex = html.indexOf('"', urlStartIndex);
      }

      // Extract the URL if urlEndIndex is not null
      if (urlEndIndex != null && urlEndIndex != -1) {
        String imageUrl = html.substring(urlStartIndex, urlEndIndex);
        // Append the base URL
        return "http://10.16.1.21:81/$imageUrl";
      }
    }

    // If 'src' attribute is not found or URL extraction fails, return null
    return null;

    // MODIFY CODE ONLY ABOVE THIS LINE
  }

  void generateQRCodeAndPDF() async {
    String domain = domainController.text;
    int extension = int.tryParse(extController.text) ?? 0;
    if (extension != 0) {
      await fetchData(extension, domain);
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

  Future<void> downloadImage(String imageUrl, int extension) async {
    try {
      final Uint8List? data = await _readImageBytes(imageUrl);
      final html.Blob blob = html.Blob([data]);
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

  Future<void> generatePdf() async {
    try {
      if (qrCodeUrl.isNotEmpty) {
        // Create a new PDF document
        PdfDocument document = PdfDocument();
        final double qrCodeWidth = 300;
        final double qrCodeHeight = 300;
        final double labelOffset = 20;

        // Load image data into PDF bitmap object
        var response = await http.get(Uri.parse(qrCodeUrl));
        var data = response.bodyBytes;
        PdfBitmap image = PdfBitmap(data);

        double centerX =
            (document.pages.add().getClientSize().width - qrCodeWidth) / 2;
        double centerY =
            (document.pages[0].getClientSize().height - qrCodeHeight) / 2;

        // Draw image on the page graphics
        document.pages[0].graphics.drawImage(
          image,
          Rect.fromLTWH(centerX, centerY, qrCodeWidth, qrCodeHeight),
        );

        double labelX = centerX + 110;
        double labelY = centerY + qrCodeHeight + labelOffset;

        // Add text label indicating the extension number
        document.pages[0].graphics.drawString(
          'Extension: ${extController.text}',
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(
            labelX,
            labelY,
            qrCodeWidth,
            20,
          ), // Adjust position and size as needed
        );

        // Save the document
        final List<int> bytes = await document.save();
        // Dispose the document
        document.dispose();

        // Download the PDF
        downloadPdf(Uint8List.fromList(bytes));
      } else {
        print('No QR code URL available to generate PDF.');
      }
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  Future<void> copyImageToClipboard(String imageUrl) async {
    final bytes = await _readImageBytes(imageUrl);
    if (bytes != null) {
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem(suggestedName: 'QRCode.png');
        item.add(Formats.png(bytes));
        await clipboard.write([item]);
        print('Image copied to clipboard');
      } else {
        print('Clipboard is not available on this platform');
      }
    } else {
      print('Failed to read image');
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
      home: Scaffold(
        appBar: AppBar(
          title: Text('Generate Single QR'),
          actions: [
            IconButton(
              icon: Icon(Icons.wb_sunny),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextFormField(
                      controller: extController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Extension'),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: domainController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(labelText: 'Domain'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: generateQRCodeAndPDF,
                    child: Text('Generate QR Code'),
                  ),
                  SizedBox(height: 20),
                  if (qrCodeUrl.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'QR Code:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Image.network(
                          qrCodeUrl,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                copyImageToClipboard(qrCodeUrl);
                              },
                              icon: Icon(Icons.content_copy),
                              tooltip: 'Copy to Clipboard',
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              onPressed: generatePdf,
                              icon: Icon(Icons.picture_as_pdf),
                              tooltip: 'Export as PDF',
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              onPressed: () {
                                downloadImage(qrCodeUrl,
                                    int.tryParse(extController.text) ?? 0);
                              },
                              icon: Icon(Icons.file_download),
                              tooltip: 'Download Image',
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
