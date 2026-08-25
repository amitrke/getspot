import type { Dictionary } from "./types";

const en: Dictionary = {
  header: {
    brand: "GetSpot",
    navFeatures: "Features",
    navFaq: "FAQ",
    openApp: "Open App →",
  },
  footer: {
    copyright: "© 2026 GetSpot ·",
    appLink: "app.getspot.org",
    privacyLink: "Privacy",
  },
  home: {
    metaTitle: "GetSpot — Organize sports meetups with ease",
    metaDescription:
      "GetSpot helps organizers schedule events, manage participants, and handle group payments for badminton and other sports meetups.",
    title: "Organize sports meetups without the group-chat chaos",
    subtitle:
      "GetSpot helps organizers schedule events, manage participants and waitlists, and handle group payments — built for badminton and other sports groups.",
    ctaOpenApp: "Open the app",
    ctaIosApp: "iOS App Store",
    ctaAndroidApp: "Google Play",
    features: [
      {
        title: "Groups",
        description:
          "Create a group, share a join code, and manage members in one place.",
      },
      {
        title: "Events",
        description:
          "Schedule sessions with capacity limits, waitlists, and fair confirmation rules.",
      },
      {
        title: "Wallet",
        description:
          "Track group balances and payments without chasing people for cash.",
      },
    ],
    seeAllFeatures: "See all features →",
  },
  features: {
    metaTitle: "Features — GetSpot",
    metaDescription:
      "See how GetSpot handles group management, event scheduling, waitlists, and payments for recurring sports meetups.",
    title: "Everything you need to run recurring sports meetups",
    subtitle: "No spreadsheets, no chasing payments, no manual waitlists.",
    forOrganizers: "For organizers",
    forPlayers: "For players",
    organizerFeatures: [
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
    ],
    playerFeatures: [
      {
        title: "One-tap registration",
        description:
          "Register for an event instantly; your fee is deducted from your group wallet balance right away.",
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
        description:
          "See your balance per group at any time — no guessing what you've paid or what you owe.",
      },
      {
        title: "Push notifications",
        description:
          "Get notified about new events, registration status changes, and reminders before games.",
      },
      {
        title: "Multiple groups, one account",
        description:
          "Join as many sports groups as you play in, all from a single sign-in.",
      },
    ],
    ctaOpenApp: "Open the app",
    ctaReadFaq: "Read the FAQ",
  },
  faq: {
    metaTitle: "FAQ — GetSpot",
    metaDescription:
      "Answers to common questions about how GetSpot's virtual wallet, refunds, and group sharing work.",
    title: "Frequently asked questions",
    introBeforeEmail: "Have a question that isn't answered here? Email",
    introAfterEmail: ".",
    items: [
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
        answer:
          "Your fee is refunded to your wallet automatically — no manual request needed.",
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
    ],
    ctaOpenApp: "Open the app",
  },
  privacy: {
    metaTitle: "Privacy Policy — GetSpot",
    metaDescription:
      "How GetSpot collects, uses, and shares information about you when you use the app.",
  },
};

export default en;
