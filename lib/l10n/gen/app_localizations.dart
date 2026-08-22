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

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

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

  /// No description provided for @authLogoOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open the trip_io website'**
  String get authLogoOpenWebsite;

  /// No description provided for @authLogoOpenWebsiteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the website.'**
  String get authLogoOpenWebsiteFailed;

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

  /// No description provided for @navForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get navForYou;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

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

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask TIA'**
  String get aiChatTitle;

  /// No description provided for @aiChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with TIA about Yaoundé destinations and get personalized travel guidance.'**
  String get aiChatSubtitle;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask TIA about a place, or what to do today…'**
  String get aiChatInputHint;

  /// No description provided for @aiChatEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Ask TIA about visiting Yaoundé - I can suggest places based on your interests and guide your trip plan.'**
  String get aiChatEmptyState;

  /// No description provided for @aiChatErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach TIA.\n{error}'**
  String aiChatErrorMessage(String error);

  /// No description provided for @aiChatNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'TIA isn\'t set up yet. Please check back soon.'**
  String get aiChatNotConfigured;

  /// No description provided for @aiChatSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Try asking TIA'**
  String get aiChatSuggestionsLabel;

  /// No description provided for @aiChatSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'What\'s worth visiting in Yaoundé today?'**
  String get aiChatSuggestion1;

  /// No description provided for @aiChatSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Suggest a half-day culture itinerary'**
  String get aiChatSuggestion2;

  /// No description provided for @aiChatSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Where can I eat local Cameroonian food?'**
  String get aiChatSuggestion3;

  /// No description provided for @aiChatSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Best spot for a sunset view?'**
  String get aiChatSuggestion4;

  /// No description provided for @aiChatVoiceStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Record a voice message'**
  String get aiChatVoiceStartTooltip;

  /// No description provided for @aiChatVoiceStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get aiChatVoiceStopTooltip;

  /// No description provided for @aiChatVoiceEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that - try recording again.'**
  String get aiChatVoiceEmptyError;

  /// No description provided for @aiChatVoiceFailedError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t transcribe that. Please try again.'**
  String get aiChatVoiceFailedError;

  /// No description provided for @aiChatVoicePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is needed to record a voice message.'**
  String get aiChatVoicePermissionDenied;

  /// No description provided for @aiChatVoiceMuteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mute Tia\'s voice'**
  String get aiChatVoiceMuteTooltip;

  /// No description provided for @aiChatVoiceUnmuteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unmute Tia\'s voice'**
  String get aiChatVoiceUnmuteTooltip;

  /// No description provided for @aiExplainButton.
  ///
  /// In en, this message translates to:
  /// **'Ask TIA to explain'**
  String get aiExplainButton;

  /// No description provided for @aiExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'TIA explanation'**
  String get aiExplainTitle;

  /// No description provided for @aiExplainError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get an explanation right now.'**
  String get aiExplainError;

  /// No description provided for @aiLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that destination.'**
  String get aiLinkOpenFailed;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @commentsInputHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get commentsInputHint;

  /// No description provided for @commentsPostButton.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get commentsPostButton;

  /// No description provided for @commentsReplyButton.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentsReplyButton;

  /// No description provided for @commentsButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'View comments'**
  String get commentsButtonLabel;

  /// No description provided for @commentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet — be the first to share your thoughts.'**
  String get commentsEmpty;

  /// No description provided for @commentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load comments.\n{error}'**
  String commentsLoadError(String error);

  /// No description provided for @commentEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commentEditButton;

  /// No description provided for @commentDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commentDeleteButton;

  /// No description provided for @commentDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get commentDeleteConfirmTitle;

  /// No description provided for @commentDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get commentDeleteConfirmMessage;

  /// No description provided for @commentsNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commentsNewBadge;

  /// No description provided for @readAloudTooltip.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloudTooltip;

  /// No description provided for @readAloudStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop reading'**
  String get readAloudStopTooltip;

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

  /// No description provided for @destinationsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by interest'**
  String get destinationsFilterLabel;

  /// No description provided for @destinationsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get destinationsFilterClear;

  /// No description provided for @destinationsFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No destinations match the selected filters.'**
  String get destinationsFilterEmpty;

  /// No description provided for @destinationCardSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'View {name}'**
  String destinationCardSemanticLabel(String name);

  /// No description provided for @suggestDestinationButton.
  ///
  /// In en, this message translates to:
  /// **'Suggest a destination'**
  String get suggestDestinationButton;

  /// No description provided for @submitDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest a destination'**
  String get submitDestinationTitle;

  /// No description provided for @submitDestinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Know a real spot in Yaoundé that\'s missing? Suggest it here - an admin reviews every submission before it goes live.'**
  String get submitDestinationSubtitle;

  /// No description provided for @submitDestinationNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination name'**
  String get submitDestinationNameLabel;

  /// No description provided for @submitDestinationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get submitDestinationNameRequired;

  /// No description provided for @submitDestinationLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get submitDestinationLocationLabel;

  /// No description provided for @submitDestinationLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bastos, Yaoundé'**
  String get submitDestinationLocationHint;

  /// No description provided for @submitDestinationDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get submitDestinationDescriptionLabel;

  /// No description provided for @submitDestinationReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion won\'t appear in the app until an admin approves it.'**
  String get submitDestinationReviewNotice;

  /// No description provided for @submitDestinationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitDestinationButton;

  /// No description provided for @submitDestinationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your suggestion was submitted for review.'**
  String get submitDestinationSuccess;

  /// No description provided for @submitDestinationSuccessImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Your suggestion was submitted, but the photo failed to upload: {error}'**
  String submitDestinationSuccessImageFailed(String error);

  /// No description provided for @submitDestinationAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo (optional)'**
  String get submitDestinationAddPhoto;

  /// No description provided for @submitDestinationLocationPickButton.
  ///
  /// In en, this message translates to:
  /// **'Set location on map'**
  String get submitDestinationLocationPickButton;

  /// No description provided for @submitDestinationLocationPickedLabel.
  ///
  /// In en, this message translates to:
  /// **'Location set: {lat}, {lon}'**
  String submitDestinationLocationPickedLabel(String lat, String lon);

  /// No description provided for @pickLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get pickLocationTitle;

  /// No description provided for @pickLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place a pin at this destination\'s location'**
  String get pickLocationHint;

  /// No description provided for @pickLocationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get pickLocationConfirm;

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

  /// No description provided for @forYouTitle.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYouTitle;

  /// No description provided for @forYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A personalized mix of picks made for you and what\'s popular in Yaoundé.'**
  String get forYouSubtitle;

  /// No description provided for @forYouPersonalizedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get forYouPersonalizedSectionTitle;

  /// No description provided for @forYouTrendingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending in Yaoundé'**
  String get forYouTrendingSectionTitle;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Destinations you\'ve saved for later.'**
  String get favoritesSubtitle;

  /// No description provided for @favoritesErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load favorites.\n{error}'**
  String favoritesErrorMessage(String error);

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any destination to save it here.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @viewMySubmissionsButton.
  ///
  /// In en, this message translates to:
  /// **'My submissions'**
  String get viewMySubmissionsButton;

  /// No description provided for @mySubmissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your submissions'**
  String get mySubmissionsTitle;

  /// No description provided for @mySubmissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Destinations you\'ve suggested, and their review status.'**
  String get mySubmissionsSubtitle;

  /// No description provided for @mySubmissionsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load your submissions.\n{error}'**
  String mySubmissionsErrorMessage(String error);

  /// No description provided for @mySubmissionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get mySubmissionsEmptyTitle;

  /// No description provided for @mySubmissionsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest a destination and track its review status here.'**
  String get mySubmissionsEmptySubtitle;

  /// No description provided for @submissionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get submissionStatusPending;

  /// No description provided for @submissionStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get submissionStatusApproved;

  /// No description provided for @submissionStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get submissionStatusRejected;

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

  /// No description provided for @itineraryDeletedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Itinerary deleted.'**
  String get itineraryDeletedSnackbar;

  /// No description provided for @directionsButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directionsButtonTooltip;

  /// No description provided for @addToItineraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary'**
  String get addToItineraryTooltip;

  /// No description provided for @addToItinerarySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary'**
  String get addToItinerarySheetTitle;

  /// No description provided for @addToItineraryCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new itinerary'**
  String get addToItineraryCreateNew;

  /// No description provided for @addToItineraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any itineraries yet.'**
  String get addToItineraryEmpty;

  /// No description provided for @addToItineraryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to \"{title}\".'**
  String addToItineraryAdded(String title);

  /// No description provided for @addToItineraryAlready.
  ///
  /// In en, this message translates to:
  /// **'Already in \"{title}\".'**
  String addToItineraryAlready(String title);

  /// No description provided for @addToItineraryAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get addToItineraryAlreadyAdded;

  /// No description provided for @orderDestinationsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Order your visit'**
  String get orderDestinationsSheetTitle;

  /// No description provided for @orderDestinationsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to set the order you want to visit these in.'**
  String get orderDestinationsSheetSubtitle;

  /// No description provided for @orderDestinationsConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get orderDestinationsConfirmButton;

  /// No description provided for @mapOptionsToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Map options'**
  String get mapOptionsToggleTooltip;

  /// No description provided for @mapSelectItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Select itinerary'**
  String get mapSelectItineraryButton;

  /// No description provided for @mapSelectItinerarySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an itinerary'**
  String get mapSelectItinerarySheetTitle;

  /// No description provided for @mapLeaveItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Leave itinerary'**
  String get mapLeaveItineraryButton;

  /// No description provided for @mapNoItinerariesAvailable.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any itineraries yet.'**
  String get mapNoItinerariesAvailable;

  /// No description provided for @mapItineraryProgress.
  ///
  /// In en, this message translates to:
  /// **'{visited} of {total} visited'**
  String mapItineraryProgress(int visited, int total);

  /// No description provided for @mapNextStopSummary.
  ///
  /// In en, this message translates to:
  /// **'Next stop: {distance} · {duration}'**
  String mapNextStopSummary(String distance, String duration);

  /// No description provided for @mapRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get mapRemainingLabel;

  /// No description provided for @mapItineraryCompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'All stops visited'**
  String get mapItineraryCompleteLabel;

  /// No description provided for @mapAmenitiesToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Nearby amenities'**
  String get mapAmenitiesToggleTooltip;

  /// No description provided for @mapAmenitiesLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby amenities'**
  String get mapAmenitiesLegendTitle;

  /// No description provided for @mapAmenitiesShowToggle.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get mapAmenitiesShowToggle;

  /// No description provided for @mapAmenitiesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No amenities found nearby.'**
  String get mapAmenitiesEmptyHint;

  /// No description provided for @mapAmenityCategoryHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get mapAmenityCategoryHospital;

  /// No description provided for @mapAmenityCategoryPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get mapAmenityCategoryPharmacy;

  /// No description provided for @mapAmenityCategoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel stations'**
  String get mapAmenityCategoryFuel;

  /// No description provided for @mapAmenityCategoryHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get mapAmenityCategoryHotel;

  /// No description provided for @mapAmenityCategoryBankAtm.
  ///
  /// In en, this message translates to:
  /// **'Banks & ATMs'**
  String get mapAmenityCategoryBankAtm;

  /// No description provided for @mapAmenityCategoryPolice.
  ///
  /// In en, this message translates to:
  /// **'Police stations'**
  String get mapAmenityCategoryPolice;

  /// No description provided for @mapAmenityDirectionsButton.
  ///
  /// In en, this message translates to:
  /// **'Directions to here'**
  String get mapAmenityDirectionsButton;

  /// No description provided for @mapYangoButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Book a taxi'**
  String get mapYangoButtonTooltip;

  /// No description provided for @mapYangoLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the taxi app.'**
  String get mapYangoLaunchFailed;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get mapTitle;

  /// No description provided for @mapFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get mapFromLabel;

  /// No description provided for @mapToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get mapToLabel;

  /// No description provided for @mapSwapButton.
  ///
  /// In en, this message translates to:
  /// **'Swap origin and destination'**
  String get mapSwapButton;

  /// No description provided for @mapClearRoute.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mapClearRoute;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations…'**
  String get mapSearchHint;

  /// No description provided for @mapNoCoordinates.
  ///
  /// In en, this message translates to:
  /// **'This destination has no location set yet'**
  String get mapNoCoordinates;

  /// No description provided for @mapProfileDriving.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get mapProfileDriving;

  /// No description provided for @mapProfileWalking.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get mapProfileWalking;

  /// No description provided for @mapProfileCycling.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get mapProfileCycling;

  /// No description provided for @mapRoutingNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Directions aren\'t set up yet. Please check back soon.'**
  String get mapRoutingNotConfigured;

  /// No description provided for @mapNoRouteFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a route between these points. One of them may be unreachable - check the destinations and your location.'**
  String get mapNoRouteFound;

  /// No description provided for @mapLocationTooFar.
  ///
  /// In en, this message translates to:
  /// **'Your current location seems far from these destinations. Check that location services are giving an accurate fix, then try again.'**
  String get mapLocationTooFar;

  /// No description provided for @viewOnMapButton.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMapButton;

  /// No description provided for @playVideoButton.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideoButton;

  /// No description provided for @videoCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close video'**
  String get videoCloseTooltip;

  /// No description provided for @videoLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this video.'**
  String get videoLoadError;

  /// No description provided for @videoLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the video link.'**
  String get videoLaunchFailed;

  /// No description provided for @mapLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access is needed to show your position on the map. Please allow it in your device settings.'**
  String get mapLocationPermissionDenied;

  /// No description provided for @mapLocationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services on your device to show your position on the map.'**
  String get mapLocationServicesDisabled;

  /// No description provided for @mapLocateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Please try again.'**
  String get mapLocateFailed;

  /// No description provided for @mapLocationApproximate.
  ///
  /// In en, this message translates to:
  /// **'Your location is approximate - without GPS (e.g. on a desktop browser), position is estimated from WiFi/network data instead.'**
  String get mapLocationApproximate;

  /// No description provided for @mapRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get mapRetryButton;

  /// No description provided for @mapUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get mapUseMyLocation;

  /// No description provided for @mapMyLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'My current location'**
  String get mapMyLocationLabel;

  /// No description provided for @mapResolvingLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get mapResolvingLocation;

  /// No description provided for @startItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Start itinerary'**
  String get startItineraryButton;

  /// No description provided for @mapRouteError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get directions.\n{error}'**
  String mapRouteError(String error);

  /// No description provided for @deleteItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItineraryButton;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign back in to see your itineraries and favorites.'**
  String get logoutConfirmMessage;

  /// No description provided for @deleteItineraryConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this itinerary?'**
  String get deleteItineraryConfirmTitle;

  /// No description provided for @deleteItineraryConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently deleted. This can\'t be undone.'**
  String deleteItineraryConfirmMessage(String title);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email and we\'ll send you a reset code.'**
  String get forgotPasswordStep1Subtitle;

  /// No description provided for @forgotPasswordIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get forgotPasswordIdentifierLabel;

  /// No description provided for @forgotPasswordIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email'**
  String get forgotPasswordIdentifierRequired;

  /// No description provided for @forgotPasswordSendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotPasswordSendCodeButton;

  /// No description provided for @forgotPasswordCodeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for \"{identifier}\", a reset code has been sent.'**
  String forgotPasswordCodeSentMessage(String identifier);

  /// No description provided for @forgotPasswordStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you, along with a new password.'**
  String get forgotPasswordStep2Subtitle;

  /// No description provided for @forgotPasswordCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get forgotPasswordCodeLabel;

  /// No description provided for @forgotPasswordCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get forgotPasswordCodeHint;

  /// No description provided for @forgotPasswordCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email'**
  String get forgotPasswordCodeRequired;

  /// No description provided for @forgotPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get forgotPasswordNewPasswordLabel;

  /// No description provided for @forgotPasswordResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordResetButton;

  /// No description provided for @forgotPasswordSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password updated. You can now sign in.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @forgotPasswordResendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get forgotPasswordResendCodeButton;

  /// No description provided for @forgotPasswordChangeIdentifierButton.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get forgotPasswordChangeIdentifierButton;

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

  /// No description provided for @itineraryDestinationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations to add…'**
  String get itineraryDestinationSearchHint;

  /// No description provided for @itineraryShowAllDestinations.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} destinations'**
  String itineraryShowAllDestinations(int count);

  /// No description provided for @itineraryHideAllDestinations.
  ///
  /// In en, this message translates to:
  /// **'Hide full list'**
  String get itineraryHideAllDestinations;

  /// No description provided for @itineraryDestinationSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by name, or tap \"show all\" to browse every destination.'**
  String get itineraryDestinationSearchPrompt;

  /// No description provided for @itineraryDestinationSearchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No destinations match \"{query}\".'**
  String itineraryDestinationSearchNoMatches(String query);

  /// No description provided for @itineraryAllDestinationsAdded.
  ///
  /// In en, this message translates to:
  /// **'All destinations have been added.'**
  String get itineraryAllDestinationsAdded;

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

  /// No description provided for @itineraryCardSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Open itinerary {title}'**
  String itineraryCardSemanticLabel(String title);

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

  /// No description provided for @itineraryAvailableTimePerDay.
  ///
  /// In en, this message translates to:
  /// **'Available time per day: {duration}'**
  String itineraryAvailableTimePerDay(String duration);

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

  /// No description provided for @tripDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip dates'**
  String get tripDatesLabel;

  /// No description provided for @tripDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Choose start and end date'**
  String get tripDatesHint;

  /// No description provided for @itineraryTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this trip a title.'**
  String get itineraryTitleRequired;

  /// No description provided for @itineraryDestinationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one destination.'**
  String get itineraryDestinationsRequired;

  /// No description provided for @itineraryDayCountLabel.
  ///
  /// In en, this message translates to:
  /// **'This is a {count}-day trip'**
  String itineraryDayCountLabel(int count);

  /// No description provided for @itineraryDayCountToday.
  ///
  /// In en, this message translates to:
  /// **'This is a 1-day trip (today)'**
  String get itineraryDayCountToday;

  /// No description provided for @newItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'New itinerary'**
  String get newItineraryButton;

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

  /// No description provided for @favoritesStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesStatLabel;

  /// No description provided for @placesPlannedStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Places planned'**
  String get placesPlannedStatLabel;

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

  /// No description provided for @avatarSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to change your profile photo'**
  String get avatarSemanticLabel;

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

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @interestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Areas of interest'**
  String get interestsLabel;

  /// No description provided for @interestsHelper.
  ///
  /// In en, this message translates to:
  /// **'Pick a few things you enjoy - we\'ll use these to recommend Yaoundé spots for you.'**
  String get interestsHelper;

  /// No description provided for @interestsUpdatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Interests updated.'**
  String get interestsUpdatedSnackbar;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Eat & stay nearby'**
  String get nearbyTitle;

  /// No description provided for @nearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real restaurants and hotels close to this spot.'**
  String get nearbySubtitle;

  /// No description provided for @practicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get practicalInfoTitle;

  /// No description provided for @openingHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get openingHoursLabel;

  /// No description provided for @entryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry fee'**
  String get entryFeeLabel;

  /// No description provided for @tipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tipsLabel;

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

  /// No description provided for @shareItineraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share this itinerary'**
  String get shareItineraryTooltip;

  /// No description provided for @shareItineraryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Share \"{title}\"'**
  String shareItineraryDialogTitle(String title);

  /// No description provided for @shareItineraryDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Anyone who opens this link gets their own copy of this itinerary added straight to their trip_io account - they\'ll be asked to create one first if they don\'t have one yet. The link keeps working for everyone you send it to until you turn sharing off.'**
  String get shareItineraryDialogMessage;

  /// No description provided for @shareItineraryCopyLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get shareItineraryCopyLinkButton;

  /// No description provided for @shareItineraryLinkCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard.'**
  String get shareItineraryLinkCopiedSnackbar;

  /// No description provided for @shareItineraryTurnOffButton.
  ///
  /// In en, this message translates to:
  /// **'Turn off sharing'**
  String get shareItineraryTurnOffButton;

  /// No description provided for @shareItineraryTurnedOffSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sharing turned off. The old link no longer works.'**
  String get shareItineraryTurnedOffSnackbar;

  /// No description provided for @shareItineraryErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create a share link right now.'**
  String get shareItineraryErrorSnackbar;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @claimedItinerarySnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added to your itineraries.'**
  String get claimedItinerarySnackbar;

  /// No description provided for @claimedItineraryErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that shared itinerary to your account.'**
  String get claimedItineraryErrorSnackbar;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Yaoundé'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Browse real, hand-picked landmarks, culture, markets and nature across Yaoundé, Cameroon.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Get picks made for you'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you\'re into and we\'ll surface the spots you\'re most likely to enjoy.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Pick your stops and how much time you have - trip_io builds a timed schedule for you.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Navigate as you go'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Follow turn-by-turn directions and see every stop, numbered in order, right on the map.'**
  String get onboardingPage4Body;

  /// No description provided for @avatarCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust photo'**
  String get avatarCropTitle;

  /// No description provided for @avatarCropConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get avatarCropConfirmButton;

  /// No description provided for @avatarCropHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reposition, pinch or scroll to zoom.'**
  String get avatarCropHint;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders and updates on your submissions.'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications.\n{error}'**
  String notificationsErrorMessage(String error);

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation notices and trip reminders will show up here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationDestinationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission update'**
  String get notificationDestinationStatusTitle;

  /// No description provided for @notificationDestinationApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" was approved and is now live.'**
  String notificationDestinationApprovedBody(String name);

  /// No description provided for @notificationDestinationRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" wasn\'t approved this time.'**
  String notificationDestinationRejectedBody(String name);

  /// No description provided for @notificationTripReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trip'**
  String get notificationTripReminderTitle;

  /// No description provided for @notificationTripReminderBodyToday.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" starts today.'**
  String notificationTripReminderBodyToday(String title);

  /// No description provided for @notificationTripReminderBodyInDays.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" starts in {days} days.'**
  String notificationTripReminderBodyInDays(String title, String days);
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
