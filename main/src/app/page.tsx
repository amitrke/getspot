const features = [
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
];

export default function Home() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <header className="mx-auto flex w-full max-w-3xl items-center justify-between px-5 py-6">
        <span className="text-lg font-bold tracking-tight">GetSpot</span>
        <a
          href="https://app.getspot.org"
          className="text-sm text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
        >
          Open App →
        </a>
      </header>

      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col items-center px-5 py-16 text-center sm:py-24">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
          Organize sports meetups without the group-chat chaos
        </h1>
        <p className="mt-4 max-w-lg text-lg text-zinc-500 dark:text-zinc-400">
          GetSpot helps organizers schedule events, manage participants and
          waitlists, and handle group payments — built for badminton and
          other sports groups.
        </p>

        <div className="mt-10 flex flex-wrap justify-center gap-3">
          <a
            href="https://app.getspot.org"
            className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
          >
            Open the app
          </a>
          <a
            href="https://apps.apple.com/us/app/sports-getspot/id6752911639"
            className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
          >
            iOS App Store
          </a>
          <a
            href="https://play.google.com/store/apps/details?id=org.getspot"
            className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
          >
            Google Play
          </a>
        </div>

        <div className="mt-20 grid w-full grid-cols-1 gap-6 text-left sm:grid-cols-3">
          {features.map((feature) => (
            <div key={feature.title}>
              <h3 className="text-sm font-semibold">{feature.title}</h3>
              <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </main>

      <footer className="mx-auto w-full max-w-3xl px-5 py-8 text-center text-sm text-zinc-500 dark:text-zinc-400">
        © 2026 GetSpot ·{" "}
        <a href="https://app.getspot.org" className="hover:underline">
          app.getspot.org
        </a>
      </footer>
    </div>
  );
}
