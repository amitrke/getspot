import { locales, type Locale, type RouteKey } from "./types";

const ROUTE_PATHS: Record<RouteKey, string> = {
  home: "",
  features: "/features",
  faq: "/faq",
  privacy: "/privacy",
};

const SITE_URL = "https://www.getspot.org";

export function localizedHref(locale: Locale, route: RouteKey): string {
  const suffix = ROUTE_PATHS[route];
  if (locale === "en") {
    return suffix === "" ? "/" : suffix;
  }
  return `/${locale}${suffix}`;
}

export function alternateLanguages(route: RouteKey): Record<string, string> {
  const languages: Record<string, string> = {};
  for (const locale of locales) {
    languages[locale] = `${SITE_URL}${localizedHref(locale, route)}`;
  }
  languages["x-default"] = `${SITE_URL}${localizedHref("en", route)}`;
  return languages;
}
