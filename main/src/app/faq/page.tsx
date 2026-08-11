import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "FAQ — GetSpot",
  description:
    "Answers to common questions about how GetSpot's virtual wallet, refunds, and group sharing work.",
};

const faqs = [
  {
    question: "Is GetSpot free to use?",
    answer:
      "Yes. There's no subscription and no per-transaction fee for organizers or players.",
  },
  {
    question: "Do I need a payment processor or business account?",
    answer:
      "No. GetSpot uses a virtual wallet instead of a payment gateway. You collect real payment from members however you already do — cash, Venmo, Zelle, etc. — then credit their wallet in the app. GetSpot never touches real payment details.",
  },
  {
    question: "How does the wallet actually work?",
    answer:
      "Wallet balances are per group. An organizer credits a member's wallet after collecting payment offline. When that member registers for an event in the group, the fee is deducted from their wallet balance automatically.",
  },
  {
    question: "What happens if I cancel after the deadline?",
    answer:
      "Each event can have a commitment deadline. Cancelling after it forfeits the fee, unless a waitlisted member takes the open spot. This keeps headcounts reliable for the organizer.",
  },
  {
    question: "What if I withdraw before the deadline?",
    answer: "Your fee is refunded to your wallet automatically — no manual request needed.",
  },
  {
    question: "What happens if a spot opens up on the waitlist?",
    answer:
      "The next person on the waitlist is confirmed automatically and notified — no manual coordination by the organizer.",
  },
  {
    question: "Can I join more than one group?",
    answer:
      "Yes. Players can join multiple sports groups with a single account, and organizers can create and manage multiple groups too.",
  },
  {
    question: "Is my data and payment info safe?",
    answer:
      "GetSpot is built on Firebase with standard authentication and security rules. Since real payments happen offline between you and your organizer, your payment details never pass through GetSpot's servers at all.",
  },
  {
    question: "What sports does GetSpot work for?",
    answer:
      "Any recurring sports meetup with a capacity limit and a fee — badminton, basketball, soccer, tennis, volleyball, and similar formats.",
  },
  {
    question: "How do I get started?",
    answer:
      "Download the app, sign in with Google or Apple, and either create a group (you'll get a shareable code for your members) or join one with a code from your organizer.",
  },
];

export default function FaqPage() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header />

      <main className="mx-auto w-full max-w-2xl flex-1 px-5 py-16 sm:py-24">
        <div className="text-center">
          <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
            Frequently asked questions
          </h1>
          <p className="mt-4 text-lg text-zinc-500 dark:text-zinc-400">
            Have a question that isn&apos;t answered here? Email{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>
            .
          </p>
        </div>

        <div className="mt-16 divide-y divide-zinc-200 dark:divide-zinc-800">
          {faqs.map((faq) => (
            <details key={faq.question} className="group py-5">
              <summary className="flex cursor-pointer list-none items-center justify-between text-left text-sm font-semibold">
                {faq.question}
                <span className="ml-4 shrink-0 text-zinc-400 transition-transform group-open:rotate-45">
                  +
                </span>
              </summary>
              <p className="mt-3 text-sm text-zinc-500 dark:text-zinc-400">
                {faq.answer}
              </p>
            </details>
          ))}
        </div>

        <div className="mt-16 flex justify-center">
          <a
            href="https://app.getspot.org"
            className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
          >
            Open the app
          </a>
        </div>
      </main>

      <Footer />
    </div>
  );
}
