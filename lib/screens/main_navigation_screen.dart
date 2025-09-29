import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'universal_matching_screen.dart';
import 'conversations_screen.dart';
import 'create_post_screen.dart';
import 'feed_screen.dart';
import 'profile_with_history_screen.dart';
import 'performance_debug_screen.dart';
import '../services/notification_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> 
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _unreadMessageCount = 0;

  final List<Widget> _screens = [
    const UniversalMatchingScreen(),
    const ConversationsScreen(),
    const CreatePostScreen(),
    const FeedScreen(),
    const ProfileWithHistoryScreen(),
  ];

  final List<String> _titles = [
    'Discover',
    'Messages',
    'Create',
    'Feed',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToUnreadMessages();
    _updateUserOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      switch (state) {
        case AppLifecycleState.resumed:
          _updateUserOnlineStatus(true);
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
        case AppLifecycleState.inactive:
          _updateUserOnlineStatus(false);
          break;
        case AppLifecycleState.hidden:
          _updateUserOnlineStatus(false);
          break;
      }
    }
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating online status: $e');
      }
    }
  }

  void _listenToUnreadMessages() {
    if (_auth.currentUser == null) return;
    
    _firestore
        .collection('conversations')
        .where('participants', arrayContains: _auth.currentUser!.uid)
        .snapshots()
        .listen((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCount = data['unreadCount']?[_auth.currentUser!.uid] ?? 0;
        totalUnread += unreadCount as int;
      }
      
      if (mounted) {
        setState(() {
          _unreadMessageCount = totalUnread;
        });
        
        NotificationService().updateBadgeCount(totalUnread);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: _unreadMessageCount > 0
                  ? badges.Badge(
                      badgeContent: Text(
                        _unreadMessageCount > 99 
                            ? '99+' 
                            : _unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                      ),
                      child: const Icon(Icons.message_outlined),
                    )
                  : const Icon(Icons.message_outlined),
              activeIcon: _unreadMessageCount > 0
                  ? badges.Badge(
                      badgeContent: Text(
                        _unreadMessageCount > 99 
                            ? '99+' 
                            : _unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                      ),
                      child: const Icon(Icons.message),
                    )
                  : const Icon(Icons.message),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Create',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.feed_outlined),
              activeIcon: Icon(Icons.feed),
              label: 'Feed',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}