// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'trip_io';

  @override
  String get authLoginTitle => 'Log In';

  @override
  String get authRegisterTitle => 'Register';

  @override
  String get authLoginSubtitle =>
      'Sign in to continue planning and managing your trips.';

  @override
  String get authRegisterSubtitle =>
      'Create your account to save itineraries and get recommendations.';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailHelper =>
      'We use this for account contact and profile info';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authUsernameHelper => 'This is your account login name';

  @override
  String get authUsernameRequired => 'Username is required';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get authLoginTip =>
      'Tip: use the correct username and password you used in your account creation.';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authToggleToRegister => 'No account? Register';

  @override
  String get authToggleToLogin => 'Already have an account? Login';

  @override
  String get authOrDivider => 'or';

  @override
  String get authTaglineTitle => 'Plan faster. Travel smarter.';

  @override
  String get authTaglineSubtitle =>
      'Search destinations, create itineraries, and keep your account synced across mobile, web, and Windows.';

  @override
  String get authFeatureMobile => 'Mobile ready';

  @override
  String get authFeatureWeb => 'Web ready';

  @override
  String get authFeatureDesktop => 'Desktop ready';

  @override
  String get navDestinations => 'Destinations';

  @override
  String get navRecommendations => 'Recommendations';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navItineraries => 'Itineraries';

  @override
  String get navAskAi => 'Ask AI';

  @override
  String get navProfile => 'Profile';

  @override
  String get aiChatTitle => 'Ask AI';

  @override
  String get aiChatSubtitle =>
      'Chat about Yaoundé destinations and get personalized suggestions.';

  @override
  String get aiChatInputHint => 'Ask about a place, or what to do today…';

  @override
  String get aiChatEmptyState =>
      'Ask me anything about visiting Yaoundé - I can suggest spots based on your interests or explain what makes a place worth a visit.';

  @override
  String aiChatErrorMessage(String error) {
    return 'Couldn\'t reach the AI assistant.\n$error';
  }

  @override
  String get aiChatNotConfigured =>
      'The AI assistant isn\'t set up yet. Please check back soon.';

  @override
  String get aiExplainButton => 'Ask AI to explain';

  @override
  String get aiExplainTitle => 'AI explanation';

  @override
  String get aiExplainError => 'Couldn\'t get an explanation right now.';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get commentsInputHint => 'Add a comment…';

  @override
  String get commentsPostButton => 'Post';

  @override
  String get commentsReplyButton => 'Reply';

  @override
  String get commentsEmpty =>
      'No comments yet — be the first to share your thoughts.';

  @override
  String commentsLoadError(String error) {
    return 'Couldn\'t load comments.\n$error';
  }

  @override
  String get destinationsTitle => 'Yaoundé Destinations';

  @override
  String get destinationsSubtitle =>
      'Search Cameroon\'s capital for landmarks, culture and nature spots.';

  @override
  String get destinationsSearchHint => 'Search destinations by name or tag';

  @override
  String get searchButton => 'Search';

  @override
  String get destinationsEmpty => 'No destinations found.';

  @override
  String get destinationsFilterLabel => 'Filter by interest';

  @override
  String get destinationsFilterClear => 'Clear';

  @override
  String get destinationsFilterEmpty =>
      'No destinations match the selected filters.';

  @override
  String get suggestDestinationButton => 'Suggest a destination';

  @override
  String get submitDestinationTitle => 'Suggest a destination';

  @override
  String get submitDestinationSubtitle =>
      'Know a real spot in Yaoundé that\'s missing? Suggest it here - an admin reviews every submission before it goes live.';

  @override
  String get submitDestinationNameLabel => 'Destination name';

  @override
  String get submitDestinationNameRequired => 'Name is required';

  @override
  String get submitDestinationLocationLabel => 'Location';

  @override
  String get submitDestinationLocationHint => 'e.g. Bastos, Yaoundé';

  @override
  String get submitDestinationDescriptionLabel => 'Description';

  @override
  String get submitDestinationReviewNotice =>
      'Your suggestion won\'t appear in the app until an admin approves it.';

  @override
  String get submitDestinationButton => 'Submit for review';

  @override
  String get submitDestinationSuccess =>
      'Thanks! Your suggestion was submitted for review.';

  @override
  String submitDestinationSuccessImageFailed(String error) {
    return 'Your suggestion was submitted, but the photo failed to upload: $error';
  }

  @override
  String get submitDestinationAddPhoto => 'Add a photo (optional)';

  @override
  String get recommendationsTitle => 'Picked for you';

  @override
  String get recommendationsSubtitle =>
      'A quick shortlist of Yaoundé spots worth adding to your itinerary.';

  @override
  String recommendationsErrorMessage(String error) {
    return 'Could not load recommendations.\n$error';
  }

  @override
  String get recommendationsEmptyTitle => 'No recommendations yet';

  @override
  String get recommendationsEmptySubtitle =>
      'Browse destinations and we\'ll start suggesting spots for you.';

  @override
  String get favoritesTitle => 'Your favorites';

  @override
  String get favoritesSubtitle => 'Destinations you\'ve saved for later.';

  @override
  String favoritesErrorMessage(String error) {
    return 'Could not load favorites.\n$error';
  }

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Tap the heart on any destination to save it here.';

  @override
  String get itinerariesFormMissing =>
      'Add a title and pick at least one destination.';

  @override
  String get itineraryCreatedSnackbar => 'Itinerary created.';

  @override
  String get itinerariesPlanTitle => 'Plan a new itinerary';

  @override
  String get itineraryTitleLabel => 'Itinerary title';

  @override
  String get itineraryTitleHint => 'My Yaoundé weekend';

  @override
  String get destinationsLabel => 'Destinations';

  @override
  String get noDestinationsAvailable => 'No destinations available yet.';

  @override
  String get itineraryDestinationSearchHint => 'Search destinations to add…';

  @override
  String itineraryShowAllDestinations(int count) {
    return 'Show all $count destinations';
  }

  @override
  String get itineraryHideAllDestinations => 'Hide full list';

  @override
  String get itineraryDestinationSearchPrompt =>
      'Search by name, or tap \"show all\" to browse every destination.';

  @override
  String itineraryDestinationSearchNoMatches(String query) {
    return 'No destinations match \"$query\".';
  }

  @override
  String get itineraryAllDestinationsAdded =>
      'All destinations have been added.';

  @override
  String get createItineraryButton => 'Create Itinerary';

  @override
  String itinerariesErrorMessage(String error) {
    return 'Could not load itineraries.\n$error';
  }

  @override
  String get itinerariesEmptyTitle => 'No itineraries yet';

  @override
  String get itinerariesEmptySubtitle =>
      'Pick a few destinations above and create your first plan.';

  @override
  String get yourItinerariesTitle => 'Your itineraries';

  @override
  String destinationsLoadError(String error) {
    return 'Could not load destinations.\n$error';
  }

  @override
  String itineraryStartTime(String time) {
    return 'Start time: $time';
  }

  @override
  String itineraryAvailableTime(String duration) {
    return 'Available time: $duration';
  }

  @override
  String itineraryAvailableTimePerDay(String duration) {
    return 'Available time per day: $duration';
  }

  @override
  String itineraryOverrunWarning(String extra, String minStop) {
    return 'This plan needs about $extra more than you have available, so stops get $minStop min each at minimum.';
  }

  @override
  String get itineraryPlanSectionTitle => 'Your plan';

  @override
  String itineraryStopsSummary(String count, String duration) {
    return '$count stops · $duration total';
  }

  @override
  String get itineraryNoSchedule => 'No timed plan for this itinerary yet.';

  @override
  String get itineraryTravelTime => 'Travel time';

  @override
  String get tripDatesLabel => 'Trip dates';

  @override
  String get tripDatesHint => 'Choose start and end date';

  @override
  String get memberSinceDevice => 'Member since this device';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get basedInYaounde => 'Based in Yaoundé, Cameroon';

  @override
  String get itinerariesStatLabel => 'Itineraries';

  @override
  String get regionStatLabel => 'Region';

  @override
  String get featuredSpotsStatLabel => 'Featured spots';

  @override
  String get aboutMeTitle => 'About me';

  @override
  String get bioHint => 'Tell fellow travellers a bit about yourself...';

  @override
  String get saveButton => 'Save';

  @override
  String get bioUpdatedSnackbar => 'Bio updated.';

  @override
  String signedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get unknownUser => 'unknown';

  @override
  String get logoutButton => 'Logout';

  @override
  String get travellerFallback => 'Traveller';

  @override
  String couldNotPickImage(String error) {
    return 'Could not pick image: $error';
  }

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get interestsLabel => 'Areas of interest';

  @override
  String get interestsHelper =>
      'Pick a few things you enjoy - we\'ll use these to recommend Yaoundé spots for you.';

  @override
  String get interestsUpdatedSnackbar => 'Interests updated.';

  @override
  String get nearbyTitle => 'Eat & stay nearby';

  @override
  String get nearbySubtitle =>
      'Real restaurants and hotels close to this spot.';

  @override
  String get practicalInfoTitle => 'Good to know';

  @override
  String get openingHoursLabel => 'Opening hours';

  @override
  String get entryFeeLabel => 'Entry fee';

  @override
  String get tipsLabel => 'Tips';

  @override
  String get sessionExpiredTitle => 'Your session has expired';

  @override
  String get sessionExpiredSubtitle => 'Please sign in again to continue.';

  @override
  String get signInAgainButton => 'Sign in again';
}
