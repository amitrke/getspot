import Link from "next/link";

const navLinks = [
  { href: "/features", label: "Features" },
  { href: "/faq", label: "FAQ" },
];

export default function Header() {
  return (
    <header className="mx-auto flex w-full max-w-3xl items-center justify-between px-5 py-6">
      <Link href="/" className="text-lg font-bold tracking-tight">
        GetSpot
      </Link>
      <nav className="flex items-center gap-6 text-sm">
        {navLinks.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className="text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
          >
            {link.label}
          </Link>
        ))}
        <a
          href="https://app.getspot.org"
          className="text-zinc-500 hover:text-zinc-900 dark:text-zinc-400 dark:hover:text-zinc-50"
        >
          Open App →
        </a>
      </nav>
    </header>
  );
}
