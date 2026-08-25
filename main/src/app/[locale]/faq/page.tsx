import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FaqContent from "@/components/FaqContent";
import { getDictionary } from "@/content";
import { alternateLanguages } from "@/content/routes";
import type { Locale } from "@/content/types";

export async function generateMetadata({ params }: PageProps<"/[locale]/faq">): Promise<Metadata> {
  const { locale } = await params;
  const dict = getDictionary(locale as Locale);
  return {
    title: dict.faq.metaTitle,
    description: dict.faq.metaDescription,
    alternates: {
      languages: alternateLanguages("faq"),
    },
  };
}

export default async function LocaleFaqPage({ params }: PageProps<"/[locale]/faq">) {
  const { locale } = (await params) as { locale: Locale };
  const dict = getDictionary(locale);

  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale={locale} currentRoute="faq" dict={dict} />
      <FaqContent dict={dict} />
      <Footer locale={locale} dict={dict} />
    </div>
  );
}
