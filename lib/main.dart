import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB82Pj-Qcv05Wvdr941nnfAOwj1TU6FkUU",
      authDomain: "one-14aef.firebaseapp.com",
      databaseURL: "https://one-14aef-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "one-14aef",
      storageBucket: "one-14aef.firebasestorage.app",
      messagingSenderId: "570713727151",
      appId: "1:570713727151:web:0dae8e88a6ecdda3b3b45a",
      measurementId: "G-FBDVL0H7PJ",
    ),
  );
  
  runApp(const OneChatApp());
}

class OneChatApp extends StatelessWidget {
  const OneChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'One Chat',
      theme: ThemeData(
        primaryColor: const Color(0xFF075E54),
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF075E54),
          elevation: 1,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF25D366),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF075E54))),
          );
        }
        if (snapshot.hasData) {
          return const HomeLayout();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saari details sahi se bharein!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Save Username to Firebase Database
        if (userCred.user != null) {
          DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
          await userRef.child(userCred.user!.uid).set({
            'username': username,
            'email': email,
          });
          await userRef.child("usernames/$username").set(userCred.user!.uid);
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication Failed")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF075E54),
                child: Icon(Icons.chat, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to One Chat',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF075E54)),
              ),
              const SizedBox(height: 30),
              if (!_isLogin) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Choose Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF075E54))
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                        ),
                        onPressed: _submitAuth,
                        child: Text(
                          _isLogin ? 'Login' : 'Create Account',
                          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Account nahi hai? Sign Up karein" : "Pehle se account hai? Login karein",
                  style: const TextStyle(color: Color(0xFF075E54)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  void _openNewChatDialog() {
    final TextEditingController searchUsernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start New Chat"),
        content: TextField(
          controller: searchUsernameController,
          decoration: const InputDecoration(
            hintText: "Enter Receiver Username",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
            onPressed: () {
              String targetUser = searchUsernameController.text.trim().toLowerCase();
              if (targetUser.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(targetUsername: targetUser),
                  ),
                );
              }
            },
            child: const Text("Chat", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('One Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _openNewChatDialog,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == "Logout") {
                  FirebaseAuth.instance.signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: "Logout", child: Text("Logout", style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.groups)),
              Tab(text: "CHATS"),
              Tab(text: "STATUS"),
              Tab(text: "CALLS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text("Communities Screen")),
            ChatsTab(onNewChatPressed: _openNewChatDialog),
            const Center(child: Text("Status Updates")),
            const Center(child: Text("No Recent Calls")),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openNewChatDialog,
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}

class ChatsTab extends StatelessWidget {
  final VoidCallback onNewChatPressed;
  const ChatsTab({super.key, required this.onNewChatPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("Koi chat nahi hai. Floating button (+) dabakar Username se chat shuru karein!",
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
            onPressed: onNewChatPressed,
            child: const Text("Start Chat with Username", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String targetUsername;
  const ChatDetailScreen({super.key, required this.targetUsername});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _myUsername = '';
  String _chatRoomId = '';

  @override
  void initState() {
    super.initState();
    _setupChatRoom();
  }

  Future<void> _setupChatRoom() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseEvent event = await FirebaseDatabase.instance.ref().child("users/${currentUser.uid}/username").once();
      if (event.snapshot.value != null) {
        _myUsername = event.snapshot.value.toString();
      } else {
        _myUsername = currentUser.email!.split('@')[0];
      }

      // Generate Unique Chat Room ID for two users
      List<String> ids = [_myUsername, widget.targetUsername];
      ids.sort();
      setState(() {
        _chatRoomId = ids.join("_");
      });
    }
  }

  void _sendMessage({String? imageUrl}) {
    if (_chatRoomId.isEmpty) return;
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child("chats/$_chatRoomId");

    if (_messageController.text.trim().isNotEmpty || imageUrl != null) {
      dbRef.push().set({
        'sender': _myUsername,
        'message': _messageController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _messageController.clear();
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        File file = File(pickedFile.path);
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName.jpg');
        
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        _sendMessage(imageUrl: downloadUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 70,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 24, color: Colors.white),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        title: Text(widget.targetUsername, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: _chatRoomId.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF075E54)))
          : Column(
              children: [
                if (_isUploading) const LinearProgressIndicator(color: Color(0xFF075E54)),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseDatabase.instance.ref().child("chats/$_chatRoomId").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                        return const Center(child: Text("No messages yet. Say Hi!"));
                      }
                      Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      List<dynamic> list = map.values.toList();
                      list.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          bool isMe = list[index]['sender'] == _myUsername;
                          String? imgUrl = list[index]['imageUrl'];
                          String msg = list[index]['message'] ?? '';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imgUrl != null && imgUrl.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(imgUrl, width: 200, fit: BoxFit.cover),
                                      ),
                                    ),
                                  if (msg.isNotEmpty)
                                    Text(msg, style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                                onPressed: () {},
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: "Message",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file, color: Colors.grey),
                                onPressed: () => _pickAndUploadImage(ImageSource.gallery),
                              ),
                              IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.grey),
                                onPressed: () => _pickAndUploadImage(ImageSource.camera),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF00A884),
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
