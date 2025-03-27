import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('messages');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: ChatExpenseScreen(),
    );
  }
}

class ChatExpenseScreen extends StatefulWidget {
  const ChatExpenseScreen({super.key});

  @override
  _ChatExpenseScreenState createState() => _ChatExpenseScreenState();
}

class _ChatExpenseScreenState extends State<ChatExpenseScreen> {
  final Box _messageBox = Hive.box('messages');
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      messages.addAll(_messageBox.values.map((e) => Map<String, dynamic>.from(e)).toList());
    });
  }

  // Function xử lý nhập liệu
  void _processMessage(String input) {
    List<String> parts = input.split(RegExp(r"[,\s]+")); // Tách theo dấu phẩy hoặc khoảng trắng
    if (parts.length < 2) return;

    String action = parts[0].toLowerCase(); // Lấy hành động (mua, bán...)
    String description = parts.sublist(1, parts.length - 1).join(" "); // Tên giao dịch
    int? amount = _parseAmount(parts.last); // Tách số tiền

    if (amount != null) {
      final message = {
        "text": input,
        "isMe": true,
        "action": action,
        "description": description,
        "amount": amount,
        "time": DateFormat('HH:mm').format(DateTime.now())
      };
      setState(() {
        messages.insert(0, message);
        _messageBox.add(message);
      });
      _controller.clear();
    }
  }

  // Chuyển đổi số tiền từ "10k" -> 10000
  int? _parseAmount(String amountText) {
    amountText = amountText.toLowerCase().replaceAll("k", "000").replaceAll("tr", "000000");
    return int.tryParse(amountText);
  }

  void _editMessage(int index) {
    // Logic to edit the message
    // For example, you can pre-fill the input field with the message text
    _controller.text = messages[index]["text"];
    setState(() {
      messages.removeAt(index);
    });
  }

  void _deleteMessage(int index) {
    setState(() {
      _messageBox.deleteAt(index);
      messages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Thu Chi"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                if (_searchQuery.isNotEmpty &&
                    !message["text"].toLowerCase().contains(_searchQuery)) {
                  return Container(); // Skip non-matching messages
                }
                return ChatBubble(
                  text: message["text"],
                  isMe: message["isMe"],
                  action: message["action"],
                  description: message["description"],
                  amount: message["amount"],
                  time: message["time"],
                  onEdit: () => _editMessage(index),
                  onDelete: () => _deleteMessage(index),
                );
              },
            ),
          ),
          // Ô nhập tin nhắn
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Nhập: mua gạo, 50k",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onSubmitted: (value) {
                        _processMessage(value);
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () => _processMessage(_controller.text),
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.send, color: Colors.white),
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

// Widget Bong bóng chat
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String action;
  final String description;
  final int amount;
  final String time;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.action,
    required this.description,
    required this.amount,
    required this.time,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Chỉnh sửa'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Xoá'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$action: $description",
                  style: TextStyle(color: isMe ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
                Text(
                  "💰 ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}",
                  style: TextStyle(color: isMe ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: isMe ? 10 : 0, left: isMe ? 0 : 10),
            child: Text(
              time,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
