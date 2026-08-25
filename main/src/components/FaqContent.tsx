import type { Dictionary } from "@/content/types";

export default function FaqContent({ dict }: { dict: Dictionary }) {
  const t = dict.faq;

  return (
    <main className="mx-auto w-full max-w-2xl flex-1 px-5 py-16 sm:py-24">
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">{t.title}</h1>
        <p className="mt-4 text-lg text-zinc-500 dark:text-zinc-400">
          {t.introBeforeEmail}{" "}
          <a href="mailto:support@getspot.org" className="underline hover:no-underline">
            support@getspot.org
          </a>
          {t.introAfterEmail}
        </p>
      </div>

      <div className="mt-16 divide-y divide-zinc-200 dark:divide-zinc-800">
        {t.items.map((faq, index) => (
          <details key={faq.question} open={index === 0} className="group py-5">
            <summary className="flex cursor-pointer list-none items-center justify-between text-left text-sm font-semibold">
              {faq.question}
              <span className="ml-4 shrink-0 text-zinc-400 transition-transform group-open:rotate-45">
                +
              </span>
            </summary>
            <p className="mt-3 text-sm text-zinc-500 dark:text-zinc-400">{faq.answer}</p>
          </details>
        ))}
      </div>

      <div className="mt-16 flex justify-center">
        <a
          href="https://app.getspot.org"
          className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
        >
          {t.ctaOpenApp}
        </a>
      </div>
    </main>
  );
}
