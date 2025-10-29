// lib/screens/contacts_grid/contacts_grid_screen.dart
import 'package:cocolab_messaging/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../models/expanded_contact.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../services/local_notification_service.dart';
import '../../utils/contacts_helper.dart';
import './../profile/profile_screen.dart';
import './../chat_screen.dart';
import './contact_search_bar.dart';
import './contact_list.dart';

class ContactsGridScreen extends StatefulWidget {
  const ContactsGridScreen({super.key});

  @override
  State<ContactsGridScreen> createState() => _ContactsGridScreenState();
}

class _ContactsGridScreenState extends State<ContactsGridScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<ExpandedContact> _contacts = [];
  List<ExpandedContact> _filteredContacts = [];
  Map<String, UserProfile> _userProfiles = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // Add these new variables
  final StreamController<Map<String, dynamic>> _notificationStreamController =
  StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => _filterContacts(_searchController.text));
    _setupNotificationListener();
    _initializeApp();
  }

  // Add these new methods
  // In contacts_grid_screen.dart, modify _setupNotificationListener
  void _setupNotificationListener() {
    // Listen for notification data and update only the specific contact
    _notificationSubscription = _notificationStreamController.stream.listen((data) {
      print("Received notification in contacts grid: $data");

      // If it's a message notification with a sender ID
      if (data.containsKey('senderId')) {
        String senderId = data['senderId'];
        // Update just the contact for this sender
        _updateContactForSender(senderId);
      }
    });

    // Register this controller with your notification service
    LocalNotificationService.setNotificationStreamController(_notificationStreamController);
  }

