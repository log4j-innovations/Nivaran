import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('gu'),
  ];

  // Basic getters for essential strings
  String get chooseYourLanguage => 'Choose Your Language';
  String get english => 'English';
  String get hindi => 'Hindi';
  String get gujarati => 'Gujarati';
  String get welcomeToNivaran => 'Welcome to Nivaran';
  String get pleaseSelectYourPreferredLanguage =>
      'Please select your preferred language';
  String get continueButton => 'Continue';
  String get useSystemLanguage => 'Use System Language';
  String get loginWithEmailOrGoogle =>
      'Login with your email or Google account';
  String get continueWithGoogle => 'Continue with Google';
  String get byClickingContinueYouAgree =>
      'By clicking continue, you agree to our';
  String get termsOfService => 'Terms of Service';
  String get and => 'and';
  String get privacyPolicy => 'Privacy Policy';
  String get iAmA => 'I am a...';
  String get citizen => 'Citizen';
  String get letsGetStarted => "Let's Get Started";
  String get login => 'Login';
  String get signUp => 'Sign Up';
  String get orContinueWith => 'or continue with';
  String get loginTitle => 'Login to your account';
  String get email => 'Email';
  String get password => 'Password';
  String get forgotPassword => 'Forgot Password?';
  String get dontHaveAnAccount => "Don't have an account?";
  String get createAccount => 'Create Account';
  String get fullName => 'Full Name';
  String get confirmPassword => 'Confirm Password';
  String get alreadyHaveAnAccount => 'Already have an account?';
  String get enterYourOfficialDetails => 'Enter Your Official Details';
  String get department => 'Department';
  String get employeeId => 'Employee ID';
  String get submit => 'Submit';
  String get setYourPassword => 'Set Your Password';
  String get passwordRequirement => 'Password must be at least 6 characters.';
  String get confirm => 'Confirm';
  String get verifyYourEmail => 'Verify Your Email';
  String get verificationEmailSent =>
      'A verification email has been sent to your email address. Please check your inbox and click the link to continue.';
  String get resendEmail => 'Resend Email';
  String get cancel => 'Cancel';
  String get home => 'Home';
  String get feed => 'Feed';
  String get report => 'Report';
  String get map => 'Map';
  String get profile => 'Profile';
  String get publicDashboard => 'Public Dashboard';
  String get notifications => 'Notifications';
  String get account => 'Account';
  String get settings => 'Settings';
  String get logout => 'Logout';
  String get reportAnIssue => 'Report an Issue';
  String get title => 'Title';
  String get description => 'Description';
  String get category => 'Category';
  String get takePhoto => 'Take Photo';
  String get chooseFromGallery => 'Choose from Gallery';
  String get submitIssue => 'Submit Issue';
  String get myIssues => 'My Issues';
  String get statistics => 'Statistics';
  String get communityImpact => 'Community Impact';
  String get issuesFeed => 'Issues Feed';
  String get issueDetails => 'Issue Details';
  String get status => 'Status';
  String get reportedOn => 'Reported On';
  String get location => 'Location';
  String get comments => 'Comments';
  String get addAComment => 'Add a comment...';
  String get post => 'Post';
  String get upvotes => 'Upvotes';
  String get upvoted => 'Upvoted';
  String get collaboration => 'Collaboration';
  String get timeline => 'Timeline';
  String get analyzingImageWithAI => 'Analyzing image with AI...';
  String get loadingCategories => 'Loading categories...';
  String get share => 'Share';
  String get tenKmRadius => '10 km radius';
  String get aiRiskAnalysis => 'AI Risk Analysis';
  String get filterIssues => 'Filter Issues';
  String get allCategories => 'All Categories';
  String get urgency => 'Urgency';
  String get allUrgencies => 'All Urgencies';
  String get allStatus => 'All Status';
  String get clearAll => 'Clear All';
  String get applyFilters => 'Apply Filters';
  String get low => 'Low';
  String get medium => 'Medium';
  String get high => 'High';
  String get reported => 'Reported';
  String get acknowledged => 'Acknowledged';
  String get inProgress => 'In Progress';
  String get resolved => 'Resolved';
  String get rejected => 'Rejected';
  String get pothole => 'Pothole';
  String get streetLightOut => 'Street Light Out';
  String get fallenTree => 'Fallen Tree';
  String get waterLeakage => 'Water Leakage';
  String get fetchingLocationAndCategories =>
      'Fetching location and categories...';
  String get aiAnalysisComplete => 'AI analysis complete';
  String get predictiveMaintenanceInsights => 'Predictive Maintenance Insights';
  String get areasLikelyToReoccur =>
      'Areas where issues are likely to reoccur based on historical patterns';
  String get proactiveMaintenanceBenefit =>
      'Proactive maintenance in this area could prevent recurring issues.';
  String get benefitEnablesProactiveAction =>
      'Benefit: Enables proactive government action';
  String get addressingAreasSaveResources =>
      'Addressing these areas before new issues are reported can save resources and improve citizen satisfaction.';
  String get notEnoughHistoricalData =>
      "As more issues are reported, we'll identify patterns to predict where problems might recur.";
  String get noHistoricalDataForPredictions =>
      'Not enough historical data for predictions yet';
  String get noEmployeePerformanceData =>
      'This section will show statistics once employee data is populated in the "employees" collection in Firestore.';
  String get noEmployeeDataAvailable =>
      'No employee performance data available at the moment.';
  String get noIssueDataAvailable => 'No issue data available';
  String get dashboardTransparency =>
      'This dashboard provides transparency on issue resolution and citizen satisfaction.';
  String get dataByEmployeeDepartment => '(Data by Employee/Department)';
  String get resolutionTimesSatisfactionRates =>
      'Resolution Times & Satisfaction Rates';
  String get mobileNo => 'Mobile No';
  String get fullNameIsRequired => 'Full Name is Required';
  String get mobileNumberIsRequired => 'Mobile number is Required';
  String get passwordIsRequired => 'Password Is Required';
  String get pleaseConfirmYourPassword => 'Please confirm your Password';
  String get checkVerificationStatus => 'Check Verification Status';
  String get areaZoneOfOperation => 'Area/Zone of Operation';
  String get governmentIssuedIdNumber => 'Government-issued ID number';
  String get noIssuesMatchFilters =>
      'No issues match current filters for {department}';
  String get editProfile => 'Edit Profile';
  String get changePassword => 'Change Password';
  String get myActivityLog => 'My Activity Log';
  String get notificationSetting => 'Notification Setting';
  String get designation => 'Designation';
  String get sortByDate => 'Sort By date';
  String get sortByUrgency => 'Sort by urgency';
  String get sortByUpvote => 'Sort by upvote';
  String get yourVoiceOurAction => 'Your Voice Our Action';
  String get language => 'Language';
  String get selectLanguage => 'Select Language';
  String get issueSavedOffline =>
      'Issue saved offline. It will be synced when online.';
  String get syncingIssues => 'Syncing issues...';
  String get offlineMode => 'Offline Mode';
  String get unsyncedIssues => 'Unsynced Issues';
  String get viewDetails => 'View Details';
  String get delete => 'Delete';
  String get issueSavedLocally => 'Issue saved locally';
  String get issueSyncedSuccessfully => 'Issue synced successfully';
  String get errorSyncingIssue => 'Error syncing issue';
  String get noUnsyncedIssues => 'No unsynced issues';
  String get defaultUrgencyMediumOffline => 'Default Urgency: Medium (Offline)';
  String get noIssuesToDisplay => 'No issues to display';
  String get myReportedIssues => 'My Reported Issues';
  String get deleteIssue => 'Delete Issue?';
  String get deleteIssueConfirmation =>
      'Are you sure you want to delete this issue? This action cannot be undone.';
  String get locationUnavailable => 'Location Unavailable';
  String get locationError => 'Location Error';
  String get cachedData => 'Cached Data';
  String get help => 'Help & Support';
  String get viewAndManageOfflineIssues => 'View and manage offline issues';

  // Gamification strings
  String get overview => 'Overview';
  String get badges => 'Badges';
  String get achievements => 'Achievements';
  String get leaderboard => 'Leaderboard';
  String get level => 'Level';
  String get points => 'Points';
  String get nextLevel => 'Next Level';
  String get issues => 'Issues';
  String get streak => 'Streak';
  String get dailyChallenges => 'Daily Challenges';
  String get recentAchievements => 'Recent Achievements';
  String get quickActions => 'Quick Actions';
  String get noChallengesAvailable => 'No challenges available';
  String get noAchievementsYet => 'No achievements yet';
  String get reportIssue => 'Report Issue';
  String get viewMap => 'View Map';
  String get shareApp => 'Share App';
  String get unlocked => 'Unlocked';
  String get locked => 'Locked';
  String get completed => 'Completed';
  String get achievementsComingSoon => 'Achievements coming soon!';
  String get rewardsStore => 'Rewards Store';
  String get availableRewards => 'Available Rewards';
  String get myRewards => 'My Rewards';
  String get yourPoints => 'Your Points';
  String get noRewardsAvailable => 'No rewards available';
  String get checkBackLater => 'Check back later for new rewards';
  String get noRewardsYet => 'No rewards yet';
  String get earnPointsToUnlock => 'Earn points to unlock rewards';
  String get purchase => 'Purchase';
  String get insufficientPoints => 'Insufficient points';
  String get rewardUnlocked => 'Reward unlocked!';
  String get purchaseFailed => 'Purchase failed';
  String get error => 'Error';
  String get rewards => 'Rewards';

  String noIssuesMatchFiltersWithDepartment(String department) {
    return noIssuesMatchFilters.replaceAll('{department}', department);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
