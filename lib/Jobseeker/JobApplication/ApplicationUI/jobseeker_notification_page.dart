import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Jobseeker-side notification inbox.
/// Add this as a tab or navigate to it from the bottom nav "Applied" tab.
class JobseekerNotificationsPage extends StatefulWidget {
  const JobseekerNotificationsPage({super.key});

  @override
  State<JobseekerNotificationsPage> createState() =>
      _JobseekerNotificationsPageState();
}

class _JobseekerNotificationsPageState
    extends State<JobseekerNotificationsPage> {

  // ── Constants (matches your app's colour palette) ─────────────────────────
  static const Color kBlue          = Color(0xFF2563EB);
  static const Color kBg            = Color(0xFFF5F6FA);
  static const Color kTextPrimary   = Color(0xFF0F1624);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kBorder        = Color(0xFFE2E8F0);
  static const Color kAccepted    = Color(0xFF22C55E);
  static const Color kRejected    = Color(0xFFEF4444);
  static const Color kShortlisted = Color(0xFFF59E0B);
  static const Color kPending     = Color(0xFF94A3B8);

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<QuerySnapshot> get _notificationsStream => FirebaseFirestore.instance
      .collection('users')
      .doc(_userId)
      .collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Future<void> _markAllRead() async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void _markRead(String notifId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':    return kAccepted;
      case 'rejected':    return kRejected;
      case 'shortlisted': return kShortlisted;
      default:            return kPending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':    return Icons.check_circle_rounded;
      case 'rejected':    return Icons.cancel_rounded;
      case 'shortlisted': return Icons.star_rounded;
      default:            return Icons.notifications_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':    return 'Accepted';
      case 'rejected':    return 'Rejected';
      case 'shortlisted': return 'Shortlisted';
      default:            return 'Update';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: const Icon(Icons.arrow_back, color: kTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: kBlue, fontSize: 13),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kBlue),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data   = docs[index].data() as Map<String, dynamic>;
              final notifId = docs[index].id;
              return _buildNotificationCard(notifId, data);
            },
          );
        },
      ),
      // ❌ REMOVED bottomNavigationBar
    );
  }

  // ── Notification Card ──────────────────────────────────────────────────────

  Widget _buildNotificationCard(String notifId, Map<String, dynamic> data) {
    final status   = data['status']   as String? ?? 'pending';
    final isRead   = data['isRead']   as bool?   ?? false;
    final title    = data['title']    as String? ?? '';
    final body     = data['body']     as String? ?? '';
    final jobTitle = data['jobTitle'] as String? ?? '';
    final ts       = data['createdAt'] as Timestamp?;

    final color = _statusColor(status);

    return GestureDetector(
      onTap: () {
        if (!isRead) _markRead(notifId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
          isRead ? Colors.white : color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? kBorder : color.withOpacity(0.35),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_statusIcon(status), color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row + unread dot
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Body
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status pill + timestamp
                  Row(
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(status),
                                size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Timestamp
                      if (ts != null)
                        Text(
                          _formatTime(ts.toDate()),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 52, color: kBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your application updates will appear here.',
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}