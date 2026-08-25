import Header from "@/components/Header";
import Footer from "@/components/Footer";
import HomeContent from "@/components/HomeContent";
import en from "@/content/en";

export default function Home() {
  return (
    <div className="flex flex-1 flex-col bg-white text-zinc-900 dark:bg-zinc-950 dark:text-zinc-50">
      <Header locale="en" currentRoute="home" dict={en} />
      <HomeContent locale="en" dict={en} />
      <Footer locale="en" dict={en} />
    </div>
  );
}
