import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:instagram_flutter/providers/user_provider.dart';
import 'package:instagram_flutter/screens/image_preview_screen.dart';
import 'package:instagram_flutter/utils/utils.dart';
import 'package:provider/provider.dart';

class GeneratedImagePreviewScreen extends StatefulWidget {
  const GeneratedImagePreviewScreen({super.key});

  @override
  State<GeneratedImagePreviewScreen> createState() =>
      _GeneratedImagePreviewScreenState();
}

class _GeneratedImagePreviewScreenState
    extends State<GeneratedImagePreviewScreen> {
  late TextEditingController _controller;

  bool isLoading = false;
  String? resultUrl;
  bool isButtonEnabled = false;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> generateImage() async {
    final String prompt =
        _controller.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (prompt.isEmpty) return;

    setState(() {
      isLoading = true;
      resultUrl = null;
    });

    final queryParams = {
      'prompt': prompt,
      'uid': Provider.of<UserProvider>(context, listen: false).getUser!.uid,
    };

    final String baseUrl = dotenv.get('BASE_URL', fallback: '');

    try {
      final uri =
          Uri.parse('$baseUrl/generate').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          isButtonEnabled = true;
          resultUrl = data['data']['media'][0]['url'];
        });
      } else if (response.statusCode == 429) {
        showSnackBar(context,
            "You are generating images too fast. Please try again later.");
      } else {
        showSnackBar(context, "Failed to generate image");
      }
    } catch (_) {
      showSnackBar(context, "Something went wrong");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectGeneratedImage() async {
    if (resultUrl == null) return;

    try {
      final response = await http.get(Uri.parse(resultUrl!));

      if (response.statusCode == 200) {
        Uint8List bytes = response.bodyBytes;

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(file: bytes),
          ),
        );
      }
    } catch (_) {
      showSnackBar(context, "Failed to load image");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Generate an Image",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Prompt Input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s{2,}'))
                    ],
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Describe your image...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// 🔹 Generate Button
                Expanded(
                  // non rounded corners button
                  child: ElevatedButton(
                    onPressed: isLoading ? null : generateImage,
                    child: const Text(
                      "Generate",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔹 Loading
            if (isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                  ),
                ),
              )

            /// 🔹 Image Result
            else if (resultUrl != null)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: null,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            resultUrl!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// 🔹 Post Button
                    if (isButtonEnabled)
                      SizedBox(
                        child: TextButton(
                          onPressed: () {
                            _selectGeneratedImage();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            "Continue with this image",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
