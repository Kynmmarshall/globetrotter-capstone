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
  String get navItineraries => 'Itinéraires';

  @override
  String get navProfile => 'Profil';

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
  String get itinerariesFormMissing =>
      'Ajoutez un titre et choisissez au moins une destination.';

  @override
  String get itineraryCreatedSnackbar => 'Itinéraire créé.';

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
  String get sessionExpiredTitle => 'Votre session a expiré';

  @override
  String get sessionExpiredSubtitle =>
      'Veuillez vous reconnecter pour continuer.';

  @override
  String get signInAgainButton => 'Se reconnecter';
}
