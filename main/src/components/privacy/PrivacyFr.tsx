import PrivacySection from "@/components/PrivacySection";

export default function PrivacyFr() {
  return (
    <>
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">Politique de confidentialité</h1>
        <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">Dernière mise à jour : 23 août 2026</p>
      </div>

      <p className="mt-10 text-sm text-zinc-500 dark:text-zinc-400">
        Merci d&apos;utiliser GetSpot. Cette politique de confidentialité explique comment nous
        collectons, utilisons et partageons des informations vous concernant lorsque vous utilisez notre
        application mobile et les services associés (collectivement, les « Services »).
      </p>

      <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">
        <strong className="text-zinc-700 dark:text-zinc-300">Avertissement :</strong> Ceci est un modèle
        de politique de confidentialité et ne constitue pas un avis juridique. Vous devriez consulter un
        professionnel du droit pour vous assurer que cette politique est appropriée et conforme à votre
        situation spécifique.
      </p>

      <div className="mt-16">
        <PrivacySection number={1} title="Informations que nous collectons">
          <p>
            Nous collectons les informations que vous nous fournissez directement, ainsi que les
            informations collectées automatiquement lors de votre utilisation de nos Services.
          </p>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">
            a) Informations que vous nous fournissez :
          </p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Informations de compte :</strong>{" "}
              Lorsque vous vous inscrivez pour un compte, nous collectons votre nom et votre adresse
              e-mail via Firebase Authentication.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Informations sur le groupe :</strong>{" "}
              Nous collectons des informations sur les groupes que vous créez ou rejoignez, y compris le
              nom du groupe, la description et les membres.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Informations sur l&apos;événement :</strong>{" "}
              Nous collectons des détails sur les événements que vous créez ou auxquels vous vous
              inscrivez, y compris le nom de l&apos;événement, l&apos;heure, les frais et votre statut de
              participation.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Informations sur le portefeuille et les transactions :
              </strong>{" "}
              Nous conservons un enregistrement du solde de votre portefeuille virtuel et un historique de
              toutes les transactions (par exemple, paiements de frais d&apos;événement, pénalités,
              remboursements) associées à votre compte.
            </li>
          </ul>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">
            b) Informations que nous collectons automatiquement :
          </p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Informations d&apos;utilisation :</strong>{" "}
              Nous collectons des informations sur votre activité au sein des Services, telles que les
              fonctionnalités que vous utilisez et le moment où vous les utilisez.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Informations sur l&apos;appareil :</strong>{" "}
              Nous pouvons collecter des informations sur l&apos;appareil que vous utilisez pour accéder à
              nos Services, y compris le modèle matériel, le système d&apos;exploitation et les
              identifiants uniques de l&apos;appareil.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Jeton Firebase Cloud Messaging (FCM) :
              </strong>{" "}
              Pour vous envoyer des notifications push, nous collectons et stockons votre jeton
              d&apos;enregistrement FCM.
            </li>
          </ul>
        </PrivacySection>

        <PrivacySection number={2} title="Comment nous utilisons vos informations">
          <p>Nous utilisons les informations que nous collectons pour :</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>Fournir, maintenir et améliorer nos Services.</li>
            <li>Créer et gérer votre compte, vos groupes et vos événements.</li>
            <li>Traiter les transactions de votre portefeuille virtuel.</li>
            <li>
              Communiquer avec vous, notamment en envoyant des rappels d&apos;événements, des mises à jour
              de liste d&apos;attente et d&apos;autres notifications liées au service.
            </li>
            <li>Assurer la sécurité de nos Services.</li>
            <li>Personnaliser votre expérience.</li>
          </ul>
        </PrivacySection>

        <PrivacySection number={3} title="Comment nous partageons vos informations">
          <p>Nous pouvons partager vos informations dans les situations suivantes :</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Avec les autres membres du groupe :
              </strong>{" "}
              Votre nom et votre statut de participation aux événements sont visibles par les autres
              membres des groupes auxquels vous appartenez. Les administrateurs de groupe peuvent
              également consulter les soldes de portefeuille des membres.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Avec des prestataires de services :</strong>{" "}
              Nous faisons appel à des prestataires de services tiers pour nous aider à exploiter nos
              Services, comme Google Firebase pour l&apos;infrastructure back-end, l&apos;authentification
              et l&apos;hébergement. Ces prestataires n&apos;ont accès à vos informations que pour exécuter
              des services en notre nom et sont tenus de ne pas les divulguer ni les utiliser à d&apos;autres
              fins.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Pour des raisons légales :</strong> Nous
              pouvons divulguer vos informations si nous estimons raisonnablement nécessaire de nous
              conformer à une loi, un règlement, une procédure judiciaire ou une demande gouvernementale.
            </li>
          </ul>
          <p>Nous ne vendons pas vos informations personnelles à des tiers.</p>
        </PrivacySection>

        <PrivacySection number={4} title="Sécurité des données">
          <p>
            Nous utilisons Google Firebase, qui met en œuvre des mesures de sécurité conformes aux normes
            du secteur pour protéger vos informations contre tout accès non autorisé, toute altération,
            divulgation ou destruction. Cependant, aucun système de sécurité n&apos;est infaillible, et
            nous ne pouvons garantir la sécurité absolue de vos informations.
          </p>
        </PrivacySection>

        <PrivacySection number={5} title="Conservation des données">
          <p>
            Nous conservons vos informations personnelles aussi longtemps que votre compte est actif ou
            selon les besoins pour vous fournir les Services. Nous pouvons également conserver des
            informations afin de nous conformer à nos obligations légales, résoudre des litiges et faire
            respecter nos accords.
          </p>
        </PrivacySection>

        <PrivacySection number={6} title="Vos droits">
          <p>
            Vous avez le droit d&apos;accéder à vos informations personnelles, de les mettre à jour ou de
            les supprimer. Vous pouvez gérer la plupart de vos informations directement dans
            l&apos;application.
          </p>
        </PrivacySection>

        <PrivacySection number={7} title="Demande de suppression des données">
          <p>
            Vous pouvez supprimer votre compte et toutes les données associées directement dans
            l&apos;application : ouvrez votre écran de profil et appuyez sur « Supprimer le compte ».
            Cette action est immédiate et irréversible. Si vous avez un solde de portefeuille négatif dans
            un groupe, vous devrez le régler avec l&apos;administrateur de votre groupe avant de pouvoir
            supprimer votre compte.
          </p>
          <p>
            Si vous ne pouvez pas accéder à l&apos;application, vous pouvez envoyer un e-mail à{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>{" "}
            pour demander la suppression.
          </p>
        </PrivacySection>

        <PrivacySection number={8} title="Confidentialité des enfants">
          <p>
            Nos Services ne s&apos;adressent pas aux personnes de moins de 13 ans. Nous ne collectons pas
            sciemment d&apos;informations personnelles auprès d&apos;enfants de moins de 13 ans. Si nous
            apprenons qu&apos;un enfant de moins de 13 ans nous a fourni des informations personnelles,
            nous prendrons des mesures pour supprimer ces informations.
          </p>
        </PrivacySection>

        <PrivacySection number={9} title="Modifications de cette politique">
          <p>
            Nous pouvons mettre à jour cette politique de confidentialité de temps à autre. Nous vous
            informerons de tout changement en publiant la nouvelle politique de confidentialité sur cette
            page et en mettant à jour la date de « Dernière mise à jour ».
          </p>
        </PrivacySection>

        <PrivacySection number={10} title="Nous contacter">
          <p>
            Si vous avez des questions concernant cette politique de confidentialité, veuillez envoyer un
            e-mail à{" "}
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
