import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Features — GetSpot",
  description:
    "See how GetSpot handles group management, event scheduling, waitlists, and payments for recurring sports meetups.",
};

const organizerFeatures = [
  {
    title: "Create events in seconds",
    description:
      "Set date, time, location, capacity, and fee — post it and members are notified immediately.",
  },
  {
    title: "Automatic waitlists",
    description:
      "Once an event fills up, new registrations join the waitlist automatically. When a confirmed spot opens up, the next person in line is promoted with no manual work.",
  },
  {
    title: "Virtual wallet system",
    description:
      "Collect payment from members however you already do — cash, Venmo, Zelle — then credit their wallet in the app. Registration fees are deducted automatically.",
  },
  {
    title: "Commitment deadlines",
    description:
      "Set a deadline after which a cancellation forfeits the fee (unless a waitlisted member takes the spot), so your headcount stays reliable.",
  },
  {
    title: "Group announcements",
    description: "Send updates to every member of a group at once.",
  },
  {
    title: "Member management",
    description:
      "Approve join requests, add or remove members, and credit wallets from one screen.",
  },
];

const playerFeatures = [
  {
    title: "One-tap registration",
    description: "Register for an event instantly; your fee is deducted from your group wallet balance right away.",
  },
  {
    title: "Real-time status",
    description:
      "Know immediately whether you're confirmed or waitlisted, and get notified automatically if you're promoted off the waitlist.",
  },
  {
    title: "Automatic refunds",
    description:
      "Withdraw before the commitment deadline and your fee is refunded to your wallet automatically.",
  },
  {
    title: "Wallet balance tracking",
    description: "See your balance per group at any time — no guessing what you've paid or what you owe.",
  },
  {
    title: "Push notifications",
    description: "Get notified about new events, registration status changes, and reminders before games.",
  },
  {
    title: "Multiple groups, one account",
    description: "Join as many sports groups as you play in, all from a single sign-in.",
  },
];

function FeatureGrid({
  features,
}: {
  features: { title: string; description: string }[];
}) {
  return (
    <div className="grid grid-cols-1 gap-8 sm:grid-cols-2">
      {features.map((feature) => (
        <div key={feature.title}>
          <h3 className="text-sm font-semibold">{feature.title}</h3>
          <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
            {feature.description}
          </p>
        </div>
      ))}
    </div>
  );
}

export default function FeaturesPage() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header />

      <main className="mx-auto w-full max-w-3xl flex-1 px-5 py-16 sm:py-24">
        <div className="text-center">
          <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
            Everything you need to run recurring sports meetups
          </h1>
          <p className="mt-4 text-lg text-zinc-500 dark:text-zinc-400">
            No spreadsheets, no chasing payments, no manual waitlists.
          </p>
        </div>

        <section className="mt-16">
          <h2 className="text-xs font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
            For organizers
          </h2>
          <div className="mt-6">
            <FeatureGrid features={organizerFeatures} />
          </div>
        </section>

        <section className="mt-16">
          <h2 className="text-xs font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
            For players
          </h2>
          <div className="mt-6">
            <FeatureGrid features={playerFeatures} />
          </div>
        </section>

        <div className="mt-20 flex flex-wrap justify-center gap-3">
          <a
            href="https://app.getspot.org"
            className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
          >
            Open the app
          </a>
          <a
            href="/faq"
            className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
          >
            Read the FAQ
          </a>
        </div>
      </main>

      <Footer />
    </div>
  );
}
