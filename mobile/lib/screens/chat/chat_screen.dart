import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:mobile/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mobile/screens/menu/menu_drawer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _sessionId = '';
  int _sessionCounter = 0;
  String? _currentMessageId;
  String? _feedbackText;
  bool _showMenu = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false;
  String _currentVoiceText = '';

  void _toggleMenu() {
    setState(() => _showMenu = !_showMenu);
  }

  // Add voice recording methods
  void _startRecording() async {
    if (await _speech.hasPermission) {
      setState(() => _isRecording = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _currentVoiceText = result.recognizedWords;
            _messageController.text = _currentVoiceText;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  void _stopRecording() async {
    await _speech.stop();
    setState(() => _isRecording = false);
    // Optional: Send text to GPT API here
  }

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeSession();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final themeMode = ref.read(themeProvider);
    //   MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
    //     SnackBar(
    //       content: Text('Theme: ${themeMode.toString().split('.').last}'),
    //       duration: const Duration(seconds: 2),
    //     ),
    //   );
    // });
  }

  void _initializeSpeech() async {
    await _speech.initialize();
  }

  void _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionCounter = prefs.getInt('sessionCounter') ?? 0;
      _sessionId = _generateSessionId();
    });
  }

  String _generateSessionId() {
    final now = DateTime.now();
    return '${DateFormat('dd-MM-yyyy').format(now)}-system_$_sessionCounter';
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _isTyping) {
      return; // Prevent multiple submissions
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    if (_messages.isEmpty || _messages.last['isUser'] != true) {
      setState(() {
        _messages.add({
          'text': message,
          'isUser': true,
          'timestamp': DateTime.now(),
        });
      });
    }

    setState(() => _isTyping = true);

    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('email') ?? '';

      final dio = Dio();

      final response = await dio.post(
        '${Env.baseUrl}/api/v1/chatbot/query',
        data: {
          'query': message,
          'userId': userId,
          'sessionId': _sessionId,
        },
      );

      final responseText = response.data['system']
          .toString()
          .replaceAll(RegExp(r'^"|"$'), ''); // Remove surrounding quotes

      setState(() {
        _isTyping = false;
        // Remove any existing typing indicator
        _messages.removeWhere((m) => m['text'] == null);
        _messages.add({
          'text': responseText,
          'isUser': false,
          'timestamp': DateTime.now(),
          'messageId': response.data['messageId'],
        });
        _currentMessageId = response.data['messageId'];
      });

      await prefs.setString('currentMessageId', _currentMessageId!);
      _scrollToBottom();
    } on DioException catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text':
              'Error: ${e.response?.data['message'] ?? 'Connection failed'}',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': 'Error: Please check your connection',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      _scrollToBottom();
    }
  }

  void _regenerateResponse(String messageId) async {
    if (_messages.isEmpty || _currentMessageId == null) return;

    setState(() => _isTyping = true);
    _scrollToBottom();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('email') ?? '';
      final messageId = prefs.getString('currentMessageId') ?? '';

      final dio = Dio();

      final response = await dio.post(
        '${Env.baseUrl}/api/v1/chatbot/regenerate',
        data: {
          'query': _messages.lastWhere((m) => m['isUser'])['text'],
          'userId': userId,
          'sessionId': _sessionId,
          'messageId': messageId, // Add messageId to reques
        },
      );

      final responseText =
          response.data['system'].toString().replaceAll(RegExp(r'^"|"$'), '');

      setState(() {
        _isTyping = false;
        _messages.add({
          'text': responseText,
          'isUser': false,
          'timestamp': DateTime.now(),
          'messageId': response.data['messageId'],
        });
        _currentMessageId = response.data['messageId'];
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to regenerate response')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _newChat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _messages.clear();
      _sessionCounter = (prefs.getInt('sessionCounter') ?? 0) + 1;
      _sessionId = _generateSessionId();
      prefs.setInt('sessionCounter', _sessionCounter);
    });
  }

  void _handleFeedback(String rating) async {
    if (rating == 'dislike') {
      showDialog(
        context: context,
        builder: (context) => Theme(
          data: Theme.of(context),
          child: AlertDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            title: Text(
              'Provide Feedback',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 10, // Initial height
                maxHeight: 300, // Max height before scrolling
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: TextField(
                    onChanged: (value) => _feedbackText = value,
                    maxLines: null, // Allows unlimited lines
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _sendReaction(rating);
                },
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      await _sendReaction(rating);
    }
  }

  Future<void> _sendReaction(String rating) async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();

    try {
      await dio.post(
        '${Env.baseUrl}/api/v1/chatbot/reaction',
        data: {
          'userId': prefs.getString('email'),
          'sessionId': _sessionId,
          'messageId': _currentMessageId,
          'rating': rating,
          'feedbackText': _feedbackText ?? '',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Changed from white

      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      //   foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      //   leading: IconButton(
      //     icon: const Icon(Icons.menu),
      //     onPressed: _toggleMenu,
      //   ),
      //   title: const Text('Genie'),
      //   actions: [
      //     IconButton(
      //       icon: Icon(
      //         Icons.refresh,
      //         color: Theme.of(context).iconTheme.color,
      //       ),
      //       onPressed: _newChat,
      //     ),
      //   ],
      // ),
      body: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _showMenu ? 0 : -MediaQuery.of(context).size.width * 0.75,
            width: MediaQuery.of(context).size.width * 0.75,
            top: 0,
            bottom: 0,
            child: const SettingsMenu(),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.translationValues(
              _showMenu ? MediaQuery.of(context).size.width * 0.70 : 0,
              0,
              0,
            ),
            child: Column(
              children: [
                Container(
                  height: kToolbarHeight + MediaQuery.of(context).padding.top,
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.menu_outlined),
                          onPressed: _toggleMenu),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Genie',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_comment_rounded,
                            color: Theme.of(context).iconTheme.color),
                        onPressed: _newChat,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _messages.isEmpty && !_isTyping
                          ? const Center(child: InitialChatView())
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: 0), // Add this

                              child: ListView.builder(
                                padding: EdgeInsets.only(
                                    top: 4), // Minimal top padding
                                controller: _scrollController,
                                itemCount:
                                    _messages.length + (_isTyping ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index < _messages.length) {
                                    final message = _messages[index];
                                    return ChatBubble(
                                      text: message['text'],
                                      isUser: message['isUser'],
                                      messageId:
                                          message['messageId'], // Add this line
                                      onCopy: () {
                                        Clipboard.setData(ClipboardData(
                                            text: message['text']));
                                        Fluttertoast.showToast(
                                          msg: "✅  Copied",
                                          toastLength: Toast.LENGTH_SHORT,
                                          gravity: ToastGravity.CENTER,
                                          backgroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color.fromARGB(
                                                      255, 80, 80, 80)
                                                  : const Color.fromARGB(
                                                      255, 24, 24, 24),
                                          textColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color.fromARGB(
                                                      255, 240, 240, 240)
                                                  : const Color.fromARGB(
                                                      255, 231, 231, 231),
                                          fontSize: 16.0,
                                        );
                                      },
                                      onRegenerate: message['isUser']
                                          ? null
                                          : () => _regenerateResponse(
                                              message['messageId']),
                                      onLike: () => _handleFeedback('like'),
                                      onDislike: () =>
                                          _handleFeedback('dislike'),
                                      // Add this new parameter
                                      isCurrentMessage:
                                          index == _messages.length - 1,
                                    );
                                  }
                                  return const TypingIndicator();
                                },
                              )),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Column(
                    children: [
                      if (_isRecording)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            _currentVoiceText.isEmpty
                                ? 'Listening...'
                                : _currentVoiceText,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                // Updated from symmetric
                                left: 8.0,
                                right: 8.0,
                                top: 8.0,
                                bottom: 16.0, // Reduced from 8.0 to 4.0
                              ), // Add left padding
                              child: TextField(
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16, // Increase from default 14
                                ),
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Message Genie...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 14.0,
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onLongPressStart: (_) {
                              HapticFeedback.vibrate(); // Initial vibration
                              _startRecording();
                            },
                            onLongPressEnd: (_) {
                              HapticFeedback.mediumImpact(); // Release feedback
                              _stopRecording();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? Colors.red
                                    : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isRecording ? Icons.mic : Icons.mic_none,
                                color: _isRecording
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(Icons.send,
                                color: _isTyping ? Colors.grey : Colors.blue,
                                size: 25),
                            padding: const EdgeInsets.all(8),
                            onPressed: _isTyping
                                ? null
                                : _sendMessage, // Disable when loading
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showMenu)
            GestureDetector(
              onTap: _toggleMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SettingsMenu(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class InitialChatView extends StatelessWidget {
  const InitialChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/genie_logo.png', width: 100),
        const SizedBox(height: 8),
        Text(
          'Hi, I\'m Genie',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        const SizedBox(height: 4),
        Text('How can I help you today?',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
      ],
    );
  }
}

// Replace entire ChatBubble class with this
class ChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? messageId; // Add this
  final VoidCallback onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final bool isCurrentMessage;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.messageId, // Add this
    required this.onCopy,
    required this.onRegenerate,
    required this.onLike,
    required this.onDislike,
    required this.isCurrentMessage,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isHovered = false;
  bool _isLiked = false;
  bool _isDisliked = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Align(
        alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                (widget.isUser ? 0.80 : 1), // User: 80%, Genie: 100%
            minWidth: MediaQuery.of(context).size.width * 0.25, // Minimum width
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isUser
                ? isDark
                    ? const Color.fromARGB(255, 49, 78, 110)
                    : const Color(0xFFE3F2FD)
                : isDark
                    ? Colors.black
                    : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: !widget.isUser && isDark
                ? Border.all(color: const Color.fromARGB(255, 0, 0, 0))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // In _ChatBubbleState build method
              if (!widget.isUser)
                Container(
                  margin: const EdgeInsets.only(
                      left: 0), // Reduced from 8// keep this to zero
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min, // Add this
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color.fromARGB(255, 41, 41, 41)
                                : const Color.fromARGB(255, 234, 234, 234),
                        backgroundImage:
                            AssetImage('assets/images/genie_logo.png'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.text,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 16, // Changed from default (was ~14)
                              ),
                            ),
                            if (widget.isCurrentMessage || _isHovered)
                              _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.isUser)
                Text(
                  widget.text,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16, // Changed from default (was ~14)
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12), // Reduced from 8.0
      child: Wrap(
        spacing: 4.0, // Reduced spacing between buttons
        // runSpacing: 2, // Reduced spacing between rows
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Copy button (always visible)
          _buildIconButton(
            icon: Icons.copy,
            onPressed: widget.onCopy,
            isActive: false,
          ),

          if (widget.isCurrentMessage) ...[
            _buildIconButton(
              icon: Icons.restart_alt_rounded,
              onPressed: widget.onRegenerate!,
              isActive: false,
            ),
            _buildIconButton(
              icon: Icons.thumb_up_alt_rounded,
              onPressed: () {
                setState(() {
                  _isLiked = !_isLiked;
                  if (_isLiked) _isDisliked = false;
                });
                widget.onLike();
              },
              isActive: _isLiked,
            ),
            _buildIconButton(
              icon: Icons.thumb_down_alt_rounded,
              onPressed: () {
                setState(() {
                  _isDisliked = !_isDisliked;
                  if (_isDisliked) _isLiked = false;
                });
                widget.onDislike();
              },
              isActive: _isDisliked,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // Minimal padding
        child: Icon(
          icon,
          size: 22, // Smaller icon size
          color: isActive
              ? Colors.lightBlue[400]
              : isDark
                  ? Colors.grey[400]
                  : Colors.grey[600],
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  int _visibleIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _visibleIndex = (_visibleIndex + 1) % 3;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(255, 41, 41, 41)
                : const Color.fromARGB(255, 234, 234, 234),
            backgroundImage: AssetImage('assets/images/genie_logo.png'),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(3, (index) {
              return AnimatedOpacity(
                opacity: index <= _visibleIndex ? 1.0 : 0.2,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
