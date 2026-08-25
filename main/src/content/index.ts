import type { Dictionary, Locale } from "./types";
import en from "./en";
import es from "./es";
import de from "./de";
import fr from "./fr";

const dictionaries: Record<Locale, Dictionary> = { en, es, de, fr };

export function getDictionary(locale: Locale): Dictionary {
  return dictionaries[locale];
}