// Add this new method to update a single contact by sender ID
  void _updateContactForSender(String senderId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Find which contact this sender belongs to
      ExpandedContact? contactToUpdate;
      int indexToUpdate = -1;

      // Check unknown contacts first (they have the ID in their contact ID)
      for (int i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        if (contact.isUnknown && contact.contact.id == 'unknown_$senderId') {
          contactToUpdate = contact;
          indexToUpdate = i;
          break;
        }
      }

      // If not found in unknown contacts, check regular contacts by phone number
      if (contactToUpdate == null) {
        // Get sender's phone number
        final senderSnapshot = await _db.child('users').child(senderId).get();
        if (senderSnapshot.exists) {
          final senderData = Map<String, dynamic>.from(senderSnapshot.value as Map);
          final senderPhone = senderData['phoneNumber'] as String?;

          if (senderPhone != null) {
            final normalizedPhone = _normalizePhoneNumber(senderPhone);

            // Look for this phone in contacts
            for (int i = 0; i < _contacts.length; i++) {
              final contact = _contacts[i];
              if (_normalizePhoneNumber(contact.phoneNumber) == normalizedPhone) {
                contactToUpdate = contact;
                indexToUpdate = i;
                break;
              }
            }
          }
        }
      }

      // If we found the contact to update
      if (contactToUpdate != null && indexToUpdate >= 0) {
        // Create updated contact with unread flag
        final updatedContact = ExpandedContact(
          contact: contactToUpdate.contact,
          phoneNumber: contactToUpdate.phoneNumber,
          isRegistered: contactToUpdate.isRegistered,
          isUnknown: contactToUpdate.isUnknown,
          hasUnreadMessages: true, // New message received - mark as unread
        );

        setState(() {
          _contacts[indexToUpdate] = updatedContact;

          // Also update in filtered contacts if present
          int filteredIndex = -1;
          if (contactToUpdate != null) {
            filteredIndex = _filteredContacts.indexWhere((contact) =>
            contact.contact.id == contactToUpdate!.contact.id);
          }
          if (filteredIndex != -1) {
            _filteredContacts[filteredIndex] = updatedContact;
          }
        });
      }
    } catch (e) {
      print("Error updating contact for sender: $e");
    }
  }

  Future<void> _initializeApp() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await _loadContacts();
    } else {
      final newStatus = await Permission.contacts.request();
      if (newStatus.isGranted) {
        await _loadContacts();
      } else {
        if (mounted) setState(() => _isLoading = false);
        _showPermissionDeniedDialog();
      }
    }
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load user profiles first
      final snapshot = await _db.child('users').get();
      final Map<String, UserProfile> registeredUsers = {};

      if (snapshot.exists) {
        final users = Map<String, dynamic>.from(snapshot.value as Map);
        users.forEach((key, value) {
          if (value is Map) {
            String normalizedNumber = _normalizePhoneNumber(value['phoneNumber'] ?? '');
            registeredUsers[normalizedNumber] = UserProfile.fromMap(Map<String, dynamic>.from(value));
          }
        });
      }

      // Get expanded contacts
      final expandedContacts = await ContactsHelper.fetchAndMatchContacts(_profileService);

      if (mounted) {
        setState(() {
          _contacts = expandedContacts;
        });

        // Now get unknown contacts from conversations
        final unknownContacts = await _getUnknownContactsFromConversations();

        // Update all contacts with unread message status
        await _updateContactsWithUnreadStatus();

        setState(() {
          // Add unknown contacts to the list
          _contacts.addAll(unknownContacts);
          _filteredContacts = _contacts;
          _userProfiles = registeredUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog('Could not load contacts. Please try again.');
    }
  }

  // Add this new method
  Future<void> _updateContactsWithUnreadStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Get all conversations
      final conversationsSnapshot = await _db.child('conversations').get();
      if (!conversationsSnapshot.exists) return;

      final allConversations = Map<String, dynamic>.from(conversationsSnapshot.value as Map);

      // Create a map of userId to hasUnreadMessages status
      final Map<String, bool> userIdToUnreadStatus = {};

      // Process all conversations
      for (var entry in allConversations.entries) {
        try {
          final conversationData = Map<String, dynamic>.from(entry.value as Map);
          final participants = Map<String, dynamic>.from(conversationData['participants'] as Map);

          // Only process conversations where current user is a participant
          if (participants[currentUser.uid] != true) continue;

          // Check if this conversation has unread messages for the current user
          bool hasUnreadMessages = false;
          if (conversationData.containsKey('unreadBy')) {
            final unreadBy = conversationData['unreadBy'] as Map?;
            if (unreadBy != null) {
              // Check if current user has unread messages
              hasUnreadMessages = unreadBy[currentUser.uid] == true;
            }
          }

          if (hasUnreadMessages) {
            // Find the other participant
            for (var userId in participants.keys) {
              if (userId != currentUser.uid) {
                // Mark this user as having unread messages
                userIdToUnreadStatus[userId] = true;
                break;
              }
            }
          }
        } catch (e) {
          print("Error processing conversation for unread status: $e");
        }
      }

      // Now update all contacts with unread status
      for (int i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];

        String userId;

        if (contact.isUnknown) {
          // For unknown contacts, extract the user ID from the contact ID
          userId = contact.contact.id.substring(8); // Remove 'unknown_' prefix
        } else {
          // For known contacts, look up their user ID by phone number
          final normalizedPhone = _normalizePhoneNumber(contact.phoneNumber);
          final userSnapshot = await _db.child('users')
              .orderByChild('phoneNumber')
              .equalTo(normalizedPhone)
              .get();

          if (!userSnapshot.exists || userSnapshot.children.isEmpty) continue;

          userId = userSnapshot.children.first.key!;
        }

        // Update the contact with unread status
        if (userIdToUnreadStatus.containsKey(userId) && userIdToUnreadStatus[userId] == true) {
          // Create a new ExpandedContact with hasUnreadMessages = true
          _contacts[i] = ExpandedContact(
            contact: contact.contact,
            phoneNumber: contact.phoneNumber,
            isRegistered: contact.isRegistered,
            isUnknown: contact.isUnknown,
            hasUnreadMessages: true,
          );
        }
      }
    } catch (e) {
      print("Error updating contacts with unread status: $e");
    }
  }

  Future<List<ExpandedContact>> _getUnknownContactsFromConversations() async {
    final List<ExpandedContact> unknownContacts = [];
    final currentUser = _authService.currentUser;

    if (currentUser == null) return unknownContacts;

    try {
      // Fetch ALL conversations instead of querying by participant
      final conversationsSnapshot = await _db.child('conversations').get();

      if (!conversationsSnapshot.exists) return unknownContacts;

      final allConversations = Map<String, dynamic>.from(conversationsSnapshot.value as Map);

      // Filter conversations to find those where current user is a participant
      final userConversations = Map<String, dynamic>.from(
          Map.fromEntries(
              allConversations.entries.where((entry) {
                final convo = Map<String, dynamic>.from(entry.value as Map);
                final participants = convo['participants'] as Map?;
                return participants != null && participants[currentUser.uid] == true;
              })
          )
      );

      print("Found ${userConversations.length} conversations for current user");

      // Get existing contact phone numbers for comparison
      final Set<String> existingContactNumbers = _contacts
          .map((contact) => _normalizePhoneNumber(contact.phoneNumber))
          .toSet();

      // Process each conversation to find unknown contacts
      for (var entry in userConversations.entries) {
        try {
          final conversationData = Map<String, dynamic>.from(entry.value as Map);
          final participants = Map<String, dynamic>.from(conversationData['participants'] as Map);

          // Find the other participant
          String otherUserId = '';
          for (var id in participants.keys) {
            if (id != currentUser.uid) {
              otherUserId = id;
              break;
            }
          }

          if (otherUserId.isEmpty) continue;

          // Check for unread messages
          bool hasUnreadMessages = false;
          try {
            // If hasUnreadMessages exists directly in the conversation
            if (conversationData.containsKey('hasUnreadMessages')) {
              hasUnreadMessages = conversationData['hasUnreadMessages'] == true;
            }
          } catch (e) {
            print("Error checking for unread messages: $e");
          }

          // Get user info
          final userSnapshot = await _db.child('users').child(otherUserId).get();
          if (!userSnapshot.exists) continue;

          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          final phoneNumber = userData['phoneNumber'] as String?;
          final displayName = userData['displayName'] as String? ?? 'Unknown User';

          if (phoneNumber == null || phoneNumber.isEmpty) continue;

          // Check if this number is already in our contacts
          final normalizedPhone = _normalizePhoneNumber(phoneNumber);
          if (existingContactNumbers.contains(normalizedPhone)) continue;

          // Create a contact object for the UI
          final contact = Contact(
            id: 'unknown_$otherUserId',
            displayName: displayName,
          );
          contact.phones = [Phone(phoneNumber)];

          unknownContacts.add(ExpandedContact(
            contact: contact,
            phoneNumber: phoneNumber,
            isRegistered: true,
            isUnknown: true,
            hasUnreadMessages: hasUnreadMessages,
          ));
        } catch (e) {
          print("Error processing conversation: $e");
        }
      }
    } catch (e) {
      print("Error getting unknown contacts: $e");
    }

    return unknownContacts;
  }

  String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '').replaceAll(RegExp(r'^1'), '');
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((expandedContact) =>
      expandedContact.contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
          expandedContact.phoneNumber.contains(query))
          .toList();
    });
  }

  void _openChat(ExpandedContact expandedContact) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showErrorDialog('User is not authenticated.');
      return;
    }

    try {
      String recipientId;

      // Check if this is an unknown contact
      if (expandedContact.contact.id.startsWith('unknown_')) {
        recipientId = expandedContact.contact.id.substring(8); // Remove 'unknown_' prefix
      } else {
        // Regular contact - look up the user ID by phone number
        String phoneNumber = _normalizePhoneNumber(expandedContact.phoneNumber);
        final snapshot = await _db.child('users')
            .orderByChild('phoneNumber')
            .equalTo(phoneNumber)
            .get();

        if (!snapshot.exists || snapshot.children.isEmpty) {
          _showErrorDialog('This contact is not registered.');
          return;
        }

        recipientId = snapshot.children.first.key!;
      }

      await _messageService.createOrUpdateConversation(
          currentUser.uid,
          recipientId,
          'Conversation started'
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              contact: expandedContact.contact,
              recipientId: recipientId,
            ),
          ),
        ).then((_) {
          // Instead of reloading all contacts, just update this specific contact
          if (mounted) {
            _updateSingleContact(expandedContact, recipientId);
          }
        });
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

