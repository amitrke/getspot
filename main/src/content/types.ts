export type Locale = "en" | "es" | "de" | "fr";

export const locales: Locale[] = ["en", "es", "de", "fr"];

export type RouteKey = "home" | "features" | "faq" | "privacy";

interface FeatureItem {
  title: string;
  description: string;
}

interface FaqItem {
  question: string;
  answer: string;
}

export interface Dictionary {
  header: {
    brand: string;
    navFeatures: string;
    navFaq: string;
    openApp: string;
  };
  footer: {
    copyright: string;
    appLink: string;
    privacyLink: string;
  };
  home: {
    metaTitle: string;
    metaDescription: string;
    title: string;
    subtitle: string;
    ctaOpenApp: string;
    ctaIosApp: string;
    ctaAndroidApp: string;
    features: FeatureItem[];
    seeAllFeatures: string;
  };
  features: {
    metaTitle: string;
    metaDescription: string;
    title: string;
    subtitle: string;
    forOrganizers: string;
    forPlayers: string;
    organizerFeatures: FeatureItem[];
    playerFeatures: FeatureItem[];
    ctaOpenApp: string;
    ctaReadFaq: string;
  };
  faq: {
    metaTitle: string;
    metaDescription: string;
    title: string;
    introBeforeEmail: string;
    introAfterEmail: string;
    items: FaqItem[];
    ctaOpenApp: string;
  };
  privacy: {
    metaTitle: string;
    metaDescription: string;
  };
}
