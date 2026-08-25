import type { Dictionary, Locale } from "@/content/types";
import { localizedHref } from "@/content/routes";

function FeatureGrid({ features }: { features: { title: string; description: string }[] }) {
  return (
    <div className="grid grid-cols-1 gap-8 sm:grid-cols-2">
      {features.map((feature) => (
        <div key={feature.title}>
          <h3 className="text-sm font-semibold">{feature.title}</h3>
          <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">{feature.description}</p>
        </div>
      ))}
    </div>
  );
}

export default function FeaturesContent({ locale, dict }: { locale: Locale; dict: Dictionary }) {
  const t = dict.features;

  return (
    <main className="mx-auto w-full max-w-3xl flex-1 px-5 py-16 sm:py-24">
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">{t.title}</h1>
        <p className="mt-4 text-lg text-zinc-500 dark:text-zinc-400">{t.subtitle}</p>
      </div>

      <section className="mt-16">
        <h2 className="text-xs font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
          {t.forOrganizers}
        </h2>
        <div className="mt-6">
          <FeatureGrid features={t.organizerFeatures} />
        </div>
      </section>

      <section className="mt-16">
        <h2 className="text-xs font-semibold tracking-wide text-zinc-400 uppercase dark:text-zinc-500">
          {t.forPlayers}
        </h2>
        <div className="mt-6">
          <FeatureGrid features={t.playerFeatures} />
        </div>
      </section>

      <div className="mt-20 flex flex-wrap justify-center gap-3">
        <a
          href="https://app.getspot.org"
          className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
        >
          {t.ctaOpenApp}
        </a>
        <a
          href={localizedHref(locale, "faq")}
          className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
        >
          {t.ctaReadFaq}
        </a>
      </div>
    </main>
  );
}
