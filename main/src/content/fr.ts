import type { Dictionary } from "./types";

const fr: Dictionary = {
  header: {
    brand: "GetSpot",
    navFeatures: "Fonctionnalités",
    navFaq: "FAQ",
    openApp: "Ouvrir l'app →",
  },
  footer: {
    copyright: "© 2026 GetSpot ·",
    appLink: "app.getspot.org",
    privacyLink: "Confidentialité",
  },
  home: {
    metaTitle: "GetSpot — Organisez vos rencontres sportives en toute simplicité",
    metaDescription:
      "GetSpot aide les organisateurs à planifier des événements, gérer les participants et gérer les paiements de groupe pour le badminton et autres rencontres sportives.",
    title: "Organisez vos rencontres sportives sans le chaos des discussions de groupe",
    subtitle:
      "GetSpot aide les organisateurs à planifier des événements, gérer les participants et les listes d'attente, et gérer les paiements de groupe — conçu pour le badminton et d'autres groupes sportifs.",
    ctaOpenApp: "Ouvrir l'app",
    ctaIosApp: "App Store iOS",
    ctaAndroidApp: "Google Play",
    features: [
      {
        title: "Groupes",
        description:
          "Créez un groupe, partagez un code d'adhésion et gérez les membres en un seul endroit.",
      },
      {
        title: "Événements",
        description:
          "Planifiez des séances avec des limites de capacité, des listes d'attente et des règles de confirmation équitables.",
      },
      {
        title: "Portefeuille",
        description:
          "Suivez les soldes et paiements du groupe sans avoir à relancer qui que ce soit.",
      },
    ],
    seeAllFeatures: "Voir toutes les fonctionnalités →",
  },
  features: {
    metaTitle: "Fonctionnalités — GetSpot",
    metaDescription:
      "Découvrez comment GetSpot gère les groupes, la planification d'événements, les listes d'attente et les paiements pour des rencontres sportives récurrentes.",
    title: "Tout ce qu'il faut pour organiser des rencontres sportives récurrentes",
    subtitle: "Pas de tableurs, pas de paiements à réclamer, pas de listes d'attente manuelles.",
    forOrganizers: "Pour les organisateurs",
    forPlayers: "Pour les joueurs",
    organizerFeatures: [
      {
        title: "Créez des événements en quelques secondes",
        description:
          "Définissez la date, l'heure, le lieu, la capacité et les frais — publiez, et les membres sont immédiatement notifiés.",
      },
      {
        title: "Listes d'attente automatiques",
        description:
          "Une fois un événement complet, les nouvelles inscriptions rejoignent automatiquement la liste d'attente. Lorsqu'une place confirmée se libère, la personne suivante est promue sans intervention manuelle.",
      },
      {
        title: "Système de portefeuille virtuel",
        description:
          "Encaissez les paiements des membres comme vous le faites déjà — espèces, virement, etc. — puis créditez leur portefeuille dans l'app. Les frais d'inscription sont déduits automatiquement.",
      },
      {
        title: "Dates limites d'engagement",
        description:
          "Fixez une date limite au-delà de laquelle une annulation entraîne la perte des frais (sauf si un membre en liste d'attente prend la place), pour un nombre de participants fiable.",
      },
      {
        title: "Annonces de groupe",
        description: "Envoyez des mises à jour à tous les membres d'un groupe en une seule fois.",
      },
      {
        title: "Gestion des membres",
        description:
          "Approuvez les demandes d'adhésion, ajoutez ou retirez des membres et créditez les portefeuilles depuis un seul écran.",
      },
    ],
    playerFeatures: [
      {
        title: "Inscription en un geste",
        description:
          "Inscrivez-vous instantanément à un événement ; vos frais sont immédiatement déduits du solde de votre portefeuille de groupe.",
      },
      {
        title: "Statut en temps réel",
        description:
          "Sachez immédiatement si vous êtes confirmé ou en liste d'attente, et soyez notifié automatiquement en cas de promotion depuis la liste d'attente.",
      },
      {
        title: "Remboursements automatiques",
        description:
          "Désinscrivez-vous avant la date limite d'engagement et vos frais sont automatiquement remboursés sur votre portefeuille.",
      },
      {
        title: "Suivi du solde du portefeuille",
        description:
          "Consultez votre solde par groupe à tout moment — sans avoir à deviner ce que vous avez payé ou ce que vous devez.",
      },
      {
        title: "Notifications push",
        description:
          "Soyez informé des nouveaux événements, des changements de statut d'inscription et des rappels avant les matchs.",
      },
      {
        title: "Plusieurs groupes, un seul compte",
        description:
          "Rejoignez autant de groupes sportifs que vous le souhaitez, le tout depuis une seule connexion.",
      },
    ],
    ctaOpenApp: "Ouvrir l'app",
    ctaReadFaq: "Lire la FAQ",
  },
  faq: {
    metaTitle: "FAQ — GetSpot",
    metaDescription:
      "Réponses aux questions courantes sur le fonctionnement du portefeuille virtuel, des remboursements et du partage de groupe de GetSpot.",
    title: "Questions fréquentes",
    introBeforeEmail: "Une question sans réponse ici ? Écrivez à",
    introAfterEmail: ".",
    items: [
      {
        question: "GetSpot est-il gratuit ?",
        answer: "Oui. Il n'y a ni abonnement ni frais par transaction pour les organisateurs ou les joueurs.",
      },
      {
        question: "Ai-je besoin d'un prestataire de paiement ou d'un compte professionnel ?",
        answer:
          "Non. GetSpot utilise un portefeuille virtuel plutôt qu'une passerelle de paiement. Vous encaissez le paiement réel des membres comme vous le faites déjà — espèces, virement, etc. — puis créditez leur portefeuille dans l'app. GetSpot ne touche jamais aux données de paiement réelles.",
      },
      {
        question: "Comment fonctionne réellement le portefeuille ?",
        answer:
          "Les soldes de portefeuille sont par groupe. Un organisateur crédite le portefeuille d'un membre après avoir encaissé le paiement hors ligne. Lorsque ce membre s'inscrit à un événement du groupe, les frais sont automatiquement déduits de son solde.",
      },
      {
        question: "Que se passe-t-il si j'annule après la date limite ?",
        answer:
          "Chaque événement peut avoir une date limite d'engagement. Annuler après cette date entraîne la perte des frais, sauf si un membre en liste d'attente prend la place libérée. Cela garantit un nombre de participants fiable pour l'organisateur.",
      },
      {
        question: "Et si je me désinscris avant la date limite ?",
        answer: "Vos frais sont automatiquement remboursés sur votre portefeuille — aucune demande manuelle n'est nécessaire.",
      },
      {
        question: "Que se passe-t-il si une place se libère sur la liste d'attente ?",
        answer:
          "La personne suivante sur la liste d'attente est automatiquement confirmée et notifiée — sans coordination manuelle de la part de l'organisateur.",
      },
      {
        question: "Puis-je rejoindre plusieurs groupes ?",
        answer:
          "Oui. Les joueurs peuvent rejoindre plusieurs groupes sportifs avec un seul compte, et les organisateurs peuvent également créer et gérer plusieurs groupes.",
      },
      {
        question: "Mes données et informations de paiement sont-elles sécurisées ?",
        answer:
          "GetSpot est construit sur Firebase avec une authentification et des règles de sécurité standard. Les paiements réels ayant lieu hors ligne entre vous et votre organisateur, vos informations de paiement ne transitent jamais par les serveurs de GetSpot.",
      },
      {
        question: "Pour quels sports GetSpot fonctionne-t-il ?",
        answer:
          "Toute rencontre sportive récurrente avec une limite de capacité et des frais — badminton, basketball, football, tennis, volleyball et formats similaires.",
      },
      {
        question: "Comment commencer ?",
        answer:
          "Téléchargez l'app, connectez-vous avec Google ou Apple, puis créez un groupe (vous recevrez un code à partager avec vos membres) ou rejoignez-en un avec un code fourni par votre organisateur.",
      },
    ],
    ctaOpenApp: "Ouvrir l'app",
  },
  privacy: {
    metaTitle: "Politique de confidentialité — GetSpot",
    metaDescription:
      "Comment GetSpot collecte, utilise et partage vos informations lorsque vous utilisez l'application.",
  },
};

export default fr;
