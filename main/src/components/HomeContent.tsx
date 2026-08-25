import Link from "next/link";
import type { Dictionary, Locale } from "@/content/types";
import { localizedHref } from "@/content/routes";

export default function HomeContent({ locale, dict }: { locale: Locale; dict: Dictionary }) {
  const t = dict.home;

  return (
    <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col items-center px-5 py-16 text-center sm:py-24">
      <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">{t.title}</h1>
      <p className="mt-4 max-w-lg text-lg text-zinc-500 dark:text-zinc-400">{t.subtitle}</p>

      <div className="mt-10 flex flex-wrap justify-center gap-3">
        <a
          href="https://app.getspot.org"
          className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-semibold text-white hover:bg-blue-500"
        >
          {t.ctaOpenApp}
        </a>
        <a
          href="https://apps.apple.com/us/app/sports-getspot/id6752911639"
          className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
        >
          {t.ctaIosApp}
        </a>
        <a
          href="https://play.google.com/store/apps/details?id=org.getspot"
          className="rounded-lg border border-zinc-300 px-6 py-3 text-sm font-semibold hover:bg-zinc-50 dark:border-zinc-700 dark:hover:bg-zinc-900"
        >
          {t.ctaAndroidApp}
        </a>
      </div>

      <div className="mt-20 grid w-full grid-cols-1 gap-6 text-left sm:grid-cols-3">
        {t.features.map((feature) => (
          <div key={feature.title}>
            <h3 className="text-sm font-semibold">{feature.title}</h3>
            <p className="mt-2 text-sm text-zinc-500 dark:text-zinc-400">{feature.description}</p>
          </div>
        ))}
      </div>

      <Link
        href={localizedHref(locale, "features")}
        className="mt-10 text-sm font-semibold text-blue-600 hover:underline dark:text-blue-400"
      >
        {t.seeAllFeatures}
      </Link>
    </main>
  );
}
