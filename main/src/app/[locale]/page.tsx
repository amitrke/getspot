import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import HomeContent from "@/components/HomeContent";
import { getDictionary } from "@/content";
import { alternateLanguages } from "@/content/routes";
import type { Locale } from "@/content/types";

export async function generateMetadata({ params }: PageProps<"/[locale]">): Promise<Metadata> {
  const { locale } = await params;
  const dict = getDictionary(locale as Locale);
  return {
    title: dict.home.metaTitle,
    description: dict.home.metaDescription,
    alternates: {
      languages: alternateLanguages("home"),
    },
  };
}

export default async function LocaleHome({ params }: PageProps<"/[locale]">) {
  const { locale } = (await params) as { locale: Locale };
  const dict = getDictionary(locale);

  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale={locale} currentRoute="home" dict={dict} />
      <HomeContent locale={locale} dict={dict} />
      <Footer locale={locale} dict={dict} />
    </div>
  );
}
