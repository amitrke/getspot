export default function PrivacySection({
  number,
  title,
  children,
}: {
  number: number;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-10 border-t border-zinc-200 pt-10 first:mt-0 first:border-t-0 first:pt-0 dark:border-zinc-800">
      <h2 className="text-lg font-semibold">
        {number}. {title}
      </h2>
      <div className="mt-3 space-y-3 text-sm text-zinc-500 dark:text-zinc-400">{children}</div>
    </section>
  );
}
