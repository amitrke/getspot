import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import PrivacyEs from "@/components/privacy/PrivacyEs";
import PrivacyDe from "@/components/privacy/PrivacyDe";
import PrivacyFr from "@/components/privacy/PrivacyFr";
import { getDictionary } from "@/content";
import { alternateLanguages } from "@/content/routes";
import type { Locale } from "@/content/types";

export async function generateMetadata({ params }: PageProps<"/[locale]/privacy">): Promise<Metadata> {
  const { locale } = await params;
  const dict = getDictionary(locale as Locale);
  return {
    title: dict.privacy.metaTitle,
    description: dict.privacy.metaDescription,
    alternates: {
      languages: alternateLanguages("privacy"),
    },
  };
}

export default async function LocalePrivacyPage({ params }: PageProps<"/[locale]/privacy">) {
  const { locale } = (await params) as { locale: Locale };
  const dict = getDictionary(locale);

  let PrivacyBody: () => React.JSX.Element;
  switch (locale) {
    case "es":
      PrivacyBody = PrivacyEs;
      break;
    case "de":
      PrivacyBody = PrivacyDe;
      break;
    case "fr":
      PrivacyBody = PrivacyFr;
      break;
    default:
      notFound();
  }

  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale={locale} currentRoute="privacy" dict={dict} />

      <main className="mx-auto w-full max-w-2xl flex-1 px-5 py-16 sm:py-24">
        <PrivacyBody />
      </main>

      <Footer locale={locale} dict={dict} />
    </div>
  );
}
