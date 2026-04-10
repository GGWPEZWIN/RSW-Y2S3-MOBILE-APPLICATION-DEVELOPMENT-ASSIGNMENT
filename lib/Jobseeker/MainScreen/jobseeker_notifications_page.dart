import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobseekerNotificationsPage extends StatelessWidget {
  const JobseekerNotificationsPage({super.key});

  static const Color kBlue    = Color(0xFF2563EB);
  static const Color kBg      = Color(0xFFF5F6FA);
  static const Color kText    = Color(0xFF0F172A);
  static const Color kSubtext = Color(0xFF64748B);
  static const Color kBorder  = Color(0xFFE2E8F0);
  static const Color kOrange  = Color(0xFFF59E0B);
  static const Color kRed     = Color(0xFFEF4444);

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Color _typeColor(String type) {
    switch (type) {
      case 'interview_cancelled': return kRed;
      case 'interview_updated':   return kOrange;
      default:                    return kBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'interview_cancelled': return Icons.cancel_rounded;
      case 'interview_updated':   return Icons.edit_calendar_rounded;
      default:                    return Icons.calendar_today_rounded;
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _markAllRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Notifications',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(color: kBlue, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kBlue));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _emptyState();
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'interview';
              return _NotifCard(
                notifId: doc.id,
                uid:     _uid,
                data:    data,
                color:   _typeColor(type),
                icon:    _typeIcon(type),
                timeAgo: _timeAgo(data['createdAt'] as Timestamp?),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: kBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 44, color: kBlue),
        ),
        const SizedBox(height: 16),
        const Text('No notifications yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        const SizedBox(height: 6),
        const Text('Interview updates will appear here.',
            style: TextStyle(fontSize: 13, color: kSubtext)),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String notifId, uid;
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String timeAgo;

  const _NotifCard({
    required this.notifId, required this.uid, required this.data,
    required this.color, required this.icon, required this.timeAgo,
  });

  static const Color kText   = Color(0xFF0F172A);
  static const Color kSubtext= Color(0xFF64748B);
  static const Color kBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final title  = data['title']  as String? ?? '';
    final body   = data['body']   as String? ?? '';
    final isRead = data['isRead'] as bool?   ?? false;

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          FirebaseFirestore.instance
              .collection('users').doc(uid)
              .collection('notifications').doc(notifId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? kBorder : color.withOpacity(0.35),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title,
                  style: TextStyle(fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: kText))),
              if (!isRead)
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 5),
            Text(body, style: const TextStyle(fontSize: 13, color: kSubtext, height: 1.4)),
            const SizedBox(height: 8),
            Text(timeAgo, style: const TextStyle(fontSize: 11, color: kSubtext)),
          ])),
        ]),
      ),
    );
  }
}