// New method to update just a single contact
  void _updateSingleContact(ExpandedContact contact, String recipientId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      // Get the conversation ID
      final sortedIds = [currentUser.uid, recipientId]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      // Check if this conversation has unread messages
      final conversationSnapshot = await _db.child('conversations').child(conversationId).get();
      if (!conversationSnapshot.exists) return;

      final conversationData = Map<String, dynamic>.from(conversationSnapshot.value as Map);
      final hasUnreadMessages = conversationData['hasUnreadMessages'] == true;

      // Find this contact in the contacts list and update it
      int index = _contacts.indexWhere((c) => c.contact.id == contact.contact.id);
      if (index != -1) {
        final updatedContact = ExpandedContact(
          contact: contact.contact,
          phoneNumber: contact.phoneNumber,
          isRegistered: contact.isRegistered,
          isUnknown: contact.isUnknown,
          hasUnreadMessages: hasUnreadMessages,
        );

        setState(() {
          _contacts[index] = updatedContact;

          // Also update in filtered contacts if present
          int filteredIndex = _filteredContacts.indexOf(contact);
          if (filteredIndex != -1) {
            _filteredContacts[filteredIndex] = updatedContact;
          }
        });
      }
    } catch (e) {
      print("Error updating single contact: $e");
    }
  }


  void _showPermissionDeniedDialog() {
    _showDialog(
      title: 'Permission Denied',
      content: 'This app requires access to contacts. Please enable it in settings.',
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }

  void _showErrorDialog(String message) {
    _showDialog(
      title: 'Error',
      content: message,
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    );
  }

  void _showDialog({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationSubscription?.cancel();
    _notificationStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              _loadContacts();
            },
          ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadContacts
          ),
        ],
      ),
      body: Column(
        children: [
          ContactSearchBar(controller: _searchController),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No contacts found"),
                  const SizedBox(height: 8),
                  const Text(
                      "Make sure you have granted permission and synced your contacts."
                  ),
                  TextButton(
                      onPressed: _loadContacts,
                      child: const Text("Retry")
                  ),
                ],
              ),
            )
                : ContactList(
              expandedContacts: _filteredContacts,
              userProfiles: _userProfiles,
              onTap: _openChat,
            ),
          ),
        ],
      ),
    );
  }
}