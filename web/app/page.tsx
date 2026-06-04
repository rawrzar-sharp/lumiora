"use client";
import { useState, useEffect, useRef } from "react";
import Particles from "./components/Particles";


const getRandomPrice = (min: number, max: number) => {
  const step = 1000;
  const v = Math.floor((Math.random() * (max - min + 1) + min) / step) * step;
  return v;
};

const menuItems = [
  {
    category: "Signature Drinks",
    items: [
      { name: "Latte", price: getRandomPrice(25000, 45000), desc: "Velvety steamed milk over a double espresso, silky microfoam on top.", tag: null, emoji: "☕" },
      { name: "Caramel Macchiato", price: getRandomPrice(30000, 52000), desc: "Layers of steamed milk, espresso and house caramel drizzle.", tag: "bestseller", emoji: "🍮" },
      { name: "Espresso", price: getRandomPrice(15000, 28000), desc: "Single or double shot — rich, concentrated and bold.", tag: null, emoji: "⚡" },
      { name: "Cappuccino", price: getRandomPrice(28000, 46000), desc: "Equal parts espresso, steamed milk and airy foam — timeless.", tag: null, emoji: "☁️" },
      { name: "Americano", price: getRandomPrice(20000, 38000), desc: "Hot water pulled over espresso for a clean, long cup.", tag: null, emoji: "🌊" },
      { name: "Affogato", price: getRandomPrice(42000, 65000), desc: "House vanilla gelato with a hot espresso shot poured over.", tag: "dessert", emoji: "🍨" },
      { name: "Flat White", price: getRandomPrice(27000, 48000), desc: "Ristretto shots with thin, silky milk — smooth texture.", tag: null, emoji: "🎯" },
      { name: "Long Black", price: getRandomPrice(22000, 40000), desc: "Hot water then espresso — preserves crema and clarity.", tag: null, emoji: "🌑" },
    ],
  },
  {
    category: "Bites",
    items: [
      { name: "Croissant Bandeng", price: 42000, desc: "Buttery croissant, smoked milkfish pâté, pickled shallots", tag: "chef's pick", emoji: "🥐" },
      { name: "Ube Toast", price: 38000, desc: "Thick-cut brioche, whipped ube butter, coconut jam", tag: "bestseller", emoji: "🍞" },
      { name: "Klepon Cake", price: 35000, desc: "Pandan sponge, palm sugar filling, desiccated coconut", tag: null, emoji: "🍰" },
    ],
  },
];




const tagColors: Record<string, string> = {
  bestseller: "bg-amber-100 text-amber-700",
  new: "bg-orange-100 text-orange-600",
  "fan fave": "bg-rose-100 text-rose-600",
  "chef's pick": "bg-emerald-100 text-emerald-700",
};



