// lib/screens/feed/issue_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:modern_auth_app/l10n/app_localizations.dart';
import '../../models/issue_model.dart';
import '../../widgets/issue_card.dart';
import '../../widgets/issue_timeline_widget.dart';
import '../../widgets/issue_collaborations_widget.dart';
import '../../services/user_profile_service.dart';
import 'issue_collaboration_screen.dart';
import 'dart:developer' as developer;

class IssueDetailsScreen extends StatefulWidget {
  final String issueId;

  const IssueDetailsScreen({super.key, required this.issueId});

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
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
      appBar: AppBar(title: Text(l10n!.issueDetails)),
      body: FutureBuilder<Issue?>(
        future: _issueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            developer.log(
              "Error in FutureBuilder: ${snapshot.error}",
              name: "IssueDetailsScreen",
            );
            return Center(
              child: Text("Error loading issue: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
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
          final userProfile =
              Provider.of<UserProfileService>(context).currentUserProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Issue Card
                IssueCard(issue: issue),

                const SizedBox(height: 24),

                // Issue Timeline
                Text(
                  l10n.timeline,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Use the statusUpdates from the issue document instead of subcollection
                IssueTimelineWidget(
                  issue: issue,
                  statusUpdates: issue.statusUpdates,
                ),

                const SizedBox(height: 24),

                // Collaborations Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.collaboration,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userProfile != null)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => IssueCollaborationScreen(
                                    issueId: widget.issueId,
                                    issue: issue,
                                  ),
                            ),
                          );

                          if (result == true) {
                            // Refresh the issue details if collaboration was added
                            setState(() {
                              _issueFuture = _fetchIssueDetails();
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.post),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Wrap in error boundary to prevent crashes
                Builder(
                  builder: (context) {
                    try {
                      return IssueCollaborationsWidget(issueId: widget.issueId);
                    } catch (e) {
                      developer.log(
                        "Error loading collaborations widget: $e",
                        name: "IssueDetailsScreen",
                      );
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Collaborations temporarily unavailable',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
