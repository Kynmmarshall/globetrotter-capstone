import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'trip_io'**
  String get appTitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLoginTitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue planning and managing your trips.'**
  String get authLoginSubtitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to save itineraries and get recommendations.'**
  String get authRegisterSubtitle;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'We use this for account contact and profile info'**
  String get authEmailHelper;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameHelper.
  ///
  /// In en, this message translates to:
  /// **'This is your account login name'**
  String get authUsernameHelper;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get authUsernameRequired;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsMismatch;

  /// No description provided for @authLoginTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: use the correct username and password you used in your account creation.'**
  String get authLoginTip;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// No description provided for @authToggleToRegister.
  ///
  /// In en, this message translates to:
  /// **'No account? Register'**
  String get authToggleToRegister;

  /// No description provided for @authToggleToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get authToggleToLogin;

  /// No description provided for @authTaglineTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan faster. Travel smarter.'**
  String get authTaglineTitle;

  /// No description provided for @authTaglineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search destinations, create itineraries, and keep your account synced across mobile, web, and Windows.'**
  String get authTaglineSubtitle;

  /// No description provided for @authFeatureMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile ready'**
  String get authFeatureMobile;

  /// No description provided for @authFeatureWeb.
  ///
  /// In en, this message translates to:
  /// **'Web ready'**
  String get authFeatureWeb;

  /// No description provided for @authFeatureDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop ready'**
  String get authFeatureDesktop;

  /// No description provided for @navDestinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get navDestinations;

  /// No description provided for @navRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get navRecommendations;

  /// No description provided for @navItineraries.
  ///
  /// In en, this message translates to:
  /// **'Itineraries'**
  String get navItineraries;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @destinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Yaoundé Destinations'**
  String get destinationsTitle;

  /// No description provided for @destinationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search Cameroon\'s capital for landmarks, culture and nature spots.'**
  String get destinationsSubtitle;

  /// No description provided for @destinationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations by name or tag'**
  String get destinationsSearchHint;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @destinationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No destinations found.'**
  String get destinationsEmpty;

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A quick shortlist of Yaoundé spots worth adding to your itinerary.'**
  String get recommendationsSubtitle;

  /// No description provided for @recommendationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load recommendations.\n{error}'**
  String recommendationsErrorMessage(String error);

  /// No description provided for @recommendationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get recommendationsEmptyTitle;

  /// No description provided for @recommendationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse destinations and we\'ll start suggesting spots for you.'**
  String get recommendationsEmptySubtitle;

  /// No description provided for @itinerariesFormMissing.
  ///
  /// In en, this message translates to:
  /// **'Add a title and pick at least one destination.'**
  String get itinerariesFormMissing;

  /// No description provided for @itineraryCreatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Itinerary created.'**
  String get itineraryCreatedSnackbar;

  /// No description provided for @itinerariesPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a new itinerary'**
  String get itinerariesPlanTitle;

  /// No description provided for @itineraryTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Itinerary title'**
  String get itineraryTitleLabel;

  /// No description provided for @itineraryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'My Yaoundé weekend'**
  String get itineraryTitleHint;

  /// No description provided for @destinationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get destinationsLabel;

  /// No description provided for @noDestinationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No destinations available yet.'**
  String get noDestinationsAvailable;

  /// No description provided for @createItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Create Itinerary'**
  String get createItineraryButton;

  /// No description provided for @itinerariesErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load itineraries.\n{error}'**
  String itinerariesErrorMessage(String error);

  /// No description provided for @itinerariesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No itineraries yet'**
  String get itinerariesEmptyTitle;

  /// No description provided for @itinerariesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a few destinations above and create your first plan.'**
  String get itinerariesEmptySubtitle;

  /// No description provided for @yourItinerariesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your itineraries'**
  String get yourItinerariesTitle;

  /// No description provided for @destinationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load destinations.\n{error}'**
  String destinationsLoadError(String error);

  /// No description provided for @itineraryStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time: {time}'**
  String itineraryStartTime(String time);

  /// No description provided for @itineraryAvailableTime.
  ///
  /// In en, this message translates to:
  /// **'Available time: {duration}'**
  String itineraryAvailableTime(String duration);

  /// No description provided for @itineraryOverrunWarning.
  ///
  /// In en, this message translates to:
  /// **'This plan needs about {extra} more than you have available, so stops get {minStop} min each at minimum.'**
  String itineraryOverrunWarning(String extra, String minStop);

  /// No description provided for @itineraryPlanSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get itineraryPlanSectionTitle;

  /// No description provided for @itineraryStopsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} stops · {duration} total'**
  String itineraryStopsSummary(String count, String duration);

  /// No description provided for @itineraryNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'No timed plan for this itinerary yet.'**
  String get itineraryNoSchedule;

  /// No description provided for @itineraryTravelTime.
  ///
  /// In en, this message translates to:
  /// **'Travel time'**
  String get itineraryTravelTime;

  /// No description provided for @memberSinceDevice.
  ///
  /// In en, this message translates to:
  /// **'Member since this device'**
  String get memberSinceDevice;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @basedInYaounde.
  ///
  /// In en, this message translates to:
  /// **'Based in Yaoundé, Cameroon'**
  String get basedInYaounde;

  /// No description provided for @itinerariesStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Itineraries'**
  String get itinerariesStatLabel;

  /// No description provided for @regionStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionStatLabel;

  /// No description provided for @featuredSpotsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Featured spots'**
  String get featuredSpotsStatLabel;

  /// No description provided for @aboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMeTitle;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell fellow travellers a bit about yourself...'**
  String get bioHint;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @bioUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Bio updated.'**
  String get bioUpdatedSnackbar;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}'**
  String signedInAs(String username);

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknownUser;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @travellerFallback.
  ///
  /// In en, this message translates to:
  /// **'Traveller'**
  String get travellerFallback;

  /// No description provided for @couldNotPickImage.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image: {error}'**
  String couldNotPickImage(String error);

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get sessionExpiredSubtitle;

  /// No description provided for @signInAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgainButton;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
