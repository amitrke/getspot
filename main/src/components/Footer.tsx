import Link from "next/link";

export default function Footer() {
  return (
    <footer className="mx-auto w-full max-w-3xl px-5 py-8 text-center text-sm text-zinc-500 dark:text-zinc-400">
      © 2026 GetSpot ·{" "}
      <a href="https://app.getspot.org" className="hover:underline">
        app.getspot.org
      </a>{" "}
      · <Link href="/privacy" className="hover:underline">Privacy</Link>
    </footer>
  );
}
