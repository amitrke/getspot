import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FeaturesContent from "@/components/FeaturesContent";
import { getDictionary } from "@/content";
import { alternateLanguages } from "@/content/routes";
import type { Locale } from "@/content/types";

export async function generateMetadata({ params }: PageProps<"/[locale]/features">): Promise<Metadata> {
  const { locale } = await params;
  const dict = getDictionary(locale as Locale);
  return {
    title: dict.features.metaTitle,
    description: dict.features.metaDescription,
    alternates: {
      languages: alternateLanguages("features"),
    },
  };
}

export default async function LocaleFeaturesPage({ params }: PageProps<"/[locale]/features">) {
  const { locale } = (await params) as { locale: Locale };
  const dict = getDictionary(locale);

  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale={locale} currentRoute="features" dict={dict} />
      <FeaturesContent locale={locale} dict={dict} />
      <Footer locale={locale} dict={dict} />
    </div>
  );
}
