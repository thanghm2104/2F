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
  final List<String> expenseKeywords = [
    "mua", "trả tiền", "đã mua", "chi", "tiêu", "thanh toán", "đầu tư", "trả nợ",
    "đóng tiền", "nạp tiền", "thu tiền", "vay", "ăn uống", "mua đồ", "chợ",
    "siêu thị", "điện", "nước", "gas", "wifi", "tiền nhà", "thuê nhà", "xăng xe",
    "taxi", "grab", "sửa xe", "bảo dưỡng xe", "vé tàu", "vé xe", "xem phim",
    "du lịch", "chơi game", "karaoke", "ăn hàng", "cafe", "học phí", "sách vở",
    "khóa học", "tiền học", "học thêm", "bệnh viện", "thuốc", "khám bệnh",
    "bảo hiểm", "viện phí", "trả góp", "trả lãi", "thanh toán thẻ", "đóng tiền vay",
    "từ thiện", "quà tặng", "biếu tiền", "mất tiền", "phạt"
  ];

  final List<String> incomeKeywords = [
    "lương", "thu nhập", "tiền về", "nhận", "làm thêm", "thu", "hoàn", "bán hàng",
    "doanh thu", "tiền hàng", "lợi nhuận", "tiền lời", "cổ tức", "lãi suất",
    "tiền lãi", "lợi nhuận đầu tư", "chứng khoán", "trái phiếu", "thưởng",
    "thưởng Tết", "trợ cấp", "phụ cấp", "hỗ trợ", "tiền thưởng", "biếu", "tặng",
    "lì xì", "tiền mừng", "nhận quà", "hỗ trợ tài chính", "chuyển khoản vào",
    "refund", "hoàn tiền"
  ];


  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      messages.addAll(_messageBox.values.map((e) {
        final message = Map<String, dynamic>.from(e);
        if (message["date"] == null) {
          message["date"] = DateTime.now();
        }
        return message;
      }).toList());
    });
  }

  void _processMessage(String input) {
    List<String> parts = input.split(RegExp(r"[,\s]+"));
    if (parts.length < 2) return;

    String description = parts.sublist(0, parts.length - 1).join(" ");
    int? amount = _parseAmount(parts.last);

    if (amount != null) {
      String category = _categorizeMessage(input);

      final message = {
        "text": input,
        "isMe": true,
        "action": category,
        "description": description,
        "amount": amount,
        "time": DateFormat('HH:mm').format(DateTime.now()),
        "date": DateTime.now(),
      };
      setState(() {
        messages.insert(0, message);
        _messageBox.add(message);
      });
      _controller.clear();
    }
  }

  String _categorizeMessage(String input) {
    input = input.toLowerCase();
    for (var keyword in expenseKeywords) {
      if (input.contains(keyword)) {
        return "chi";
      }
    }
    for (var keyword in incomeKeywords) {
      if (input.contains(keyword)) {
        return "thu";
      }
    }
    return "unknown";
  }

  int? _parseAmount(String amountText) {
    amountText = amountText.toLowerCase().replaceAll("k", "000").replaceAll("tr", "000000");
    return int.tryParse(amountText.replaceAll(RegExp(r'[^\d]'), ''));
  }

  void _editMessage(int index) {
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

  Map<String, int> _calculateSummary() {
    int totalIncome = 0;
    int totalExpense = 0;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    for (var message in messages) {
      DateTime? messageDate = message["date"];
      if (messageDate != null && messageDate.isAfter(startOfDay)) {
        if (message["action"] == "thu") {
          totalIncome += (message["amount"] as int);
        } else if (message["action"] == "chi") {
          totalExpense += (message["amount"] as int);
        }
      }
    }

    return {
      "totalIncome": totalIncome,
      "totalExpense": totalExpense,
    };
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> summary = _calculateSummary();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat Thu Chi"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.attach_money),
              onPressed: () {
                // Hiển thị tổng thu chi hôm nay
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Tổng thu chi hôm nay"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Tổng thu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(summary['totalIncome']).replaceAll('.', ',')}"),
                          Text("Tổng chi: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(summary['totalExpense']).replaceAll('.', ',')}"),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("Đóng"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
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
                    return Container();
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          filled: true,
                          fillColor: Colors.white,
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  "💰 ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount).replaceAll('.', ',')}",
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
