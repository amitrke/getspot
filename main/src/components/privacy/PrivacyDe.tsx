import PrivacySection from "@/components/PrivacySection";

export default function PrivacyDe() {
  return (
    <>
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">Datenschutzerklärung</h1>
        <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">Zuletzt aktualisiert: 23. August 2026</p>
      </div>

      <p className="mt-10 text-sm text-zinc-500 dark:text-zinc-400">
        Vielen Dank, dass du GetSpot nutzt. Diese Datenschutzerklärung erläutert, wie wir Informationen
        über dich sammeln, verwenden und weitergeben, wenn du unsere mobile App und die zugehörigen
        Dienste (zusammen die &bdquo;Dienste&ldquo;) nutzt.
      </p>

      <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">
        <strong className="text-zinc-700 dark:text-zinc-300">Hinweis:</strong> Dies ist eine Vorlage für
        eine Datenschutzerklärung und stellt keine Rechtsberatung dar. Du solltest dich von einem
        Rechtsexperten beraten lassen, um sicherzustellen, dass diese Richtlinie für deine spezifische
        Situation geeignet und rechtskonform ist.
      </p>

      <div className="mt-16">
        <PrivacySection number={1} title="Informationen, die wir sammeln">
          <p>
            Wir sammeln Informationen, die du uns direkt zur Verfügung stellst, sowie Informationen, die
            automatisch durch deine Nutzung unserer Dienste erfasst werden.
          </p>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">
            a) Informationen, die du uns zur Verfügung stellst:
          </p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Kontoinformationen:</strong> Wenn du
              dich für ein Konto registrierst, erfassen wir deinen Namen und deine E-Mail-Adresse über
              Firebase Authentication.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Gruppeninformationen:</strong> Wir
              erfassen Informationen über die Gruppen, die du erstellst oder denen du beitrittst,
              einschließlich Gruppenname, Beschreibung und Mitglieder.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Event-Informationen:</strong> Wir
              erfassen Details zu den Events, die du erstellst oder für die du dich anmeldest,
              einschließlich Eventname, Uhrzeit, Gebühr und deinem Teilnahmestatus.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Wallet- und Transaktionsinformationen:
              </strong>{" "}
              Wir führen ein Protokoll deines virtuellen Wallet-Guthabens sowie eine Historie aller mit
              deinem Konto verbundenen Transaktionen (z. B. Event-Gebührenzahlungen, Strafen,
              Rückerstattungen).
            </li>
          </ul>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">
            b) Informationen, die wir automatisch sammeln:
          </p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Nutzungsinformationen:</strong> Wir
              erfassen Informationen über deine Aktivität in den Diensten, z. B. welche Funktionen du
              nutzt und wann du sie nutzt.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Geräteinformationen:</strong> Wir
              können Informationen über das Gerät sammeln, mit dem du auf unsere Dienste zugreifst,
              einschließlich Hardwaremodell, Betriebssystem und eindeutiger Gerätekennungen.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Firebase Cloud Messaging (FCM)-Token:
              </strong>{" "}
              Um dir Push-Benachrichtigungen zu senden, erfassen und speichern wir dein
              FCM-Registrierungstoken.
            </li>
          </ul>
        </PrivacySection>

        <PrivacySection number={2} title="Wie wir deine Informationen verwenden">
          <p>Wir verwenden die von uns gesammelten Informationen, um:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>Unsere Dienste bereitzustellen, zu pflegen und zu verbessern.</li>
            <li>Dein Konto, deine Gruppen und Events zu erstellen und zu verwalten.</li>
            <li>Transaktionen für dein virtuelles Wallet zu verarbeiten.</li>
            <li>
              Mit dir zu kommunizieren, unter anderem durch Event-Erinnerungen, Wartelisten-Updates und
              andere dienstbezogene Benachrichtigungen.
            </li>
            <li>Die Sicherheit unserer Dienste zu gewährleisten.</li>
            <li>Deine Erfahrung zu personalisieren.</li>
          </ul>
        </PrivacySection>

        <PrivacySection number={3} title="Wie wir deine Informationen weitergeben">
          <p>Wir können deine Informationen in folgenden Situationen weitergeben:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Mit anderen Gruppenmitgliedern:</strong>{" "}
              Dein Name und dein Teilnahmestatus für Events sind für andere Mitglieder der Gruppen
              sichtbar, denen du angehörst. Gruppenadministratoren können außerdem die Wallet-Guthaben der
              Mitglieder einsehen.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Mit Dienstleistern:</strong> Wir nutzen
              Drittanbieter-Dienstleister, um unsere Dienste zu betreiben, etwa Google Firebase für
              Backend-Infrastruktur, Authentifizierung und Hosting. Diese Anbieter haben nur Zugriff auf
              deine Informationen, um Dienstleistungen in unserem Auftrag zu erbringen, und dürfen diese
              nicht für andere Zwecke offenlegen oder verwenden.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Aus rechtlichen Gründen:</strong> Wir
              können deine Informationen offenlegen, wenn wir dies für angemessen erforderlich halten, um
              einem Gesetz, einer Vorschrift, einem gerichtlichen Verfahren oder einer behördlichen
              Anfrage nachzukommen.
            </li>
          </ul>
          <p>Wir verkaufen deine persönlichen Informationen nicht an Dritte.</p>
        </PrivacySection>

        <PrivacySection number={4} title="Datensicherheit">
          <p>
            Wir verwenden Google Firebase, das branchenübliche Sicherheitsmaßnahmen implementiert, um
            deine Informationen vor unbefugtem Zugriff, Veränderung, Offenlegung oder Zerstörung zu
            schützen. Kein Sicherheitssystem ist jedoch unüberwindbar, und wir können die absolute
            Sicherheit deiner Informationen nicht garantieren.
          </p>
        </PrivacySection>

        <PrivacySection number={5} title="Datenspeicherung">
          <p>
            Wir speichern deine persönlichen Informationen, solange dein Konto aktiv ist oder soweit dies
            zur Bereitstellung der Dienste erforderlich ist. Wir können Informationen außerdem aufbewahren,
            um unseren rechtlichen Verpflichtungen nachzukommen, Streitigkeiten beizulegen und unsere
            Vereinbarungen durchzusetzen.
          </p>
        </PrivacySection>

        <PrivacySection number={6} title="Deine Rechte">
          <p>
            Du hast das Recht, auf deine persönlichen Informationen zuzugreifen, sie zu aktualisieren oder
            zu löschen. Die meisten deiner Informationen kannst du direkt in der App verwalten.
          </p>
        </PrivacySection>

        <PrivacySection number={7} title="Antrag auf Datenlöschung">
          <p>
            Du kannst dein Konto und alle zugehörigen Daten direkt in der App löschen: Öffne deinen
            Profilbildschirm und tippe auf &bdquo;Konto löschen&ldquo;. Dies erfolgt sofort und kann nicht
            rückgängig gemacht werden. Solltest du in einer Gruppe ein negatives Wallet-Guthaben haben,
            musst du dieses mit deinem Gruppenadministrator ausgleichen, bevor du dein Konto löschen
            kannst.
          </p>
          <p>
            Solltest du keinen Zugriff auf die App haben, kannst du stattdessen eine E-Mail an{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>{" "}
            senden, um die Löschung zu beantragen.
          </p>
        </PrivacySection>

        <PrivacySection number={8} title="Datenschutz für Kinder">
          <p>
            Unsere Dienste richten sich nicht an Personen unter 13 Jahren. Wir sammeln wissentlich keine
            personenbezogenen Daten von Kindern unter 13 Jahren. Sollten wir feststellen, dass uns ein
            Kind unter 13 Jahren personenbezogene Daten zur Verfügung gestellt hat, werden wir Schritte
            unternehmen, um diese Informationen zu löschen.
          </p>
        </PrivacySection>

        <PrivacySection number={9} title="Änderungen dieser Richtlinie">
          <p>
            Wir können diese Datenschutzerklärung von Zeit zu Zeit aktualisieren. Wir werden dich über
            Änderungen informieren, indem wir die neue Datenschutzerklärung auf dieser Seite
            veröffentlichen und das Datum &bdquo;Zuletzt aktualisiert&ldquo; aktualisieren.
          </p>
        </PrivacySection>

        <PrivacySection number={10} title="Kontakt">
          <p>
            Wenn du Fragen zu dieser Datenschutzerklärung hast, sende bitte eine E-Mail an{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>
            .
          </p>
        </PrivacySection>
      </div>
    </>
  );
}
