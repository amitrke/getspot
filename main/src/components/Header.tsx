import Link from "next/link";
import type { Dictionary, Locale, RouteKey } from "@/content/types";
import { locales } from "@/content/types";
import { localizedHref } from "@/content/routes";

const LOCALE_LABELS: Record<Locale, string> = {
  en: "EN",
  es: "ES",
  de: "DE",
  fr: "FR",
};

export default function Header({
  locale,
  currentRoute,
  dict,
}: {
  locale: Locale;
  currentRoute: RouteKey;
  dict: Dictionary;
}) {
  const navLinks: { route: RouteKey; label: string }[] = [
    { route: "features", label: dict.header.navFeatures },
    { route: "faq", label: dict.header.navFaq },
  ];

  return (
    <header className="mx-auto flex w-full max-w-3xl items-center justify-between px-5 py-6">
      <Link href={localizedHref(locale, "home")} className="text-lg font-bold tracking-tight">
        {dict.header.brand}
      </Link>
      <nav className="flex items-center gap-6 text-sm">
        {navLinks.map((link) => (
          <Link
            key={link.route}
            href={localizedHref(locale, link.route)}
            className="text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
          >
            {link.label}
          </Link>
        ))}
        <a
          href="https://app.getspot.org"
          className="text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
        >
          {dict.header.openApp}
        </a>
        <div className="flex items-center gap-2 border-l border-zinc-200 pl-6 dark:border-zinc-800">
          {locales.map((loc) => (
            <Link
              key={loc}
              href={localizedHref(loc, currentRoute)}
              className={
                loc === locale
                  ? "font-semibold text-zinc-900 dark:text-zinc-50"
                  : "text-zinc-400 hover:text-zinc-900 dark:text-zinc-500 dark:hover:text-zinc-50"
              }
            >
              {LOCALE_LABELS[loc]}
            </Link>
          ))}
        </div>
      </nav>
    </header>
  );
}
