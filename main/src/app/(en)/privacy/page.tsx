import type { Metadata } from "next";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import PrivacyEn from "@/components/privacy/PrivacyEn";
import en from "@/content/en";
import { alternateLanguages } from "@/content/routes";

export const metadata: Metadata = {
  title: en.privacy.metaTitle,
  description: en.privacy.metaDescription,
  alternates: {
    languages: alternateLanguages("privacy"),
  },
};

export default function PrivacyPage() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale="en" currentRoute="privacy" dict={en} />

      <main className="mx-auto w-full max-w-2xl flex-1 px-5 py-16 sm:py-24">
        <PrivacyEn />
      </main>

      <Footer locale="en" dict={en} />
    </div>
  );
}
