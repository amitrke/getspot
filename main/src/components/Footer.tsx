import Link from "next/link";
import type { Dictionary, Locale } from "@/content/types";
import { localizedHref } from "@/content/routes";

export default function Footer({ locale, dict }: { locale: Locale; dict: Dictionary }) {
  return (
    <footer className="mx-auto w-full max-w-3xl px-5 py-8 text-center text-sm text-zinc-500 dark:text-zinc-400">
      {dict.footer.copyright}{" "}
      <a href="https://app.getspot.org" className="hover:underline">
        {dict.footer.appLink}
      </a>{" "}
      · <Link href={localizedHref(locale, "privacy")} className="hover:underline">{dict.footer.privacyLink}</Link>
    </footer>
  );
}
