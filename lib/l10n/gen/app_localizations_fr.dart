// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'trip_io';

  @override
  String get authLoginTitle => 'Connexion';

  @override
  String get authRegisterTitle => 'Inscription';

  @override
  String get authLoginSubtitle =>
      'Connectez-vous pour continuer à planifier et gérer vos voyages.';

  @override
  String get authRegisterSubtitle =>
      'Créez votre compte pour enregistrer vos itinéraires et recevoir des recommandations.';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailHelper =>
      'Utilisé pour vous contacter et compléter votre profil';

  @override
  String get authEmailRequired => 'L\'e-mail est requis';

  @override
  String get authEmailInvalid => 'Saisissez une adresse e-mail valide';

  @override
  String get authUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get authUsernameHelper =>
      'C\'est l\'identifiant de connexion de votre compte';

  @override
  String get authUsernameRequired => 'Le nom d\'utilisateur est requis';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordRequired => 'Le mot de passe est requis';

  @override
  String get authConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authConfirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get authPasswordsMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authLoginTip =>
      'Astuce : utilisez le nom d\'utilisateur et le mot de passe saisis lors de la création de votre compte.';

  @override
  String get authLoginButton => 'Connexion';

  @override
  String get authCreateAccountButton => 'Créer un compte';

  @override
  String get authToggleToRegister => 'Pas de compte ? Inscrivez-vous';

  @override
  String get authToggleToLogin => 'Déjà un compte ? Connectez-vous';

  @override
  String get authOrDivider => 'ou';

  @override
  String get authTaglineTitle =>
      'Planifiez plus vite. Voyagez plus intelligemment.';

  @override
  String get authTaglineSubtitle =>
      'Recherchez des destinations, créez des itinéraires et gardez votre compte synchronisé sur mobile, web et Windows.';

  @override
  String get authFeatureMobile => 'Compatible mobile';

  @override
  String get authFeatureWeb => 'Compatible web';

  @override
  String get authFeatureDesktop => 'Compatible bureau';

  @override
  String get navDestinations => 'Destinations';

  @override
  String get navRecommendations => 'Recommandations';

  @override
  String get navForYou => 'Pour vous';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navItineraries => 'Itinéraires';

  @override
  String get navProfile => 'Profil';

  @override
  String get aiChatTitle => 'Demander à TIA';

  @override
  String get aiChatSubtitle =>
      'Discutez avec TIA des destinations de Yaoundé et recevez des conseils de voyage personnalisés.';

  @override
  String get aiChatInputHint =>
      'Demandez à TIA à propos d\'un lieu, ou quoi faire aujourd\'hui…';

  @override
  String get aiChatEmptyState =>
      'Demandez à TIA à propos de Yaoundé - je peux suggérer des lieux selon vos centres d\'intérêt et guider votre plan de voyage.';

  @override
  String aiChatErrorMessage(String error) {
    return 'Impossible de contacter TIA.\n$error';
  }

  @override
  String get aiChatNotConfigured =>
      'TIA n\'est pas encore configuré. Revenez bientôt.';

  @override
  String get aiChatSuggestionsLabel => 'Essayez de demander à TIA';

  @override
  String get aiChatSuggestion1 =>
      'Que vaut-il la peine de visiter à Yaoundé aujourd\'hui ?';

  @override
  String get aiChatSuggestion2 =>
      'Suggérez un itinéraire culturel d\'une demi-journée';

  @override
  String get aiChatSuggestion3 =>
      'Où puis-je manger de la cuisine camerounaise locale ?';

  @override
  String get aiChatSuggestion4 =>
      'Meilleur endroit pour un coucher de soleil ?';

  @override
  String get aiChatVoiceStartTooltip => 'Enregistrer un message vocal';

  @override
  String get aiChatVoiceStopTooltip => 'Arrêter l\'enregistrement';

  @override
  String get aiChatVoiceEmptyError =>
      'Je n\'ai rien entendu - réessayez l\'enregistrement.';

  @override
  String get aiChatVoiceFailedError =>
      'Impossible de transcrire ce message. Réessayez.';

  @override
  String get aiChatVoicePermissionDenied =>
      'L\'accès au microphone est nécessaire pour enregistrer un message vocal.';

  @override
  String get aiChatVoiceMuteTooltip => 'Couper la voix de Tia';

  @override
  String get aiChatVoiceUnmuteTooltip => 'Activer la voix de Tia';

  @override
  String get aiExplainButton => 'Demander à TIA une explication';

  @override
  String get aiExplainTitle => 'Explication TIA';

  @override
  String get aiExplainError =>
      'Impossible d\'obtenir une explication pour le moment.';

  @override
  String get aiLinkOpenFailed => 'Impossible d\'ouvrir cette destination.';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get commentsInputHint => 'Ajouter un commentaire…';

  @override
  String get commentsPostButton => 'Publier';

  @override
  String get commentsReplyButton => 'Répondre';

  @override
  String get commentsButtonLabel => 'Voir les commentaires';

  @override
  String get commentsEmpty =>
      'Aucun commentaire pour l\'instant — soyez le premier à partager votre avis.';

  @override
  String commentsLoadError(String error) {
    return 'Impossible de charger les commentaires.\n$error';
  }

  @override
  String get commentEditButton => 'Modifier';

  @override
  String get commentDeleteButton => 'Supprimer';

  @override
  String get commentDeleteConfirmTitle => 'Supprimer ce commentaire ?';

  @override
  String get commentDeleteConfirmMessage => 'Cette action est irréversible.';

  @override
  String get commentsNewBadge => 'Nouveau';

  @override
  String get readAloudTooltip => 'Lire à voix haute';

  @override
  String get readAloudStopTooltip => 'Arrêter la lecture';

  @override
  String get destinationsTitle => 'Destinations à Yaoundé';

  @override
  String get destinationsSubtitle =>
      'Explorez les monuments, la culture et la nature de la capitale du Cameroun.';

  @override
  String get destinationsSearchHint =>
      'Rechercher une destination par nom ou mot-clé';

  @override
  String get searchButton => 'Rechercher';

  @override
  String get destinationsEmpty => 'Aucune destination trouvée.';

  @override
  String get destinationsFilterLabel => 'Filtrer par centre d\'intérêt';

  @override
  String get destinationsFilterClear => 'Effacer';

  @override
  String get destinationsFilterEmpty =>
      'Aucune destination ne correspond aux filtres sélectionnés.';

  @override
  String destinationCardSemanticLabel(String name) {
    return 'Voir $name';
  }

  @override
  String get suggestDestinationButton => 'Suggérer une destination';

  @override
  String get submitDestinationTitle => 'Suggérer une destination';

  @override
  String get submitDestinationSubtitle =>
      'Vous connaissez un vrai lieu à Yaoundé qui manque ? Suggérez-le ici - un administrateur examine chaque suggestion avant sa mise en ligne.';

  @override
  String get submitDestinationNameLabel => 'Nom de la destination';

  @override
  String get submitDestinationNameRequired => 'Le nom est requis';

  @override
  String get submitDestinationLocationLabel => 'Lieu';

  @override
  String get submitDestinationLocationHint => 'ex. Bastos, Yaoundé';

  @override
  String get submitDestinationDescriptionLabel => 'Description';

  @override
  String get submitDestinationReviewNotice =>
      'Votre suggestion n\'apparaîtra pas dans l\'application tant qu\'un administrateur ne l\'aura pas approuvée.';

  @override
  String get submitDestinationButton => 'Envoyer pour examen';

  @override
  String get submitDestinationSuccess =>
      'Merci ! Votre suggestion a été envoyée pour examen.';

  @override
  String submitDestinationSuccessImageFailed(String error) {
    return 'Votre suggestion a été envoyée, mais l\'envoi de la photo a échoué : $error';
  }

  @override
  String get submitDestinationAddPhoto => 'Ajouter une photo (facultatif)';

  @override
  String get submitDestinationLocationPickButton =>
      'Définir la position sur la carte';

  @override
  String submitDestinationLocationPickedLabel(String lat, String lon) {
    return 'Position définie : $lat, $lon';
  }

  @override
  String get pickLocationTitle => 'Choisir la position';

  @override
  String get pickLocationHint =>
      'Touchez la carte pour placer une épingle à l\'emplacement de cette destination';

  @override
  String get pickLocationConfirm => 'Utiliser cette position';

  @override
  String get recommendationsTitle => 'Sélectionné pour vous';

  @override
  String get recommendationsSubtitle =>
      'Une courte liste de lieux à Yaoundé à ajouter à votre itinéraire.';

  @override
  String recommendationsErrorMessage(String error) {
    return 'Impossible de charger les recommandations.\n$error';
  }

  @override
  String get recommendationsEmptyTitle =>
      'Aucune recommandation pour l\'instant';

  @override
  String get recommendationsEmptySubtitle =>
      'Explorez les destinations et nous vous suggérerons des lieux.';

  @override
  String get forYouTitle => 'Pour vous';

  @override
  String get forYouSubtitle =>
      'Un mélange personnalisé de suggestions faites pour vous et de ce qui est populaire à Yaoundé.';

  @override
  String get forYouPersonalizedSectionTitle => 'Sélectionné pour vous';

  @override
  String get forYouTrendingSectionTitle => 'Tendance à Yaoundé';

  @override
  String get favoritesTitle => 'Vos favoris';

  @override
  String get favoritesSubtitle => 'Destinations que vous avez enregistrées.';

  @override
  String favoritesErrorMessage(String error) {
    return 'Impossible de charger les favoris.\n$error';
  }

  @override
  String get favoritesEmptyTitle => 'Aucun favori pour l\'instant';

  @override
  String get favoritesEmptySubtitle =>
      'Appuyez sur le cœur d\'une destination pour l\'enregistrer ici.';

  @override
  String get viewMySubmissionsButton => 'Mes suggestions';

  @override
  String get mySubmissionsTitle => 'Vos suggestions';

  @override
  String get mySubmissionsSubtitle =>
      'Les destinations que vous avez suggérées, et leur statut de validation.';

  @override
  String mySubmissionsErrorMessage(String error) {
    return 'Impossible de charger vos suggestions.\n$error';
  }

  @override
  String get mySubmissionsEmptyTitle => 'Aucune suggestion pour l\'instant';

  @override
  String get mySubmissionsEmptySubtitle =>
      'Suggérez une destination et suivez son statut de validation ici.';

  @override
  String get submissionStatusPending => 'En attente de validation';

  @override
  String get submissionStatusApproved => 'Approuvée';

  @override
  String get submissionStatusRejected => 'Non approuvée';

  @override
  String get itinerariesFormMissing =>
      'Ajoutez un titre et choisissez au moins une destination.';

  @override
  String get itineraryCreatedSnackbar => 'Itinéraire créé.';

  @override
  String get itineraryDeletedSnackbar => 'Itinéraire supprimé.';

  @override
  String get directionsButtonTooltip => 'Itinéraire';

  @override
  String get addToItineraryTooltip => 'Ajouter à un itinéraire';

  @override
  String get addToItinerarySheetTitle => 'Ajouter à un itinéraire';

  @override
  String get addToItineraryCreateNew => 'Créer un nouvel itinéraire';

  @override
  String get addToItineraryEmpty => 'Vous n\'avez pas encore d\'itinéraire.';

  @override
  String addToItineraryAdded(String title) {
    return 'Ajouté à « $title ».';
  }

  @override
  String addToItineraryAlready(String title) {
    return 'Déjà dans « $title ».';
  }

  @override
  String get addToItineraryAlreadyAdded => 'Déjà ajouté';

  @override
  String get addToItineraryNewDialogTitle => 'Nouvel itinéraire';

  @override
  String get orderDestinationsSheetTitle => 'Ordonnez votre visite';

  @override
  String get orderDestinationsSheetSubtitle =>
      'Faites glisser pour définir l\'ordre de visite souhaité.';

  @override
  String get orderDestinationsConfirmButton => 'Confirmer l\'ordre';

  @override
  String get mapOptionsToggleTooltip => 'Options de la carte';

  @override
  String get mapSelectItineraryButton => 'Choisir un itinéraire';

  @override
  String get mapSelectItinerarySheetTitle => 'Choisissez un itinéraire';

  @override
  String get mapLeaveItineraryButton => 'Quitter l\'itinéraire';

  @override
  String get mapNoItinerariesAvailable =>
      'Vous n\'avez pas encore d\'itinéraire.';

  @override
  String mapItineraryProgress(int visited, int total) {
    return '$visited sur $total visités';
  }

  @override
  String mapNextStopSummary(String distance, String duration) {
    return 'Prochain arrêt : $distance · $duration';
  }

  @override
  String get mapRemainingLabel => 'Restant';

  @override
  String get mapItineraryCompleteLabel => 'Tous les arrêts visités';

  @override
  String get mapAmenitiesToggleTooltip => 'Commodités à proximité';

  @override
  String get mapAmenitiesLegendTitle => 'Commodités à proximité';

  @override
  String get mapAmenitiesShowToggle => 'Afficher sur la carte';

  @override
  String get mapAmenitiesEmptyHint => 'Aucune commodité trouvée à proximité.';

  @override
  String get mapAmenityCategoryHospital => 'Hôpitaux';

  @override
  String get mapAmenityCategoryPharmacy => 'Pharmacies';

  @override
  String get mapAmenityCategoryFuel => 'Stations-service';

  @override
  String get mapAmenityCategoryHotel => 'Hôtels';

  @override
  String get mapAmenityCategoryBankAtm => 'Banques et distributeurs';

  @override
  String get mapAmenityCategoryPolice => 'Postes de police';

  @override
  String get mapAmenityDirectionsButton => 'Itinéraire jusqu\'ici';

  @override
  String get mapYangoButtonTooltip => 'Réserver un taxi';

  @override
  String get mapYangoLaunchFailed =>
      'Impossible d\'ouvrir l\'application de taxi.';

  @override
  String get navMap => 'Carte';

  @override
  String get mapTitle => 'Obtenir l\'itinéraire';

  @override
  String get mapFromLabel => 'Départ';

  @override
  String get mapToLabel => 'Arrivée';

  @override
  String get mapSwapButton => 'Inverser le départ et l\'arrivée';

  @override
  String get mapClearRoute => 'Effacer';

  @override
  String get mapSearchHint => 'Rechercher des destinations…';

  @override
  String get mapNoCoordinates =>
      'Cette destination n\'a pas encore de position définie';

  @override
  String get mapProfileDriving => 'Voiture';

  @override
  String get mapProfileWalking => 'À pied';

  @override
  String get mapProfileCycling => 'Vélo';

  @override
  String get mapRoutingNotConfigured =>
      'L\'itinéraire n\'est pas encore configuré. Revenez bientôt.';

  @override
  String get mapNoRouteFound =>
      'Impossible de trouver un itinéraire entre ces points. L\'un d\'eux est peut-être inaccessible - vérifiez les destinations et votre position.';

  @override
  String get mapLocationTooFar =>
      'Votre position actuelle semble éloignée de ces destinations. Vérifiez que la localisation est précise, puis réessayez.';

  @override
  String get viewOnMapButton => 'Voir sur la carte';

  @override
  String get playVideoButton => 'Voir la vidéo';

  @override
  String get videoCloseTooltip => 'Fermer la vidéo';

  @override
  String get videoLoadError => 'Impossible de charger cette vidéo.';

  @override
  String get videoLaunchFailed => 'Impossible d\'ouvrir le lien de la vidéo.';

  @override
  String get mapLocationPermissionDenied =>
      'L\'accès à la position est nécessaire pour l\'afficher sur la carte. Veuillez l\'autoriser dans les paramètres de votre appareil.';

  @override
  String get mapLocationServicesDisabled =>
      'Activez la localisation sur votre appareil pour afficher votre position sur la carte.';

  @override
  String get mapLocateFailed =>
      'Impossible d\'obtenir votre position. Veuillez réessayer.';

  @override
  String get mapLocationApproximate =>
      'Votre position est approximative - sans GPS (par ex. sur un navigateur de bureau), elle est estimée à partir des données WiFi/réseau.';

  @override
  String get mapRetryButton => 'Réessayer';

  @override
  String get mapUseMyLocation => 'Utiliser ma position actuelle';

  @override
  String get mapMyLocationLabel => 'Ma position actuelle';

  @override
  String get mapResolvingLocation => 'Recherche de votre position…';

  @override
  String get startItineraryButton => 'Démarrer l\'itinéraire';

  @override
  String mapRouteError(String error) {
    return 'Impossible d\'obtenir l\'itinéraire.\n$error';
  }

  @override
  String get deleteItineraryButton => 'Supprimer';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmMessage =>
      'Vous devrez vous reconnecter pour voir vos itinéraires et favoris.';

  @override
  String get deleteItineraryConfirmTitle => 'Supprimer cet itinéraire ?';

  @override
  String deleteItineraryConfirmMessage(String title) {
    return '« $title » sera définitivement supprimé. Cette action est irréversible.';
  }

  @override
  String get cancelButton => 'Annuler';

  @override
  String get forgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser votre mot de passe';

  @override
  String get forgotPasswordStep1Subtitle =>
      'Entrez votre nom d\'utilisateur ou votre email et nous vous enverrons un code de réinitialisation.';

  @override
  String get forgotPasswordIdentifierLabel => 'Nom d\'utilisateur ou email';

  @override
  String get forgotPasswordIdentifierRequired =>
      'Entrez votre nom d\'utilisateur ou votre email';

  @override
  String get forgotPasswordSendCodeButton => 'Envoyer le code';

  @override
  String forgotPasswordCodeSentMessage(String identifier) {
    return 'Si un compte existe pour « $identifier », un code de réinitialisation a été envoyé.';
  }

  @override
  String get forgotPasswordStep2Subtitle =>
      'Entrez le code que nous vous avons envoyé, ainsi qu\'un nouveau mot de passe.';

  @override
  String get forgotPasswordCodeLabel => 'Code de réinitialisation';

  @override
  String get forgotPasswordCodeHint => 'Code à 6 chiffres';

  @override
  String get forgotPasswordCodeRequired => 'Entrez le code reçu par email';

  @override
  String get forgotPasswordNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get forgotPasswordResetButton => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordSuccessMessage =>
      'Mot de passe mis à jour. Vous pouvez maintenant vous connecter.';

  @override
  String get forgotPasswordResendCodeButton => 'Renvoyer le code';

  @override
  String get forgotPasswordChangeIdentifierButton => 'Utiliser un autre compte';

  @override
  String get itinerariesPlanTitle => 'Planifier un nouvel itinéraire';

  @override
  String get itineraryTitleLabel => 'Titre de l\'itinéraire';

  @override
  String get itineraryTitleHint => 'Mon week-end à Yaoundé';

  @override
  String get destinationsLabel => 'Destinations';

  @override
  String get noDestinationsAvailable =>
      'Aucune destination disponible pour l\'instant.';

  @override
  String get itineraryDestinationSearchHint =>
      'Rechercher des destinations à ajouter…';

  @override
  String itineraryShowAllDestinations(int count) {
    return 'Afficher les $count destinations';
  }

  @override
  String get itineraryHideAllDestinations => 'Masquer la liste complète';

  @override
  String get itineraryDestinationSearchPrompt =>
      'Recherchez par nom, ou appuyez sur « afficher tout » pour parcourir toutes les destinations.';

  @override
  String itineraryDestinationSearchNoMatches(String query) {
    return 'Aucune destination ne correspond à « $query ».';
  }

  @override
  String get itineraryAllDestinationsAdded =>
      'Toutes les destinations ont été ajoutées.';

  @override
  String get createItineraryButton => 'Créer l\'itinéraire';

  @override
  String itinerariesErrorMessage(String error) {
    return 'Impossible de charger les itinéraires.\n$error';
  }

  @override
  String get itinerariesEmptyTitle => 'Aucun itinéraire pour l\'instant';

  @override
  String get itinerariesEmptySubtitle =>
      'Choisissez quelques destinations ci-dessus pour créer votre premier plan.';

  @override
  String get yourItinerariesTitle => 'Vos itinéraires';

  @override
  String itineraryCardSemanticLabel(String title) {
    return 'Ouvrir l\'itinéraire $title';
  }

  @override
  String destinationsLoadError(String error) {
    return 'Impossible de charger les destinations.\n$error';
  }

  @override
  String itineraryStartTime(String time) {
    return 'Heure de départ : $time';
  }

  @override
  String itineraryAvailableTime(String duration) {
    return 'Temps disponible : $duration';
  }

  @override
  String itineraryAvailableTimePerDay(String duration) {
    return 'Temps disponible par jour : $duration';
  }

  @override
  String itineraryOverrunWarning(String extra, String minStop) {
    return 'Ce plan nécessite environ $extra de plus que le temps disponible ; chaque arrêt dure donc au moins $minStop min.';
  }

  @override
  String get itineraryPlanSectionTitle => 'Votre plan';

  @override
  String itineraryStopsSummary(String count, String duration) {
    return '$count arrêts · $duration au total';
  }

  @override
  String get itineraryNoSchedule =>
      'Aucun plan chronométré pour cet itinéraire pour l\'instant.';

  @override
  String get itineraryTravelTime => 'Temps de trajet';

  @override
  String get tripDatesLabel => 'Dates du voyage';

  @override
  String get tripDatesHint => 'Choisissez une date de début et de fin';

  @override
  String get memberSinceDevice => 'Membre depuis cet appareil';

  @override
  String memberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get basedInYaounde => 'Basé à Yaoundé, Cameroun';

  @override
  String get itinerariesStatLabel => 'Itinéraires';

  @override
  String get favoritesStatLabel => 'Favoris';

  @override
  String get placesPlannedStatLabel => 'Lieux prévus';

  @override
  String get aboutMeTitle => 'À propos de moi';

  @override
  String get bioHint => 'Parlez un peu de vous aux autres voyageurs...';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get bioUpdatedSnackbar => 'Biographie mise à jour.';

  @override
  String signedInAs(String username) {
    return 'Connecté en tant que $username';
  }

  @override
  String get unknownUser => 'inconnu';

  @override
  String get logoutButton => 'Déconnexion';

  @override
  String get travellerFallback => 'Voyageur';

  @override
  String get avatarSemanticLabel =>
      'Appuyez pour changer votre photo de profil';

  @override
  String couldNotPickImage(String error) {
    return 'Impossible de sélectionner l\'image : $error';
  }

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get themeLabel => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get interestsLabel => 'Centres d\'intérêt';

  @override
  String get interestsHelper =>
      'Choisissez ce qui vous intéresse - nous nous en servirons pour vous recommander des lieux à Yaoundé.';

  @override
  String get interestsUpdatedSnackbar => 'Centres d\'intérêt mis à jour.';

  @override
  String get nearbyTitle => 'Manger et dormir à proximité';

  @override
  String get nearbySubtitle =>
      'Vrais restaurants et hôtels proches de ce lieu.';

  @override
  String get practicalInfoTitle => 'Bon à savoir';

  @override
  String get openingHoursLabel => 'Horaires d\'ouverture';

  @override
  String get entryFeeLabel => 'Prix d\'entrée';

  @override
  String get tipsLabel => 'Astuces';

  @override
  String get sessionExpiredTitle => 'Votre session a expiré';

  @override
  String get sessionExpiredSubtitle =>
      'Veuillez vous reconnecter pour continuer.';

  @override
  String get signInAgainButton => 'Se reconnecter';

  @override
  String get shareItineraryTooltip => 'Partager cet itinéraire';

  @override
  String shareItineraryDialogTitle(String title) {
    return 'Partager « $title »';
  }

  @override
  String get shareItineraryDialogMessage =>
      'Toute personne qui ouvre ce lien reçoit sa propre copie de cet itinéraire directement dans son compte trip_io - il lui sera demandé d\'en créer un si elle n\'en a pas encore. Le lien continue de fonctionner pour tous ceux à qui vous l\'envoyez jusqu\'à ce que vous désactiviez le partage.';

  @override
  String get shareItineraryCopyLinkButton => 'Copier le lien';

  @override
  String get shareItineraryLinkCopiedSnackbar =>
      'Lien copié dans le presse-papiers.';

  @override
  String get shareItineraryTurnOffButton => 'Désactiver le partage';

  @override
  String get shareItineraryTurnedOffSnackbar =>
      'Partage désactivé. L\'ancien lien ne fonctionne plus.';

  @override
  String get shareItineraryErrorSnackbar =>
      'Impossible de créer un lien de partage pour le moment.';

  @override
  String get closeButton => 'Fermer';

  @override
  String get claimedItinerarySnackbar => 'Ajouté à vos itinéraires.';

  @override
  String get claimedItineraryErrorSnackbar =>
      'Impossible d\'ajouter cet itinéraire partagé à votre compte.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingGetStarted => 'Commencer';

  @override
  String get onboardingPage1Title => 'Découvrez Yaoundé';

  @override
  String get onboardingPage1Body =>
      'Parcourez de vrais lieux sélectionnés à la main : monuments, culture, marchés et nature à Yaoundé, Cameroun.';

  @override
  String get onboardingPage2Title => 'Des suggestions pensées pour vous';

  @override
  String get onboardingPage2Body =>
      'Dites-nous ce qui vous intéresse et nous vous proposerons les lieux les plus susceptibles de vous plaire.';

  @override
  String get onboardingPage3Title => 'Planifiez votre journée';

  @override
  String get onboardingPage3Body =>
      'Choisissez vos arrêts et votre temps disponible - trip_io construit un planning chronométré pour vous.';

  @override
  String get onboardingPage4Title => 'Naviguez en temps réel';

  @override
  String get onboardingPage4Body =>
      'Suivez un itinéraire pas à pas et voyez chaque arrêt, numéroté dans l\'ordre, directement sur la carte.';

  @override
  String get avatarCropTitle => 'Ajuster la photo';

  @override
  String get avatarCropConfirmButton => 'Terminé';

  @override
  String get avatarCropHint =>
      'Faites glisser pour repositionner, pincez ou faites défiler pour zoomer.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsSubtitle =>
      'Rappels de voyage et mises à jour sur vos suggestions.';

  @override
  String notificationsErrorMessage(String error) {
    return 'Impossible de charger les notifications.\n$error';
  }

  @override
  String get notificationsEmptyTitle => 'Vous êtes à jour';

  @override
  String get notificationsEmptySubtitle =>
      'Les avis de modération et rappels de voyage apparaîtront ici.';

  @override
  String get notificationDestinationStatusTitle =>
      'Mise à jour de votre suggestion';

  @override
  String notificationDestinationApprovedBody(String name) {
    return '« $name » a été approuvée et est maintenant en ligne.';
  }

  @override
  String notificationDestinationRejectedBody(String name) {
    return '« $name » n\'a pas été approuvée cette fois-ci.';
  }

  @override
  String get notificationTripReminderTitle => 'Voyage à venir';

  @override
  String notificationTripReminderBodyToday(String title) {
    return '« $title » commence aujourd\'hui.';
  }

  @override
  String notificationTripReminderBodyInDays(String title, String days) {
    return '« $title » commence dans $days jours.';
  }
}
