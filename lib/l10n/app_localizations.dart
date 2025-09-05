import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseYourLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati;

  /// No description provided for @welcomeToNivaran.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nivaran'**
  String get welcomeToNivaran;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a...'**
  String get iAmA;

  /// No description provided for @citizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizen;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get letsGetStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @enterYourOfficialDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Official Details'**
  String get enterYourOfficialDetails;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @setYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Your Password'**
  String get setYourPassword;

  /// No description provided for @passwordRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordRequirement;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to your email address. Please check your inbox and click the link to continue.'**
  String get verificationEmailSent;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @publicDashboard.
  ///
  /// In en, this message translates to:
  /// **'Public Dashboard'**
  String get publicDashboard;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportAnIssue;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @submitIssue.
  ///
  /// In en, this message translates to:
  /// **'Submit Issue'**
  String get submitIssue;

  /// No description provided for @myIssues.
  ///
  /// In en, this message translates to:
  /// **'My Issues'**
  String get myIssues;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @communityImpact.
  ///
  /// In en, this message translates to:
  /// **'Community Impact'**
  String get communityImpact;

  /// No description provided for @issuesFeed.
  ///
  /// In en, this message translates to:
  /// **'Issues Feed'**
  String get issuesFeed;

  /// No description provided for @issueDetails.
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get issueDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @reportedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported On'**
  String get reportedOn;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @upvotes.
  ///
  /// In en, this message translates to:
  /// **'Upvotes'**
  String get upvotes;

  /// No description provided for @upvoted.
  ///
  /// In en, this message translates to:
  /// **'Upvoted'**
  String get upvoted;

  /// No description provided for @collaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get collaboration;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @analyzingImageWithAI.
  ///
  /// In en, this message translates to:
  /// **'Analyzing image with AI...'**
  String get analyzingImageWithAI;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @tenKmRadius.
  ///
  /// In en, this message translates to:
  /// **'10 km radius'**
  String get tenKmRadius;

  /// No description provided for @aiRiskAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Risk Analysis'**
  String get aiRiskAnalysis;

  /// No description provided for @filterIssues.
  ///
  /// In en, this message translates to:
  /// **'Filter Issues'**
  String get filterIssues;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @allUrgencies.
  ///
  /// In en, this message translates to:
  /// **'All Urgencies'**
  String get allUrgencies;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @reported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reported;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @pothole.
  ///
  /// In en, this message translates to:
  /// **'Pothole'**
  String get pothole;

  /// No description provided for @streetLightOut.
  ///
  /// In en, this message translates to:
  /// **'Street Light Out'**
  String get streetLightOut;

  /// No description provided for @fallenTree.
  ///
  /// In en, this message translates to:
  /// **'Fallen Tree'**
  String get fallenTree;

  /// No description provided for @waterLeakage.
  ///
  /// In en, this message translates to:
  /// **'Water Leakage'**
  String get waterLeakage;

  /// No description provided for @fetchingLocationAndCategories.
  ///
  /// In en, this message translates to:
  /// **'Fetching location and categories...'**
  String get fetchingLocationAndCategories;

  /// No description provided for @aiAnalysisComplete.
  ///
  /// In en, this message translates to:
  /// **'AI analysis complete'**
  String get aiAnalysisComplete;

  /// No description provided for @predictiveMaintenanceInsights.
  ///
  /// In en, this message translates to:
  /// **'Predictive Maintenance Insights'**
  String get predictiveMaintenanceInsights;

  /// No description provided for @areasLikelyToReoccur.
  ///
  /// In en, this message translates to:
  /// **'Areas where issues are likely to reoccur based on historical patterns'**
  String get areasLikelyToReoccur;

  /// No description provided for @proactiveMaintenanceBenefit.
  ///
  /// In en, this message translates to:
  /// **'Proactive maintenance in this area could prevent recurring issues.'**
  String get proactiveMaintenanceBenefit;

  /// No description provided for @benefitEnablesProactiveAction.
  ///
  /// In en, this message translates to:
  /// **'Benefit: Enables proactive government action'**
  String get benefitEnablesProactiveAction;

  /// No description provided for @addressingAreasSaveResources.
  ///
  /// In en, this message translates to:
  /// **'Addressing these areas before new issues are reported can save resources and improve citizen satisfaction.'**
  String get addressingAreasSaveResources;

  /// No description provided for @notEnoughHistoricalData.
  ///
  /// In en, this message translates to:
  /// **'As more issues are reported, we\'ll identify patterns to predict where problems might recur.'**
  String get notEnoughHistoricalData;

  /// No description provided for @noHistoricalDataForPredictions.
  ///
  /// In en, this message translates to:
  /// **'Not enough historical data for predictions yet'**
  String get noHistoricalDataForPredictions;

  /// No description provided for @noEmployeePerformanceData.
  ///
  /// In en, this message translates to:
  /// **'This section will show statistics once employee data is populated in the \"employees\" collection in Firestore.'**
  String get noEmployeePerformanceData;

  /// No description provided for @noEmployeeDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No employee performance data available at the moment.'**
  String get noEmployeeDataAvailable;

  /// No description provided for @noIssueDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No issue data available'**
  String get noIssueDataAvailable;

  /// No description provided for @dashboardTransparency.
  ///
  /// In en, this message translates to:
  /// **'This dashboard provides transparency on issue resolution and citizen satisfaction.'**
  String get dashboardTransparency;

  /// No description provided for @dataByEmployeeDepartment.
  ///
  /// In en, this message translates to:
  /// **'(Data by Employee/Department)'**
  String get dataByEmployeeDepartment;

  /// No description provided for @resolutionTimesSatisfactionRates.
  ///
  /// In en, this message translates to:
  /// **'Resolution Times & Satisfaction Rates'**
  String get resolutionTimesSatisfactionRates;

  /// No description provided for @mobileNo.
  ///
  /// In en, this message translates to:
  /// **'Mobile No'**
  String get mobileNo;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name is Required'**
  String get fullNameIsRequired;

  /// No description provided for @mobileNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is Required'**
  String get mobileNumberIsRequired;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password Is Required'**
  String get passwordIsRequired;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your Password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Verification Status'**
  String get checkVerificationStatus;

  /// No description provided for @areaZoneOfOperation.
  ///
  /// In en, this message translates to:
  /// **'Area/Zone of Operation'**
  String get areaZoneOfOperation;

  /// No description provided for @governmentIssuedIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Government-issued ID number'**
  String get governmentIssuedIdNumber;

  /// No description provided for @noIssuesMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No issues match current filters for {department}'**
  String noIssuesMatchFilters(Object department);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @myActivityLog.
  ///
  /// In en, this message translates to:
  /// **'My Activity Log'**
  String get myActivityLog;

  /// No description provided for @notificationSetting.
  ///
  /// In en, this message translates to:
  /// **'Notification Setting'**
  String get notificationSetting;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get designation;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort By date'**
  String get sortByDate;

  /// No description provided for @sortByUrgency.
  ///
  /// In en, this message translates to:
  /// **'Sort by urgency'**
  String get sortByUrgency;

  /// No description provided for @sortByUpvote.
  ///
  /// In en, this message translates to:
  /// **'Sort by upvote'**
  String get sortByUpvote;

  /// No description provided for @yourVoiceOurAction.
  ///
  /// In en, this message translates to:
  /// **'Your Voice Our Action'**
  String get yourVoiceOurAction;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @issueSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Issue saved offline. It will be synced when online.'**
  String get issueSavedOffline;

  /// No description provided for @syncingIssues.
  ///
  /// In en, this message translates to:
  /// **'Syncing issues...'**
  String get syncingIssues;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @unsyncedIssues.
  ///
  /// In en, this message translates to:
  /// **'Unsynced Issues'**
  String get unsyncedIssues;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @issueSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Issue saved locally'**
  String get issueSavedLocally;

  /// No description provided for @issueSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Issue synced successfully'**
  String get issueSyncedSuccessfully;

  /// No description provided for @errorSyncingIssue.
  ///
  /// In en, this message translates to:
  /// **'Error syncing issue'**
  String get errorSyncingIssue;

  /// No description provided for @noUnsyncedIssues.
  ///
  /// In en, this message translates to:
  /// **'No unsynced issues'**
  String get noUnsyncedIssues;

  /// No description provided for @defaultUrgencyMediumOffline.
  ///
  /// In en, this message translates to:
  /// **'Default Urgency: Medium (Offline)'**
  String get defaultUrgencyMediumOffline;

  /// No description provided for @noIssuesToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No issues to display'**
  String get noIssuesToDisplay;

  /// No description provided for @myReportedIssues.
  ///
  /// In en, this message translates to:
  /// **'My Reported Issues'**
  String get myReportedIssues;

  /// No description provided for @deleteIssue.
  ///
  /// In en, this message translates to:
  /// **'Delete Issue?'**
  String get deleteIssue;

  /// No description provided for @deleteIssueConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this issue? This action cannot be undone.'**
  String get deleteIssueConfirmation;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location Unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Location Error'**
  String get locationError;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Cached Data'**
  String get cachedData;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
