import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import FaqContent from "@/components/FaqContent";
import en from "@/content/en";
import { alternateLanguages } from "@/content/routes";

export const metadata: Metadata = {
  title: en.faq.metaTitle,
  description: en.faq.metaDescription,
  alternates: {
    languages: alternateLanguages("faq"),
  },
};

export default function FaqPage() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale="en" currentRoute="faq" dict={en} />
      <FaqContent dict={en} />
      <Footer locale="en" dict={en} />
    </div>
  );
}
