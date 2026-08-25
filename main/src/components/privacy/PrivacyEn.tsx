import PrivacySection from "@/components/PrivacySection";

export default function PrivacyEn() {
  return (
    <>
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">Privacy Policy</h1>
        <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">Last Updated: August 23, 2026</p>
      </div>

      <p className="mt-10 text-sm text-zinc-500 dark:text-zinc-400">
        Thank you for using GetSpot. This Privacy Policy explains how we collect, use, and share
        information about you when you use our mobile application and related services (collectively,
        the &ldquo;Services&rdquo;).
      </p>

      <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">
        <strong className="text-zinc-700 dark:text-zinc-300">Disclaimer:</strong> This is a template
        privacy policy and does not constitute legal advice. You should consult with a legal professional
        to ensure this policy is appropriate and compliant for your specific situation.
      </p>

      <div className="mt-16">
        <PrivacySection number={1} title="Information We Collect">
          <p>
            We collect information you provide directly to us and information that is collected
            automatically through your use of our Services.
          </p>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">a) Information You Provide to Us:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Account Information:</strong> When you
              register for an account, we collect your name and email address through Firebase
              Authentication.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Group Information:</strong> We collect
              information about the groups you create or join, including the group name, description, and
              members.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Event Information:</strong> We collect
              details about the events you create or register for, including event name, time, fee, and
              your participation status.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Wallet and Transaction Information:</strong>{" "}
              We maintain a record of your virtual wallet balance and a history of all transactions (e.g.,
              event fee payments, penalties, refunds) associated with your account.
            </li>
          </ul>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">b) Information We Collect Automatically:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Usage Information:</strong> We collect
              information about your activity on the Services, such as which features you use and when you
              use them.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Device Information:</strong> We may
              collect information about the device you use to access our Services, including the hardware
              model, operating system, and unique device identifiers.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Firebase Cloud Messaging (FCM) Token:
              </strong>{" "}
              To send you push notifications, we collect and store your FCM registration token.
            </li>
          </ul>
        </PrivacySection>

        <PrivacySection number={2} title="How We Use Your Information">
          <p>We use the information we collect to:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>Provide, maintain, and improve our Services.</li>
            <li>Create and manage your account, groups, and events.</li>
            <li>Process transactions for your virtual wallet.</li>
            <li>
              Communicate with you, including sending event reminders, waitlist updates, and other
              service-related notifications.
            </li>
            <li>Ensure the security of our Services.</li>
            <li>Personalize your experience.</li>
          </ul>
        </PrivacySection>

        <PrivacySection number={3} title="How We Share Your Information">
          <p>We may share your information in the following situations:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">With Other Group Members:</strong> Your
              name and participation status for events are visible to other members of the groups you are
              in. Group administrators can also view member wallet balances.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">With Service Providers:</strong> We use
              third-party service providers to help us operate our Services, such as Google Firebase for
              backend infrastructure, authentication, and hosting. These providers have access to your
              information only to perform services on our behalf and are obligated not to disclose or use
              it for any other purpose.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">For Legal Reasons:</strong> We may
              disclose your information if we believe that it is reasonably necessary to comply with a law,
              regulation, legal process, or governmental request.
            </li>
          </ul>
          <p>We do not sell your personal information to third parties.</p>
        </PrivacySection>

        <PrivacySection number={4} title="Data Security">
          <p>
            We use Google Firebase, which implements industry-standard security measures to protect your
            information from unauthorized access, alteration, disclosure, or destruction. However, no
            security system is impenetrable, and we cannot guarantee the absolute security of your
            information.
          </p>
        </PrivacySection>

        <PrivacySection number={5} title="Data Retention">
          <p>
            We retain your personal information for as long as your account is active or as needed to
            provide you with the Services. We may also retain information to comply with our legal
            obligations, resolve disputes, and enforce our agreements.
          </p>
        </PrivacySection>

        <PrivacySection number={6} title="Your Rights">
          <p>
            You have the right to access, update, or delete your personal information. You can manage most
            of your information directly within the app.
          </p>
        </PrivacySection>

        <PrivacySection number={7} title="Data Deletion Request">
          <p>
            You can delete your account and all associated data directly within the app: open your profile
            screen and tap &ldquo;Delete Account.&rdquo; This is immediate and cannot be undone. If you have
            a negative wallet balance in any group, you&apos;ll need to settle it with your group admin
            before you can delete your account.
          </p>
          <p>
            If you&apos;re unable to access the app, you can email{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>{" "}
            to request deletion instead.
          </p>
        </PrivacySection>

        <PrivacySection number={8} title="Children's Privacy">
          <p>
            Our Services are not directed to individuals under the age of 13. We do not knowingly collect
            personal information from children under 13. If we become aware that a child under 13 has
            provided us with personal information, we will take steps to delete such information.
          </p>
        </PrivacySection>

        <PrivacySection number={9} title="Changes to This Policy">
          <p>
            We may update this Privacy Policy from time to time. We will notify you of any changes by
            posting the new Privacy Policy on this page and updating the &ldquo;Last Updated&rdquo; date.
          </p>
        </PrivacySection>

        <PrivacySection number={10} title="Contact Us">
          <p>
            If you have any questions about this Privacy Policy, please email{" "}
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
