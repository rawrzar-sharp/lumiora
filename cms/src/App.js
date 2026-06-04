import React, { useEffect, useState } from 'react';
import './App.css';
import {
  LayoutDashboard,
  Coffee,
  ShoppingCart,
  Boxes,
  Package,
  ClipboardList,
  AlertTriangle,
  TrendingUp,
  Settings,
  LogOut,
  Search,
  Bell,
} from 'lucide-react';

function App() {
  const [activeMenu, setActiveMenu] = useState('Dashboard');
  const [menuItems, setMenuItems] = useState([]);
  const [selectedMenu, setSelectedMenu] = useState(null);
  const [stockDraft, setStockDraft] = useState('');
  const [statusMessage, setStatusMessage] = useState('');
  const [loading, setLoading] = useState(true);

  const stats = [
    { label: 'Pesanan Masuk', value: '24', icon: <ShoppingCart size={20} />, color: 'blue' },
    { label: 'Menu Ready', value: '18', icon: <Coffee size={20} />, color: 'green' },
    { label: 'Stok Menipis', value: '5 item', icon: <AlertTriangle size={20} />, color: 'orange' },
    { label: 'Omzet Hari Ini', value: 'Rp 4.8M', icon: <TrendingUp size={20} />, color: 'purple' },
  ];

  const pendingOrders = [
    { id: 'ORD-1001', customer: 'Budi Santoso', item: '2x Latte + 1x Croissant', status: 'Diproses', time: '08:45' },
    { id: 'ORD-1002', customer: 'Siti Aminah', item: '1x Americano', status: 'Siap Antar', time: '09:10' },
    { id: 'ORD-1003', customer: 'Rina Melati', item: '3x Matcha Latte', status: 'Menunggu Bahan', time: '09:25' },
  ];

  const lowStock = [
    { ingredient: 'Susu Fresh', stock: '8 liter', status: 'Hampir habis' },
    { ingredient: 'Matcha Powder', stock: '1.2 kg', status: 'Perlu restock' },
    { ingredient: 'Es Batu', stock: '18 kg', status: 'Aman' },
  ];

  useEffect(() => {
    const loadMenu = async () => {
      try {
        setLoading(true);
        const res = await fetch('http://43.133.144.212:1234/api/menu');
        const data = await res.json();
        const items = Array.isArray(data?.data) ? data.data : Array.isArray(data?.menu) ? data.menu : [];
        setMenuItems(items);
        if (items[0]) {
          setSelectedMenu(items[0]);
          setStockDraft(String(items[0].stock ?? 0));
        }
      } catch (error) {
        console.error('Failed to load menu', error);
        setStatusMessage('Gagal mengambil data menu dari backend.');
      } finally {
        setLoading(false);
      }
    };

    loadMenu();
  }, []);

  const handleSelectMenu = (item) => {
    setSelectedMenu(item);
    setStockDraft(String(item.stock ?? 0));
    setStatusMessage(`Menu ${item.item_name || item.name} dipilih.`);
  };

  const handleStockChange = async (mode) => {
    if (!selectedMenu) return;

    try {
      const payload = mode === 'set' ? { stock: Number(stockDraft) } : { delta: mode === 'plus' ? 1 : -1 };
      const res = await fetch(`http://43.133.144.212:1234/api/menu/${selectedMenu.id}/stock`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Update stock gagal');

      setMenuItems((prev) => prev.map((item) => item.id === selectedMenu.id ? { ...item, stock: data.stock } : item));
      setSelectedMenu((prev) => prev ? { ...prev, stock: data.stock } : prev);
      setStatusMessage(`Stok ${selectedMenu.item_name || selectedMenu.name} disimpan: ${data.stock}`);
    } catch (error) {
      console.error(error);
      setStatusMessage(error.message || 'Gagal menyimpan stok ke database.');
    }
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <Coffee size={28} color="#60a5fa" />
          <span>Lumiora Staff</span>
        </div>

        <ul className="sidebar-menu">
          {['Dashboard', 'Menu & Stok', 'Pesanan', 'Ingredients', 'Laporan', 'Pengaturan'].map((item) => (
            <li
              key={item}
              className={activeMenu === item ? 'active' : ''}
              onClick={() => setActiveMenu(item)}
            >
              {item === 'Dashboard' && <LayoutDashboard size={18} />}
              {item === 'Menu & Stok' && <Boxes size={18} />}
              {item === 'Pesanan' && <ShoppingCart size={18} />}
              {item === 'Ingredients' && <Package size={18} />}
              {item === 'Laporan' && <ClipboardList size={18} />}
              {item === 'Pengaturan' && <Settings size={18} />}
              <span>{item}</span>
            </li>
          ))}
        </ul>

        <div className="sidebar-logout">
          <button className="logout-btn" type="button">
            <LogOut size={18} />
            <span>Keluar</span>
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="header">
          <label className="search-bar">
            <Search size={18} color="#9ca3af" />
            <input type="text" placeholder="Cari pesanan, menu, bahan, atau laporan..." />
          </label>

          <div className="header-right">
            <Bell size={18} color="#6b7280" className="icon-button" />
            <div className="profile">
              <img src="https://ui-avatars.com/api/?name=Staff+Lumiora&background=2563eb&color=fff" alt="Staff" />
              <span>Staff Prep Café</span>
            </div>
          </div>
        </header>

        <section className="content-wrapper">
          <div className="page-title-row">
            <div>
              <p className="eyebrow">Dashboard Staff</p>
              <h2>Persiapan Café & Stock Opname</h2>
              <p className="subtle-text">Pantau pesanan masuk, bahan, stok menu, dan laporan sisa stock dari satu layar.</p>
            </div>
            <button className="primary-btn" type="button">+ Update Stok</button>
          </div>

          <div className="stat-grid">
            {stats.map((item, index) => (
              <article className="stat-card" key={index}>
                <div className={`stat-icon ${item.color}`}>{item.icon}</div>
                <div className="stat-info">
                  <h4>{item.label}</h4>
                  <h2>{item.value}</h2>
                </div>
              </article>
            ))}
          </div>

          <div className="grid-2">
            <article className="panel-card">
              <div className="panel-head">
                <div>
                  <p className="eyebrow">Pesanan Masuk</p>
                  <h3>Notifikasi & Status</h3>
                </div>
                <button className="ghost-btn" type="button">Lihat semua</button>
              </div>
              <ul className="order-list">
                {pendingOrders.map((order) => (
                  <li key={order.id} className="order-item">
                    <div>
                      <strong>{order.id}</strong>
                      <p>{order.customer}</p>
                      <span>{order.item}</span>
                    </div>
                    <div className="order-meta">
                      <span className={`badge ${order.status.toLowerCase().replace(/\s+/g, '-')}`}>{order.status}</span>
                      <small>{order.time}</small>
                    </div>
                  </li>
                ))}
              </ul>
            </article>

            <article className="panel-card">
              <div className="panel-head">
                <div>
                  <p className="eyebrow">Ingredients</p>
                  <h3>Low Ingredients Alert</h3>
                </div>
                <button className="ghost-btn" type="button">Restock</button>
              </div>
              <ul className="stack-list">
                {lowStock.map((item) => (
                  <li key={item.ingredient} className="stack-item">
                    <div>
                      <strong>{item.ingredient}</strong>
                      <p>{item.status}</p>
                    </div>
                    <span className="pill">{item.stock}</span>
                  </li>
                ))}
              </ul>
            </article>
          </div>

          <div className="grid-2">
            <article className="panel-card">
              <div className="panel-head">
                <div>
                  <p className="eyebrow">Menu / Produk</p>
                  <h3>Update Stok Menu</h3>
                </div>
                <button className="ghost-btn" type="button">Kelola menu</button>
              </div>
              <div className="menu-list">
                {loading ? (
                  <p className="subtle-text">Memuat data menu dari backend...</p>
                ) : menuItems.length === 0 ? (
                  <p className="subtle-text">Tidak ada menu yang bisa ditampilkan dari API.</p>
                ) : (
                  menuItems.map((item) => (
                    <button
                      type="button"
                      key={item.id}
                      className={`menu-row ${selectedMenu?.id === item.id ? 'selected' : ''}`}
                      onClick={() => handleSelectMenu(item)}
                    >
                      <strong>{item.item_name || item.name}</strong>
                      <span>{item.category_name || item.category_id}</span>
                      <small>Stok: {item.stock ?? 0}</small>
                    </button>
                  ))
                )}
              </div>

              {selectedMenu && (
                <div className="stock-editor">
                  <p className="subtle-text">Menu yang dipilih: <strong>{selectedMenu.item_name || selectedMenu.name}</strong></p>
                  <label className="stock-input-wrap">
                    <span>Stok baru</span>
                    <input
                      type="number"
                      min="0"
                      value={stockDraft}
                      onChange={(e) => setStockDraft(e.target.value)}
                    />
                  </label>
                  <div className="stock-actions">
                    <button type="button" className="ghost-btn" onClick={() => handleStockChange('minus')}>-1</button>
                    <button type="button" className="ghost-btn" onClick={() => handleStockChange('plus')}>+1</button>
                    <button type="button" className="primary-btn" onClick={() => handleStockChange('set')}>Simpan ke DB</button>
                  </div>
                  {statusMessage && <p className="status-note">{statusMessage}</p>}
                </div>
              )}
            </article>

            <article className="panel-card">
              <div className="panel-head">
                <div>
                  <p className="eyebrow">Opsional</p>
                  <h3>Recipe & COGS</h3>
                </div>
                <button className="ghost-btn" type="button">Lihat recipe</button>
              </div>
              <ul className="notes-list">
                <li>Ingredients List: daftar bahan utama untuk tiap menu.</li>
                <li>Recipe: kombinasi bahan dan takaran untuk produksi.</li>
                <li>COGS: dihitung dari recipe agar biaya produksi lebih akurat.</li>
                <li>Laporan sisa stock dan penjualan bisa ditambahkan ke panel ini.</li>
              </ul>
            </article>
          </div>

          <article className="panel-card wide-card">
            <div className="panel-head">
              <div>
                <p className="eyebrow">Ringkasan</p>
                <h3>Operasional Hari Ini</h3>
              </div>
              <button className="ghost-btn" type="button">Export laporan</button>
            </div>
            <div className="summary-grid">
              <div className="summary-box"><strong>12</strong><span>Pesanan selesai</span></div>
              <div className="summary-box"><strong>4</strong><span>Menu perlu stok ulang</span></div>
              <div className="summary-box"><strong>92%</strong><span>Utilisasi bahan</span></div>
              <div className="summary-box"><strong>Rp 4.8M</strong><span>Penjualan hari ini</span></div>
            </div>
          </article>
        </section>
      </main>
    </div>
  );
}

export default App;