import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Oculum — Download Android",
  description: "Scarica l'ultima versione Android di Oculum.",
};

export default function Home() {
  return (
    <main className="page">
      <section className="card">
        <p className="eyebrow">OCULUM</p>
        <h1>Download Android</h1>
        <p className="description">
          Versione per telefoni Android moderni (ARM64): Occhi dei Caduti,
          Reforge, riposi e condizioni aggiornate.
        </p>
        <a
          className="download"
          href="https://github.com/Mich369/Oculum/releases/download/oculum-android-20260826-0653/Oculum-Android-arm64-v8a.apk"
        >
          Scarica APK Android
        </a>
        <p className="hint">
          Se Android chiede il permesso, abilita l&apos;installazione da questa
          sorgente. L&apos;APK è firmato come aggiornamento di Oculum e funziona
          sui telefoni Android recenti.
        </p>
      </section>
    </main>
  );
}
