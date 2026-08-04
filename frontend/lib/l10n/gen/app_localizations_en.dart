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
  String get navForYou => 'For You';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navItineraries => 'Itineraries';

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
  String get aiChatSuggestionsLabel => 'Try asking';

  @override
  String get aiChatSuggestion1 => 'What\'s worth visiting in Yaoundé today?';

  @override
  String get aiChatSuggestion2 => 'Suggest a half-day culture itinerary';

  @override
  String get aiChatSuggestion3 => 'Where can I eat local Cameroonian food?';

  @override
  String get aiChatSuggestion4 => 'Best spot for a sunset view?';

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
  String get commentsButtonLabel => 'View comments';

  @override
  String get commentsEmpty =>
      'No comments yet — be the first to share your thoughts.';

  @override
  String commentsLoadError(String error) {
    return 'Couldn\'t load comments.\n$error';
  }

  @override
  String get commentEditButton => 'Edit';

  @override
  String get commentDeleteButton => 'Delete';

  @override
  String get commentDeleteConfirmTitle => 'Delete this comment?';

  @override
  String get commentDeleteConfirmMessage => 'This can\'t be undone.';

  @override
  String get commentsNewBadge => 'New';

  @override
  String get readAloudTooltip => 'Read aloud';

  @override
  String get readAloudStopTooltip => 'Stop reading';

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
  String destinationCardSemanticLabel(String name) {
    return 'View $name';
  }

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
  String get submitDestinationLocationPickButton => 'Set location on map';

  @override
  String submitDestinationLocationPickedLabel(String lat, String lon) {
    return 'Location set: $lat, $lon';
  }

  @override
  String get pickLocationTitle => 'Pick location';

  @override
  String get pickLocationHint =>
      'Tap the map to place a pin at this destination\'s location';

  @override
  String get pickLocationConfirm => 'Use this location';

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
  String get forYouTitle => 'For You';

  @override
  String get forYouSubtitle =>
      'A personalized mix of picks made for you and what\'s popular in Yaoundé.';

  @override
  String get forYouPersonalizedSectionTitle => 'Picked for you';

  @override
  String get forYouTrendingSectionTitle => 'Trending in Yaoundé';

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
  String get viewMySubmissionsButton => 'My submissions';

  @override
  String get mySubmissionsTitle => 'Your submissions';

  @override
  String get mySubmissionsSubtitle =>
      'Destinations you\'ve suggested, and their review status.';

  @override
  String mySubmissionsErrorMessage(String error) {
    return 'Could not load your submissions.\n$error';
  }

  @override
  String get mySubmissionsEmptyTitle => 'No submissions yet';

  @override
  String get mySubmissionsEmptySubtitle =>
      'Suggest a destination and track its review status here.';

  @override
  String get submissionStatusPending => 'Pending review';

  @override
  String get submissionStatusApproved => 'Approved';

  @override
  String get submissionStatusRejected => 'Not approved';

  @override
  String get itinerariesFormMissing =>
      'Add a title and pick at least one destination.';

  @override
  String get itineraryCreatedSnackbar => 'Itinerary created.';

  @override
  String get itineraryDeletedSnackbar => 'Itinerary deleted.';

  @override
  String get directionsButtonTooltip => 'Directions';

  @override
  String get addToItineraryTooltip => 'Add to itinerary';

  @override
  String get addToItinerarySheetTitle => 'Add to itinerary';

  @override
  String get addToItineraryCreateNew => 'Create new itinerary';

  @override
  String get addToItineraryEmpty => 'You don\'t have any itineraries yet.';

  @override
  String addToItineraryAdded(String title) {
    return 'Added to \"$title\".';
  }

  @override
  String addToItineraryAlready(String title) {
    return 'Already in \"$title\".';
  }

  @override
  String get addToItineraryAlreadyAdded => 'Already added';

  @override
  String get addToItineraryNewDialogTitle => 'New itinerary';

  @override
  String get orderDestinationsSheetTitle => 'Order your visit';

  @override
  String get orderDestinationsSheetSubtitle =>
      'Drag to set the order you want to visit these in.';

  @override
  String get orderDestinationsConfirmButton => 'Confirm order';

  @override
  String get mapOptionsToggleTooltip => 'Map options';

  @override
  String get mapSelectItineraryButton => 'Select itinerary';

  @override
  String get mapSelectItinerarySheetTitle => 'Choose an itinerary';

  @override
  String get mapLeaveItineraryButton => 'Leave itinerary';

  @override
  String get mapNoItinerariesAvailable =>
      'You don\'t have any itineraries yet.';

  @override
  String mapItineraryProgress(int visited, int total) {
    return '$visited of $total visited';
  }

  @override
  String get navMap => 'Map';

  @override
  String get mapTitle => 'Get directions';

  @override
  String get mapFromLabel => 'From';

  @override
  String get mapToLabel => 'To';

  @override
  String get mapSwapButton => 'Swap origin and destination';

  @override
  String get mapClearRoute => 'Clear';

  @override
  String get mapSearchHint => 'Search destinations…';

  @override
  String get mapNoCoordinates => 'This destination has no location set yet';

  @override
  String get mapProfileDriving => 'Drive';

  @override
  String get mapProfileWalking => 'Walk';

  @override
  String get mapProfileCycling => 'Bike';

  @override
  String get mapRoutingNotConfigured =>
      'Directions aren\'t set up yet. Please check back soon.';

  @override
  String get mapNoRouteFound =>
      'We couldn\'t find a route between these points. One of them may be unreachable - check the destinations and your location.';

  @override
  String get mapLocationTooFar =>
      'Your current location seems far from these destinations. Check that location services are giving an accurate fix, then try again.';

  @override
  String get viewOnMapButton => 'View on map';

  @override
  String get mapLocationPermissionDenied =>
      'Location access is needed to show your position on the map. Please allow it in your device settings.';

  @override
  String get mapLocationServicesDisabled =>
      'Turn on location services on your device to show your position on the map.';

  @override
  String get mapLocateFailed =>
      'Couldn\'t get your location. Please try again.';

  @override
  String get mapLocationApproximate =>
      'Your location is approximate - without GPS (e.g. on a desktop browser), position is estimated from WiFi/network data instead.';

  @override
  String get mapRetryButton => 'Retry';

  @override
  String get mapUseMyLocation => 'Use my current location';

  @override
  String get mapMyLocationLabel => 'My current location';

  @override
  String get mapResolvingLocation => 'Finding your location…';

  @override
  String get startItineraryButton => 'Start itinerary';

  @override
  String mapRouteError(String error) {
    return 'Couldn\'t get directions.\n$error';
  }

  @override
  String get deleteItineraryButton => 'Delete';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You\'ll need to sign back in to see your itineraries and favorites.';

  @override
  String get deleteItineraryConfirmTitle => 'Delete this itinerary?';

  @override
  String deleteItineraryConfirmMessage(String title) {
    return '\"$title\" will be permanently deleted. This can\'t be undone.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordStep1Subtitle =>
      'Enter your username or email and we\'ll send you a reset code.';

  @override
  String get forgotPasswordIdentifierLabel => 'Username or email';

  @override
  String get forgotPasswordIdentifierRequired => 'Enter your username or email';

  @override
  String get forgotPasswordSendCodeButton => 'Send code';

  @override
  String forgotPasswordCodeSentMessage(String identifier) {
    return 'If an account exists for \"$identifier\", a reset code has been sent.';
  }

  @override
  String get forgotPasswordStep2Subtitle =>
      'Enter the code we sent you, along with a new password.';

  @override
  String get forgotPasswordCodeLabel => 'Reset code';

  @override
  String get forgotPasswordCodeHint => '6-digit code';

  @override
  String get forgotPasswordCodeRequired => 'Enter the code from your email';

  @override
  String get forgotPasswordNewPasswordLabel => 'New password';

  @override
  String get forgotPasswordResetButton => 'Reset password';

  @override
  String get forgotPasswordSuccessMessage =>
      'Password updated. You can now sign in.';

  @override
  String get forgotPasswordResendCodeButton => 'Resend code';

  @override
  String get forgotPasswordChangeIdentifierButton => 'Use a different account';

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
  String itineraryCardSemanticLabel(String title) {
    return 'Open itinerary $title';
  }

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
  String get favoritesStatLabel => 'Favorites';

  @override
  String get placesPlannedStatLabel => 'Places planned';

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
  String get avatarSemanticLabel => 'Tap to change your profile photo';

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
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

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

  @override
  String get shareItineraryTooltip => 'Share this itinerary';

  @override
  String shareItineraryDialogTitle(String title) {
    return 'Share \"$title\"';
  }

  @override
  String get shareItineraryDialogMessage =>
      'Anyone who opens this link gets their own copy of this itinerary added straight to their trip_io account - they\'ll be asked to create one first if they don\'t have one yet. The link keeps working for everyone you send it to until you turn sharing off.';

  @override
  String get shareItineraryCopyLinkButton => 'Copy link';

  @override
  String get shareItineraryLinkCopiedSnackbar => 'Link copied to clipboard.';

  @override
  String get shareItineraryTurnOffButton => 'Turn off sharing';

  @override
  String get shareItineraryTurnedOffSnackbar =>
      'Sharing turned off. The old link no longer works.';

  @override
  String get shareItineraryErrorSnackbar =>
      'Couldn\'t create a share link right now.';

  @override
  String get closeButton => 'Close';

  @override
  String get claimedItinerarySnackbar => 'Added to your itineraries.';

  @override
  String get claimedItineraryErrorSnackbar =>
      'Couldn\'t add that shared itinerary to your account.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPage1Title => 'Discover Yaoundé';

  @override
  String get onboardingPage1Body =>
      'Browse real, hand-picked landmarks, culture, markets and nature across Yaoundé, Cameroon.';

  @override
  String get onboardingPage2Title => 'Get picks made for you';

  @override
  String get onboardingPage2Body =>
      'Tell us what you\'re into and we\'ll surface the spots you\'re most likely to enjoy.';

  @override
  String get onboardingPage3Title => 'Plan your day';

  @override
  String get onboardingPage3Body =>
      'Pick your stops and how much time you have - trip_io builds a timed schedule for you.';

  @override
  String get onboardingPage4Title => 'Navigate as you go';

  @override
  String get onboardingPage4Body =>
      'Follow turn-by-turn directions and see every stop, numbered in order, right on the map.';

  @override
  String get avatarCropTitle => 'Adjust photo';

  @override
  String get avatarCropConfirmButton => 'Done';

  @override
  String get avatarCropHint => 'Drag to reposition, pinch or scroll to zoom.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Trip reminders and updates on your submissions.';

  @override
  String notificationsErrorMessage(String error) {
    return 'Could not load notifications.\n$error';
  }

  @override
  String get notificationsEmptyTitle => 'You\'re all caught up';

  @override
  String get notificationsEmptySubtitle =>
      'Moderation notices and trip reminders will show up here.';

  @override
  String get notificationDestinationStatusTitle => 'Submission update';

  @override
  String notificationDestinationApprovedBody(String name) {
    return '\"$name\" was approved and is now live.';
  }

  @override
  String notificationDestinationRejectedBody(String name) {
    return '\"$name\" wasn\'t approved this time.';
  }

  @override
  String get notificationTripReminderTitle => 'Upcoming trip';

  @override
  String notificationTripReminderBodyToday(String title) {
    return '\"$title\" starts today.';
  }

  @override
  String notificationTripReminderBodyInDays(String title, String days) {
    return '\"$title\" starts in $days days.';
  }
}
