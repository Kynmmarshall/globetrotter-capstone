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
  String get navFavorites => 'Favoris';

  @override
  String get navItineraries => 'Itinéraires';

  @override
  String get navProfile => 'Profil';

  @override
  String get aiChatTitle => 'Demander à l\'IA';

  @override
  String get aiChatSubtitle =>
      'Discutez des destinations de Yaoundé et recevez des suggestions personnalisées.';

  @override
  String get aiChatInputHint =>
      'Demandez à propos d\'un lieu, ou quoi faire aujourd\'hui…';

  @override
  String get aiChatEmptyState =>
      'Posez-moi une question sur Yaoundé - je peux suggérer des lieux selon vos centres d\'intérêt ou expliquer pourquoi un lieu vaut le détour.';

  @override
  String aiChatErrorMessage(String error) {
    return 'Impossible de contacter l\'assistant IA.\n$error';
  }

  @override
  String get aiChatNotConfigured =>
      'L\'assistant IA n\'est pas encore configuré. Revenez bientôt.';

  @override
  String get aiExplainButton => 'Demander une explication à l\'IA';

  @override
  String get aiExplainTitle => 'Explication de l\'IA';

  @override
  String get aiExplainError =>
      'Impossible d\'obtenir une explication pour le moment.';

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
  String get itinerariesFormMissing =>
      'Ajoutez un titre et choisissez au moins une destination.';

  @override
  String get itineraryCreatedSnackbar => 'Itinéraire créé.';

  @override
  String get itineraryDeletedSnackbar => 'Itinéraire supprimé.';

  @override
  String get deleteItineraryButton => 'Supprimer';

  @override
  String get deleteItineraryConfirmTitle => 'Supprimer cet itinéraire ?';

  @override
  String deleteItineraryConfirmMessage(String title) {
    return '« $title » sera définitivement supprimé. Cette action est irréversible.';
  }

  @override
  String get cancelButton => 'Annuler';

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
  String get regionStatLabel => 'Région';

  @override
  String get featuredSpotsStatLabel => 'Lieux en vedette';

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
}