export default function Home() {
  const [activeMenu, setActiveMenu] = useState(0);
  const [cart, setCart] = useState<{ name: string; price: number; qty: number }[]>([]);
  const [cartOpen, setCartOpen] = useState(false);
  const [toastMsg, setToastMsg] = useState("");
  const [heroVisible, setHeroVisible] = useState(false);
  const [reserveOpen, setReserveOpen] = useState(false);
  const [reserveForm, setReserveForm] = useState({ name: "", date: "", time: "", guests: "2" });
  const [reserveSubmitted, setReserveSubmitted] = useState(false);
  const [activeSection, setActiveSection] = useState("home");
  const menuRef = useRef<HTMLDivElement>(null);
  const aboutRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setTimeout(() => setHeroVisible(true), 100); }, []);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(""), 2500);
  };

  const addToCart = (name: string, price: number) => {
    setCart((prev) => {
      const existing = prev.find((i) => i.name === name);
      if (existing) return prev.map((i) => i.name === name ? { ...i, qty: i.qty + 1 } : i);
      return [...prev, { name, price, qty: 1 }];
    });
    showToast(`Added ${name} to order ✓`);
  };

  const removeFromCart = (name: string) => setCart((prev) => prev.filter((i) => i.name !== name));
  const cartTotal = cart.reduce((s, i) => s + i.price * i.qty, 0);
  const cartCount = cart.reduce((s, i) => s + i.qty, 0);
  const scrollTo = (ref: React.RefObject<HTMLDivElement | null>, section: string) => {
    ref.current?.scrollIntoView({ behavior: "smooth" });
    setActiveSection(section);
  };

  return (
    <>
      <Particles />
      <div className="min-h-screen font-sans text-[#1a1a1a] relative z-10">




      {/* Toast */}
      <div className={`fixed top-6 left-1/2 -translate-x-1/2 z-50 transition-all duration-500 ${toastMsg ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-4 pointer-events-none"}`}>
        <div className="bg-[#1a1a1a] text-white px-5 py-3 rounded-full text-sm shadow-xl">{toastMsg}</div>
      </div>




      {/* Nav */}
      <nav className="fixed top-0 left-0 right-0 z-40 bg-[#faf7f2]/90 backdrop-blur-md border-b border-[#e8ddd0]">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <button onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })} className="flex items-center gap-2">
            <span className="text-2xl">🔥</span>
            <span className="text-xl font-bold tracking-tight">Flame <span className="text-[#c2703e]">&</span> Foam</span>
          </button>
          <div className="hidden sm:flex items-center gap-6 text-sm font-medium text-[#666]">
            <button onClick={() => scrollTo(menuRef, "menu")} className={`hover:text-[#c2703e] transition-colors ${activeSection === "menu" ? "text-[#c2703e]" : ""}`}>Menu</button>
            <button onClick={() => scrollTo(aboutRef, "about")} className={`hover:text-[#c2703e] transition-colors ${activeSection === "about" ? "text-[#c2703e]" : ""}`}>About</button>
            <button onClick={() => setReserveOpen(true)} className="bg-[#c2703e] text-white px-4 py-2 rounded-full hover:bg-[#a85c30] transition-colors">Reserve a Table</button>
          </div>
          <button onClick={() => setCartOpen(true)} className="relative flex items-center gap-2 bg-[#1a1a1a] text-white px-4 py-2 rounded-full text-sm hover:bg-[#333] transition-colors">
            <span>🛒</span><span>Order</span>
            {cartCount > 0 && <span className="absolute -top-2 -right-2 bg-[#c2703e] text-white text-xs w-5 h-5 rounded-full flex items-center justify-center font-bold">{cartCount}</span>}
          </button>
        </div>
      </nav>




      {/* Hero */}
      <section className="pt-16 min-h-screen flex flex-col items-center justify-center relative overflow-hidden px-6">
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="absolute rounded-full opacity-20 blur-3xl animate-pulse"
              style={{ background: i % 2 === 0 ? "#c2703e" : "#f5a623", width: `${200 + i * 80}px`, height: `${200 + i * 80}px`, top: `${10 + i * 12}%`, left: `${5 + i * 14}%`, animationDelay: `${i * 0.8}s`, animationDuration: `${4 + i}s` }} />
          ))}
        </div>
        <div className={`relative z-10 text-center max-w-2xl transition-all duration-1000 ${heroVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"}`}>
          <div className="inline-flex items-center gap-2 bg-white/80 border border-[#e8ddd0] text-[#c2703e] text-xs font-medium px-4 py-2 rounded-full mb-6 shadow-sm">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Now Open · Kemang, Jakarta Selatan
          </div>
          <h1 className="text-5xl sm:text-7xl font-bold tracking-tight leading-none mb-4">
            Flame <span className="text-[#c2703e]">&</span> Foam
          </h1>
          <p className="text-[#888] text-lg sm:text-xl leading-relaxed mb-2">A Jakarta craft café where bold fire meets</p>
          <p className="text-[#888] text-lg sm:text-xl leading-relaxed mb-8">velvety foam — one sip at a time.</p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <button onClick={() => scrollTo(menuRef, "menu")} className="bg-[#c2703e] text-white px-8 py-4 rounded-full font-medium hover:bg-[#a85c30] transition-all hover:scale-105 shadow-lg">Explore Menu</button>
            <button onClick={() => setReserveOpen(true)} className="bg-white border border-[#e8ddd0] px-8 py-4 rounded-full font-medium hover:bg-[#f5f0ea] transition-all hover:scale-105 shadow-sm">Reserve a Table</button>
          </div>
        </div>
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce">
          <div className="w-6 h-10 rounded-full border-2 border-[#ccc] flex items-start justify-center pt-2"><div className="w-1 h-2 bg-[#ccc] rounded-full"></div></div>
        </div>
      </section>




      {/* Ticker */}
      <section className="bg-[#1a1a1a] text-white py-4 overflow-hidden">
        <div className="flex whitespace-nowrap" style={{ animation: "slide 20s linear infinite" }}>
          {[...Array(3)].map((_, i) => (
            <span key={i} className="flex text-sm text-[#aaa]">
              {["🔥 Specialty Coffee", "🌿 Pandan Series", "🧊 Nitro Cold Brew", "🎵 Live Jazz Fridays", "☕ Single Origin Roasts", "🍰 Local Pastries"].map((t) => <span key={t} className="mx-8">{t}</span>)}
            </span>
          ))}
        </div>
      </section>




      {/* Menu */}
      <section ref={menuRef} className="max-w-5xl mx-auto px-6 py-20">
        <div className="text-center mb-12">
          <p className="text-[#c2703e] text-sm font-medium uppercase tracking-widest mb-2">What We Serve</p>
          <h2 className="text-4xl font-bold">Our Menu</h2>
          <p className="text-[#888] mt-3 max-w-md mx-auto">Local ingredients, global techniques. Click any item to add it to your order.</p>
        </div>
        <div className="flex gap-2 justify-center mb-10 bg-white rounded-full p-1.5 w-fit mx-auto border border-[#e8ddd0] shadow-sm">
          {menuItems.map((cat, i) => (
            <button key={i} onClick={() => setActiveMenu(i)} className={`px-6 py-2.5 rounded-full text-sm font-medium transition-all ${activeMenu === i ? "bg-[#c2703e] text-white shadow-md" : "text-[#666] hover:text-[#1a1a1a]"}`}>{cat.category}</button>
          ))}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {menuItems[activeMenu].items.map((item) => (
            <div key={item.name} className="bg-white rounded-2xl p-5 border border-[#e8ddd0] hover:border-[#c2703e] hover:shadow-lg transition-all duration-300 group cursor-pointer" onClick={() => addToCart(item.name, item.price)}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-2xl">{item.emoji}</span>
                    <h3 className="font-bold text-base">{item.name}</h3>
                    {item.tag && <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${tagColors[item.tag]}`}>{item.tag}</span>}
                  </div>
                  <p className="text-[#888] text-sm leading-relaxed">{item.desc}</p>
                </div>
                <div className="text-right flex-shrink-0">
                  <p className="font-bold">Rp {item.price.toLocaleString("id-ID")}</p>
                  <button className="mt-2 bg-[#f5f0ea] group-hover:bg-[#c2703e] group-hover:text-white text-[#c2703e] w-8 h-8 rounded-full flex items-center justify-center text-lg font-bold transition-all">+</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>




      {/* About */}
      <section ref={aboutRef} className="bg-[#1a1a1a] text-white py-20 px-6">
        <div className="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-2 gap-12 items-center">
          <div>
            <p className="text-[#c2703e] text-sm font-medium uppercase tracking-widest mb-3">Our Story</p>
            <h2 className="text-4xl font-bold mb-5 leading-tight">Born in Kemang,<br />Brewed with Soul</h2>
            <p className="text-[#aaa] leading-relaxed mb-4">Flame & Foam started as a small pop-up at Pasar Santa in 2021. We fell in love with the tension between bold espresso and silky microfoam — and Jakarta's energy became our secret ingredient.</p>
            <p className="text-[#aaa] leading-relaxed mb-6">Every drink fuses local heroes like pandan, palm sugar, and coconut with world-class roasting techniques. This is Jakarta in a cup.</p>
            <div className="flex gap-8">
              {[["4.9★", "Google Reviews"], ["50+", "Menu Items"], ["2021", "Est. Kemang"]].map(([val, label]) => (
                <div key={label}><p className="text-2xl font-bold">{val}</p><p className="text-[#666] text-sm">{label}</p></div>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {["☕", "🌿", "🔥", "🧊"].map((emoji, i) => (
              <div key={i} className={`rounded-2xl p-8 flex items-center justify-center text-5xl hover:scale-105 transition-transform cursor-default ${i % 2 === 0 ? "bg-[#2a2a2a]" : "bg-[#c2703e]/20"}`}>{emoji}</div>
            ))}
          </div>
        </div>
      </section>




      {/* Hours & Location */}
      <section className="max-w-5xl mx-auto px-6 py-20 grid grid-cols-1 sm:grid-cols-2 gap-10">
        <div className="bg-white rounded-2xl p-8 border border-[#e8ddd0]">
          <h3 className="text-xl font-bold mb-5">⏰ Opening Hours</h3>
          {[{ day: "Mon – Fri", time: "07:00 – 22:00" }, { day: "Sat – Sun", time: "08:00 – 23:00" }].map((h) => (
            <div key={h.day} className="flex justify-between py-3 border-b border-[#f0ebe3] last:border-0">
              <span className="text-[#666]">{h.day}</span><span className="font-medium">{h.time}</span>
            </div>
          ))}
          <div className="mt-4 p-3 bg-amber-50 rounded-xl text-sm text-amber-700 flex gap-2"><span>🎵</span><span>Live jazz every Friday evening from 19:00</span></div>
        </div>
        <div className="bg-white rounded-2xl p-8 border border-[#e8ddd0]">
          <h3 className="text-xl font-bold mb-5">📍 Find Us</h3>
          <p className="text-[#666] mb-1">Jl. Kemang Raya No. 47</p>
          <p className="text-[#666] mb-4">Kemang, Jakarta Selatan 12730</p>
          <a href="https://maps.google.com/?q=Kemang+Jakarta+Selatan" target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 bg-[#1a1a1a] text-white px-5 py-3 rounded-full text-sm font-medium hover:bg-[#333] transition-colors">Open in Maps →</a>
          <div className="mt-4 p-3 bg-emerald-50 rounded-xl text-sm text-emerald-700 flex gap-2"><span>✅</span><span>Free parking available on weekdays</span></div>
        </div>
      </section>





      {/* Footer */}
      <footer className="bg-[#c2703e] text-white py-12">
        <div className="max-w-7xl mx-auto px-6 grid grid-cols-1 sm:grid-cols-3 gap-8 items-center">
          <div className="hidden sm:block">
            <div className="w-full h-48 rounded-l-[80px] bg-cover bg-center overflow-hidden" style={{ backgroundImage: "linear-gradient(rgba(194,124,61,0.65), rgba(194,124,61,0.65)), url('/footer-photo.jpg')" }} aria-hidden="true" />
          </div>

          <div className="text-center sm:text-left">
            <div className="flex items-center justify-center sm:justify-start gap-3 mb-4">
              <span className="text-2xl">🔥</span>
              <span className="text-white font-bold text-lg">Flame & Foam</span>
            </div>
            <nav aria-label="Footer navigation" className="flex flex-col gap-3">
              <a href="#about" className="font-medium hover:underline">About Us</a>
              <a href="#menu" className="font-medium hover:underline">Our Products</a>
              <a href="#contact" className="font-medium hover:underline">Contact Us</a>
            </nav>
          </div>

          <div className="text-center sm:text-right space-y-4">
            <p className="text-xl font-bold">Get In Touch With Us!</p>
            <div className="flex justify-center sm:justify-end gap-4">
              <a href="#" aria-label="Facebook" className="p-2 rounded-lg bg-white/10 hover:bg-white/20">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M22 12C22 6.48 17.52 2 12 2S2 6.48 2 12c0 4.84 3.44 8.84 7.94 9.8v-6.93H7.9v-2.87h2.04V9.41c0-2.02 1.2-3.13 3.03-3.13.88 0 1.8.16 1.8.16v1.98h-1.02c-1.01 0-1.32.62-1.32 1.25v1.5h2.25l-.36 2.87h-1.89V21.8C18.56 20.84 22 16.84 22 12z" fill="white"/></svg>
              </a>
              <a href="#" aria-label="Instagram" className="p-2 rounded-lg bg-white/10 hover:bg-white/20">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M7 2h10a5 5 0 0 1 5 5v10a5 5 0 0 1-5 5H7a5 5 0 0 1-5-5V7a5 5 0 0 1 5-5zm5 6.5A4.5 4.5 0 1 0 16.5 13 4.5 4.5 0 0 0 12 8.5zm5.5-3a1 1 0 1 1 0 2 1 1 0 0 1 0-2z" fill="white"/></svg>
              </a>
              <a href="#" aria-label="YouTube" className="p-2 rounded-lg bg-white/10 hover:bg-white/20">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10 15l5.2-3L10 9v6zm11-3c0-1.1-.9-2-2-2h-1.2l-.28-.02C16.6 9.8 13.6 9 12 9s-4.6.8-5.52.98L6.2 10H5c-1.1 0-2 .9-2 2v1c0 1.1.9 2 2 2h1.2l.28.02C7.4 15.2 10.4 16 12 16s4.6-.8 5.52-.98L17.8 15H19c1.1 0 2-.9 2-2v-1z" fill="white"/></svg>
              </a>
            </div>

            <div className="mt-2">
              <div className="flex items-center gap-2 mt-2 justify-center sm:justify-end">
                <span className="inline-block w-6 h-4 bg-white rounded-sm shadow-inner" aria-hidden="true" />
                <span className="text-sm">Indonesia</span>
              </div>

              <p className="mt-3 uppercase text-sm font-medium">Language</p>
              <div className="flex items-center gap-3 justify-center sm:justify-end mt-2">
                <button className="font-bold">EN</button>
                <span className="text-white/60">|</span>
                <button className="text-white/80">IN</button>
              </div>
            </div>
          </div>
        </div>

        <div className="border-t border-white/10 mt-8 pt-6 text-center text-sm text-white/80">
          © {new Date().getFullYear()} Flame & Foam · Kemang, Jakarta · All rights reserved · 📞 +62 21 7654 3210 · ✉️ hello@flameandfoam.id
        </div>
      </footer>





      {/* Cart Drawer */}
      {cartOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/40" onClick={() => setCartOpen(false)} />
          <div className="relative bg-white w-full max-w-sm h-full flex flex-col shadow-2xl">
            <div className="flex items-center justify-between p-6 border-b border-[#e8ddd0]">
              <h2 className="text-lg font-bold">Your Order ({cartCount})</h2>
              <button onClick={() => setCartOpen(false)} className="text-[#888] hover:text-black text-xl">✕</button>
            </div>
            <div className="flex-1 overflow-y-auto p-6">
              {cart.length === 0 ? (
                <div className="text-center text-[#aaa] mt-12"><div className="text-5xl mb-3">🛒</div><p>Your order is empty</p><button onClick={() => setCartOpen(false)} className="mt-4 text-[#c2703e] text-sm underline">Browse menu</button></div>
              ) : cart.map((item) => (
                <div key={item.name} className="flex items-center justify-between py-3 border-b border-[#f0ebe3]">
                  <div><p className="font-medium text-sm">{item.name}</p><p className="text-[#888] text-xs">Rp {(item.price * item.qty).toLocaleString("id-ID")}</p></div>
                  <div className="flex items-center gap-2"><span className="text-sm font-medium">×{item.qty}</span><button onClick={() => removeFromCart(item.name)} className="text-[#ccc] hover:text-red-400 text-lg">×</button></div>
                </div>
              ))}
            </div>
            {cart.length > 0 && (
              <div className="p-6 border-t border-[#e8ddd0]">
                <div className="flex justify-between mb-4 font-bold text-lg"><span>Total</span><span>Rp {cartTotal.toLocaleString("id-ID")}</span></div>
                <button onClick={() => { showToast("Order placed! See you soon ☕"); setCart([]); setCartOpen(false); }} className="w-full bg-[#c2703e] text-white py-4 rounded-full font-medium hover:bg-[#a85c30] transition-colors">Place Order</button>
                <p className="text-center text-xs text-[#aaa] mt-3">Pay at the counter or via GoPay / OVO</p>
              </div>
            )}
          </div>
        </div>
      )}

      <style>{`
        @keyframes slide { from { transform: translateX(0); } to { transform: translateX(-33.33%); } }
      `}</style>
      </div>
    </>
  );
}