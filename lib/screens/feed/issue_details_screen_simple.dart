// lib/screens/feed/issue_details_screen_simple.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import '../../models/issue_model.dart';
import 'dart:developer' as developer;

class IssueDetailsScreenSimple extends StatefulWidget {
  final String issueId;

  const IssueDetailsScreenSimple({super.key, required this.issueId});

  @override
  State<IssueDetailsScreenSimple> createState() =>
      _IssueDetailsScreenSimpleState();
}

class _IssueDetailsScreenSimpleState extends State<IssueDetailsScreenSimple> {
  Future<Issue?>? _issueFuture;

  @override
  void initState() {
    super.initState();
    _issueFuture = _fetchIssueDetails();
  }

  Future<Issue?> _fetchIssueDetails() async {
    if (widget.issueId.isEmpty || widget.issueId == 'error_no_id') {
      developer.log(
        "IssueDetailsScreen: Invalid or missing issueId provided: '${widget.issueId}'",
        name: "IssueDetailsScreen",
      );
      return null;
    }
    try {
      developer.log(
        "IssueDetailsScreen: Fetching details for issueId: '${widget.issueId}'",
        name: "IssueDetailsScreen",
      );
      DocumentSnapshot<Map<String, dynamic>> issueDoc =
          await FirebaseFirestore.instance
              .collection('issues')
              .doc(widget.issueId)
              .get();

      developer.log(
        "IssueDetailsScreen: Document exists: ${issueDoc.exists}",
        name: "IssueDetailsScreen",
      );

      if (issueDoc.exists) {
        final data = issueDoc.data();
        developer.log(
          "IssueDetailsScreen: Document data keys: ${data?.keys.toList()}",
          name: "IssueDetailsScreen",
        );
        return Issue.fromFirestore(data!, issueDoc.id);
      } else {
        developer.log(
          "IssueDetailsScreen: Issue with ID '${widget.issueId}' not found in Firestore.",
          name: "IssueDetailsScreen",
        );
        return null;
      }
    } catch (e) {
      developer.log(
        "Error fetching issue details for ${widget.issueId}: $e",
        name: "IssueDetailsScreen",
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.issueDetails),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: FutureBuilder<Issue?>(
        future: _issueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading issue details...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            developer.log(
              "Error in FutureBuilder: ${snapshot.error}",
              name: "IssueDetailsScreen",
            );
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading issue",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _issueFuture = _fetchIssueDetails();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "Issue not found",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Issue ID: ${widget.issueId}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "This issue might have been deleted or there was an error loading it.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _issueFuture = _fetchIssueDetails();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final issue = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    issue.username.isNotEmpty
                                        ? issue.username
                                        : 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _formatTimestamp(issue.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(issue.status),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                issue.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          issue.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(issue.category),
                              backgroundColor: Colors.blue[100],
                            ),
                            if (issue.urgency != null &&
                                issue.urgency!.isNotEmpty)
                              Chip(
                                label: Text(issue.urgency!),
                                backgroundColor: _getUrgencyColor(
                                  issue.urgency,
                                ),
                              ),
                          ],
                        ),
                        if (issue.location.address.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.red[400],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  issue.location.address,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Issue Image
                if (issue.imageUrl.isNotEmpty)
                  Card(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        issue.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Image not available'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${issue.upvotes}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text('Upvotes'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${issue.downvotes}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text('Downvotes'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${issue.commentsCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text('Comments'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${issue.affectedUsersCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text('Affected'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Success message removed - app is working properly now
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
      case 'acknowledged':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'reported':
      default:
        return Colors.blue;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'high':
        return Colors.red[100]!;
      case 'medium':
        return Colors.orange[100]!;
      case 'low':
        return Colors.blue[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
