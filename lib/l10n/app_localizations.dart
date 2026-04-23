import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

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
    Locale('ms'),
    Locale('zh'),
  ];

  /// No description provided for @findTheRightJob.
  ///
  /// In en, this message translates to:
  /// **'Find the right job'**
  String get findTheRightJob;

  /// No description provided for @buildYourCareer.
  ///
  /// In en, this message translates to:
  /// **'Build your career'**
  String get buildYourCareer;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginBtn;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @registerLink.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLink;

  /// No description provided for @recruitmentVisit.
  ///
  /// In en, this message translates to:
  /// **'Recruitment? Visit '**
  String get recruitmentVisit;

  /// No description provided for @hereLink.
  ///
  /// In en, this message translates to:
  /// **'here'**
  String get hereLink;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @employerLabel.
  ///
  /// In en, this message translates to:
  /// **'Employer'**
  String get employerLabel;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabel;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @jobsPosted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Posted'**
  String get jobsPosted;

  /// No description provided for @applicantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get applicantsLabel;

  /// No description provided for @jobsClosed.
  ///
  /// In en, this message translates to:
  /// **'Jobs Closed'**
  String get jobsClosed;

  /// No description provided for @upcomingInterviews.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Interviews'**
  String get upcomingInterviews;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @recentJobPost.
  ///
  /// In en, this message translates to:
  /// **'Recent job post'**
  String get recentJobPost;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'view all'**
  String get viewAll;

  /// No description provided for @myJobList.
  ///
  /// In en, this message translates to:
  /// **'My Job List'**
  String get myJobList;

  /// No description provided for @noJobsPosted.
  ///
  /// In en, this message translates to:
  /// **'You have no jobs posted yet.'**
  String get noJobsPosted;

  /// No description provided for @untitledJob.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledJob;

  /// No description provided for @appsByJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications by Job'**
  String get appsByJobTitle;

  /// No description provided for @interviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviewsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @employerSettings.
  ///
  /// In en, this message translates to:
  /// **'Employer Settings'**
  String get employerSettings;

  /// No description provided for @companyBackground.
  ///
  /// In en, this message translates to:
  /// **'Company Background'**
  String get companyBackground;

  /// No description provided for @backgroundLabel.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundLabel;

  /// No description provided for @noBackgroundSet.
  ///
  /// In en, this message translates to:
  /// **'No background description set.'**
  String get noBackgroundSet;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInfo;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get notSpecified;

  /// No description provided for @noWebsiteAdded.
  ///
  /// In en, this message translates to:
  /// **'No website added'**
  String get noWebsiteAdded;

  /// No description provided for @createCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get createCompanyTitle;

  /// No description provided for @setupCompanyHeader.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your company'**
  String get setupCompanyHeader;

  /// No description provided for @setupCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This information will appear on your job posts.'**
  String get setupCompanySubtitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name *'**
  String get companyNameLabel;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., TechFlow Sdn Bhd'**
  String get companyNameHint;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name required'**
  String get companyNameRequired;

  /// No description provided for @companyEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Email *'**
  String get companyEmailLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Penang, Malaysia'**
  String get addressHint;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get websiteLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell job seekers about your company...'**
  String get descriptionHint;

  /// No description provided for @createCompanyBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get createCompanyBtn;

  /// No description provided for @findDreamJob.
  ///
  /// In en, this message translates to:
  /// **'Find Your\nDream Job'**
  String get findDreamJob;

  /// No description provided for @searchJobsHint.
  ///
  /// In en, this message translates to:
  /// **'Search for jobs ...'**
  String get searchJobsHint;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendationsTitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabNewToYou.
  ///
  /// In en, this message translates to:
  /// **'New to you'**
  String get tabNewToYou;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @matchingDescription.
  ///
  /// In en, this message translates to:
  /// **'These matches are generated based on your skills, resume analysis, and past application preferences.'**
  String get matchingDescription;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @improveMatches.
  ///
  /// In en, this message translates to:
  /// **'Improve your job matches'**
  String get improveMatches;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @workingExperience.
  ///
  /// In en, this message translates to:
  /// **'Working Experience'**
  String get workingExperience;

  /// No description provided for @skillsLabel.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillsLabel;

  /// No description provided for @languagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// No description provided for @resumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeLabel;

  /// No description provided for @myResume.
  ///
  /// In en, this message translates to:
  /// **'My Resume'**
  String get myResume;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get actionUpload;

  /// No description provided for @tapToViewResume.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full resume'**
  String get tapToViewResume;

  /// No description provided for @noResumeUploaded.
  ///
  /// In en, this message translates to:
  /// **'No resume uploaded.'**
  String get noResumeUploaded;

  /// No description provided for @myAppliedJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Applied Jobs'**
  String get myAppliedJobsTitle;

  /// No description provided for @tabAppliedJobs.
  ///
  /// In en, this message translates to:
  /// **'Applied Jobs'**
  String get tabAppliedJobs;

  /// No description provided for @tabWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get tabWithdrawn;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in.'**
  String get pleaseLogin;

  /// No description provided for @noMatchingApps.
  ///
  /// In en, this message translates to:
  /// **'No matching applications.'**
  String get noMatchingApps;

  /// No description provided for @searchCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'Search company...'**
  String get searchCompanyHint;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get sortStatus;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @statusUnprocessed.
  ///
  /// In en, this message translates to:
  /// **'Unprocessed'**
  String get statusUnprocessed;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get statusShortlisted;

  /// No description provided for @statusInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get statusInterview;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @mySavedJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Saved Jobs'**
  String get mySavedJobsTitle;

  /// No description provided for @pleaseLoginSaved.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see saved jobs.'**
  String get pleaseLoginSaved;

  /// No description provided for @noSavedJobs.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any jobs yet.'**
  String get noSavedJobs;

  /// No description provided for @sortSalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get sortSalary;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get sortAlphabetical;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @langLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get langLabel;

  /// No description provided for @signOutBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutBtn;

  /// No description provided for @deleteAccBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccBtn;

  /// No description provided for @allMyJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'All my job'**
  String get allMyJobsTitle;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @employerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your employer account to manage hiring.'**
  String get employerLoginSubtitle;

  /// No description provided for @workEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Work Email'**
  String get workEmailLabel;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @createEmployerAccountBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Employer Account'**
  String get createEmployerAccountBtn;

  /// No description provided for @employerAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'Employer accounts are separate from jobseeker accounts. Only registered companies can access the employer portal.'**
  String get employerAccountNotice;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable pop-up alerts'**
  String get notificationsSubtitle;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account?'**
  String get signOutConfirm;

  /// No description provided for @companyInformation.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInformation;

  /// No description provided for @industryLabel.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get industryLabel;

  /// No description provided for @addPhone.
  ///
  /// In en, this message translates to:
  /// **'Add phone'**
  String get addPhone;

  /// No description provided for @addOfficeLocation.
  ///
  /// In en, this message translates to:
  /// **'Add office location'**
  String get addOfficeLocation;
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
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
