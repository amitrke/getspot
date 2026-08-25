import type { Dictionary } from "./types";

const de: Dictionary = {
  header: {
    brand: "GetSpot",
    navFeatures: "Funktionen",
    navFaq: "FAQ",
    openApp: "App öffnen →",
  },
  footer: {
    copyright: "© 2026 GetSpot ·",
    appLink: "app.getspot.org",
    privacyLink: "Datenschutz",
  },
  home: {
    metaTitle: "GetSpot — Organisiere Sporttreffen mit Leichtigkeit",
    metaDescription:
      "GetSpot hilft Organisatoren, Events zu planen, Teilnehmer zu verwalten und Gruppenzahlungen für Badminton und andere Sporttreffen abzuwickeln.",
    title: "Organisiere Sporttreffen ohne das Chaos im Gruppenchat",
    subtitle:
      "GetSpot hilft Organisatoren, Events zu planen, Teilnehmer und Wartelisten zu verwalten und Gruppenzahlungen abzuwickeln — entwickelt für Badminton und andere Sportgruppen.",
    ctaOpenApp: "App öffnen",
    ctaIosApp: "iOS App Store",
    ctaAndroidApp: "Google Play",
    features: [
      {
        title: "Gruppen",
        description:
          "Erstelle eine Gruppe, teile einen Beitrittscode und verwalte Mitglieder an einem Ort.",
      },
      {
        title: "Events",
        description:
          "Plane Termine mit Kapazitätsgrenzen, Wartelisten und fairen Bestätigungsregeln.",
      },
      {
        title: "Wallet",
        description:
          "Behalte Gruppenguthaben und Zahlungen im Blick, ohne Leuten hinterherzulaufen.",
      },
    ],
    seeAllFeatures: "Alle Funktionen ansehen →",
  },
  features: {
    metaTitle: "Funktionen — GetSpot",
    metaDescription:
      "Erfahre, wie GetSpot Gruppenverwaltung, Terminplanung, Wartelisten und Zahlungen für wiederkehrende Sporttreffen abwickelt.",
    title: "Alles, was du für wiederkehrende Sporttreffen brauchst",
    subtitle: "Keine Tabellenkalkulationen, kein Zahlungen hinterherlaufen, keine manuellen Wartelisten.",
    forOrganizers: "Für Organisatoren",
    forPlayers: "Für Spieler",
    organizerFeatures: [
      {
        title: "Events in Sekunden erstellen",
        description:
          "Lege Datum, Uhrzeit, Ort, Kapazität und Gebühr fest — veröffentliche es, und Mitglieder werden sofort benachrichtigt.",
      },
      {
        title: "Automatische Wartelisten",
        description:
          "Sobald ein Event ausgebucht ist, kommen neue Anmeldungen automatisch auf die Warteliste. Wird ein bestätigter Platz frei, rückt die nächste Person ohne manuellen Aufwand nach.",
      },
      {
        title: "Virtuelles Wallet-System",
        description:
          "Kassiere Zahlungen von Mitgliedern wie gewohnt — Bargeld, PayPal, Überweisung — und schreibe sie dann im App-Wallet gut. Anmeldegebühren werden automatisch abgezogen.",
      },
      {
        title: "Verbindlichkeitsfristen",
        description:
          "Lege eine Frist fest, nach der eine Absage die Gebühr verfallen lässt (außer ein Wartelisten-Mitglied übernimmt den Platz), damit deine Teilnehmerzahl verlässlich bleibt.",
      },
      {
        title: "Gruppenankündigungen",
        description: "Sende Updates an alle Mitglieder einer Gruppe gleichzeitig.",
      },
      {
        title: "Mitgliederverwaltung",
        description:
          "Genehmige Beitrittsanfragen, füge Mitglieder hinzu oder entferne sie und schreibe Guthaben gut — alles von einem Bildschirm aus.",
      },
    ],
    playerFeatures: [
      {
        title: "Anmeldung mit einem Tipp",
        description:
          "Melde dich sofort für ein Event an; deine Gebühr wird direkt von deinem Gruppen-Wallet-Guthaben abgezogen.",
      },
      {
        title: "Status in Echtzeit",
        description:
          "Erfahre sofort, ob du bestätigt oder auf der Warteliste bist, und werde automatisch benachrichtigt, wenn du von der Warteliste hochgestuft wirst.",
      },
      {
        title: "Automatische Rückerstattungen",
        description:
          "Ziehe dich vor der Verbindlichkeitsfrist zurück, und deine Gebühr wird automatisch auf dein Wallet zurückerstattet.",
      },
      {
        title: "Wallet-Guthaben im Überblick",
        description:
          "Sieh jederzeit dein Guthaben pro Gruppe — kein Rätselraten, was du bezahlt hast oder schuldest.",
      },
      {
        title: "Push-Benachrichtigungen",
        description:
          "Erhalte Benachrichtigungen über neue Events, Statusänderungen bei Anmeldungen und Erinnerungen vor Spielen.",
      },
      {
        title: "Mehrere Gruppen, ein Konto",
        description:
          "Tritt so vielen Sportgruppen bei, wie du spielst — alles mit einem einzigen Login.",
      },
    ],
    ctaOpenApp: "App öffnen",
    ctaReadFaq: "FAQ lesen",
  },
  faq: {
    metaTitle: "FAQ — GetSpot",
    metaDescription:
      "Antworten auf häufige Fragen dazu, wie das virtuelle Wallet, Rückerstattungen und die Gruppenfreigabe von GetSpot funktionieren.",
    title: "Häufig gestellte Fragen",
    introBeforeEmail: "Eine Frage, die hier nicht beantwortet wird? Schreib eine E-Mail an",
    introAfterEmail: ".",
    items: [
      {
        question: "Ist GetSpot kostenlos?",
        answer: "Ja. Es gibt kein Abonnement und keine Transaktionsgebühr für Organisatoren oder Spieler.",
      },
      {
        question: "Brauche ich einen Zahlungsdienstleister oder ein Geschäftskonto?",
        answer:
          "Nein. GetSpot verwendet ein virtuelles Wallet statt eines Zahlungs-Gateways. Du kassierst die echte Zahlung von Mitgliedern wie gewohnt — Bargeld, PayPal, Überweisung usw. — und schreibst sie dann im App-Wallet gut. GetSpot kommt nie mit echten Zahlungsdaten in Berührung.",
      },
      {
        question: "Wie funktioniert das Wallet genau?",
        answer:
          "Wallet-Guthaben sind pro Gruppe. Ein Organisator schreibt das Guthaben eines Mitglieds gut, nachdem er die Zahlung offline erhalten hat. Meldet sich dieses Mitglied für ein Event in der Gruppe an, wird die Gebühr automatisch von seinem Guthaben abgezogen.",
      },
      {
        question: "Was passiert, wenn ich nach der Frist absage?",
        answer:
          "Jedes Event kann eine Verbindlichkeitsfrist haben. Eine Absage danach lässt die Gebühr verfallen, es sei denn, ein Mitglied von der Warteliste übernimmt den freien Platz. So bleibt die Teilnehmerzahl für den Organisator verlässlich.",
      },
      {
        question: "Was, wenn ich vor der Frist zurücktrete?",
        answer: "Deine Gebühr wird automatisch auf dein Wallet zurückerstattet — keine manuelle Anfrage nötig.",
      },
      {
        question: "Was passiert, wenn ein Platz auf der Warteliste frei wird?",
        answer:
          "Die nächste Person auf der Warteliste wird automatisch bestätigt und benachrichtigt — ohne manuelle Koordination durch den Organisator.",
      },
      {
        question: "Kann ich mehr als einer Gruppe beitreten?",
        answer:
          "Ja. Spieler können mit einem einzigen Konto mehreren Sportgruppen beitreten, und Organisatoren können ebenfalls mehrere Gruppen erstellen und verwalten.",
      },
      {
        question: "Sind meine Daten und Zahlungsinformationen sicher?",
        answer:
          "GetSpot basiert auf Firebase mit Standard-Authentifizierung und Sicherheitsregeln. Da echte Zahlungen offline zwischen dir und deinem Organisator stattfinden, laufen deine Zahlungsdaten nie über die Server von GetSpot.",
      },
      {
        question: "Für welche Sportarten eignet sich GetSpot?",
        answer:
          "Jedes wiederkehrende Sporttreffen mit Kapazitätsgrenze und Gebühr — Badminton, Basketball, Fußball, Tennis, Volleyball und ähnliche Formate.",
      },
      {
        question: "Wie fange ich an?",
        answer:
          "Lade die App herunter, melde dich mit Google oder Apple an und erstelle entweder eine Gruppe (du erhältst einen teilbaren Code für deine Mitglieder) oder tritt einer mit einem Code deines Organisators bei.",
      },
    ],
    ctaOpenApp: "App öffnen",
  },
  privacy: {
    metaTitle: "Datenschutzerklärung — GetSpot",
    metaDescription:
      "Wie GetSpot Informationen über dich sammelt, verwendet und weitergibt, wenn du die App nutzt.",
  },
};

export default de;
