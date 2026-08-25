import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FeaturesContent from "@/components/FeaturesContent";
import en from "@/content/en";
import { alternateLanguages } from "@/content/routes";

export const metadata: Metadata = {
  title: en.features.metaTitle,
  description: en.features.metaDescription,
  alternates: {
    languages: alternateLanguages("features"),
  },
};

export default function FeaturesPage() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale="en" currentRoute="features" dict={en} />
      <FeaturesContent locale="en" dict={en} />
      <Footer locale="en" dict={en} />
    </div>
  );
}
