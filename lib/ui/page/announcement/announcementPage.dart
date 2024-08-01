import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../helper/utility.dart';
import '../../../state/feedState.dart';
import '../../../widgets/customWidgets.dart';
import '../../../widgets/newWidget/customLoader.dart';
import '../../../widgets/newWidget/emptyList.dart';
import '../../../widgets/newWidget/title_text.dart';
import '../../theme/theme.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage(
      {Key? key, required this.scaffoldKey, this.refreshIndicatorKey})
      : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool showFloatingButton = false;

  @override
  void initState() {
    String? email = currentUser?.email;
    showFloatingButton = currentUser != null &&
        currentUser?.email != null &&
        email!.endsWith('@stf.ammusted.com');
    super.initState();
  }

  Widget _floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showAddAnnouncementDialog(context);
      },
      child: customIcon(
        context,
        icon: AppIcon.fabTweet,
        isTwitterIcon: true,
        iconColor: Theme.of(context).colorScheme.onPrimary,
        size: 25,
      ),
    );
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    File? _selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      maxLines: 5,
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Announcement',
                        border: InputBorder.none
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: const Text('Select Image'),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8.0),
                      Image.file(_selectedImage!, height: 100, width: 100),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Description cannot be empty')),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const CustomScreenLoader(
                          height: double.infinity,
                          width: double.infinity,
                          backgroundColor: Colors.white,
                        );
                      },
                    );

                    String? imageUrl;
                    if (_selectedImage != null) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('announcementImages')
                          .child('${DateTime.now().toIso8601String()}.jpg');

                      await ref.putFile(_selectedImage!);
                      imageUrl = await ref.getDownloadURL();
                    }

                    await _addAnnouncement(descriptionController.text, imageUrl);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addAnnouncement(String description, String? imageUrl) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('announcement').push();

    Map<String, dynamic> announcement = {
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
      'imagePath': imageUrl,
      'user': {
        'displayName': currentUser?.displayName ?? 'Anonymous',
        'isVerified': false,
        'profilePic': currentUser?.photoURL ?? '',
        'userId': currentUser?.uid ?? '',
      },
    };

    await ref.set(announcement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: showFloatingButton ? _floatingActionButton(context) : null,
      backgroundColor: TwitterColor.mystic,
      body: SafeArea(
        child: SizedBox(
          height: context.height,
          width: context.width,
          child: RefreshIndicator(
            key: widget.refreshIndicatorKey,
            onRefresh: () async {
              /// refresh home page feed
              var feedState = Provider.of<FeedState>(context, listen: false);
              feedState.getDataFromDatabase();
              return Future.value(true);
            },
            child: _FeedPageBody(
              refreshIndicatorKey: widget.refreshIndicatorKey,
              scaffoldKey: widget.scaffoldKey,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedPageBody extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const _FeedPageBody(
      {Key? key, required this.scaffoldKey, this.refreshIndicatorKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref().child('announcement').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomScreenLoader(
            height: double.infinity,
            width: double.infinity,
            backgroundColor: Colors.white,
          );
        } else if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<FeedModel> list = [];
          data.forEach((key, data) => list.add(FeedModel.fromJson(data, key)));

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                floating: true,
                elevation: 0,
                leading: Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFF5E0C0C),),
                      onPressed: () {
                        scaffoldKey.currentState!.openDrawer();
                      },
                    );
                  },
                ),
                title: const Text("Announcements"),
                centerTitle: true,
                iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0.0),
                  child: Container(
                    color: Colors.grey.shade200,
                    height: 1.0,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return TweetWidget(feedModel: list[index]);
                  },
                  childCount: list.length,
                ),
              ),
            ],
          );
        } else {
          return const EmptyList(
            'No Announcements added yet',
            subTitle:
            'When new Announcements are added, they\'ll show up here \n Tap Announcements button to add new one',
          );
        }
      },
    );
  }
}

class TweetWidget extends StatelessWidget {
  final FeedModel feedModel;

  const TweetWidget({Key? key, required this.feedModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return GestureDetector(
      onLongPress: () {
        if (feedModel.user.userId == currentUser?.uid) {
          _showDeleteDialog(context, feedModel);
        }
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(feedModel.user.profilePic),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TitleText(currentUser!.displayName!,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              overflow: TextOverflow.ellipsis),

                          const SizedBox(width: 3),

                          currentUser.emailVerified
                              ? customIcon(
                            context,
                            icon: AppIcon.blueTick,
                            isTwitterIcon: true,
                            iconColor: AppColor.primary,
                            size: 13,
                            paddingIcon: 3,
                          )
                              : const SizedBox(width: 0),
                          SizedBox(
                            width: currentUser.emailVerified ? 5 : 0,
                          ),
                        ],
                      ),
                      customText(
                        Utility.getChatTime(feedModel.createdAt).toString(),
                        style:
                        TextStyles.userNameStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                  feedModel.description,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w300),
              ),
              if (feedModel.imageUrl != null) ...[
                const SizedBox(height: 8.0),
                Image.network(feedModel.imageUrl!),
              ],
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FeedModel feedModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text('Are you sure you want to delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteAnnouncement(feedModel.key);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(String key) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('announcement').child(key);
    await ref.remove();
  }
}

class FeedModel {
  String key;
  String description;
  String createdAt;
  String? imageUrl;
  UserModel user;

  FeedModel({
    required this.key,
    required this.description,
    required this.createdAt,
    this.imageUrl,
    required this.user,
  });

  factory FeedModel.fromJson(Map<dynamic, dynamic> json, String key) {
    return FeedModel(
      key: key,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? '',
      imageUrl: json['imagePath'],
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}

class UserModel {
  String displayName;
  bool isVerified;
  String profilePic;
  String userId;

  UserModel({
    required this.displayName,
    required this.isVerified,
    required this.profilePic,
    required this.userId,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) {
    return UserModel(
      displayName: json['displayName'] ?? '',
      isVerified: json['isVerified'] ?? false,
      profilePic: json['profilePic'] ?? '',
      userId: json['userId'] ?? '',
    );
  }
}
