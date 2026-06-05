import React, { useState, useEffect } from 'react';
import './App.css';
import OrdersPage from './pages/Orders';
import InventoryPage from './pages/Inventory';
import RecipesPage from './pages/Recipes';
import ReportsPage from './pages/Reports';
import { 
  LayoutDashboard, Coffee, ShoppingCart, Users, 
  PieChart, Settings, LogOut, Search, Bell, MoreVertical 
} from 'lucide-react';

// URL Backend (override with REACT_APP_API_URL in production/dev)
const API_URL = process.env.REACT_APP_API_URL || 'http://43.133.144.212:1234';

function App() {
  // --- STATE MANAGEMENT ---
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userRole, setUserRole] = useState(''); // 'admin' atau 'staff'
  const [apiToken, setApiToken] = useState(null);
  const [activeMenu, setActiveMenu] = useState('Pesanan');
  const [orders, setOrders] = useState([]);

  // --- FUNGSI LOGIN DUMMY ---
  const handleLogin = (e) => {
    e.preventDefault();
    const username = e.target.username.value;
    const password = e.target.password.value;

    // Logika sederhana: jika username 'admin', role admin. Jika 'staff', role staff.
    if (username === 'admin' && password === 'admin123') {
      setUserRole('admin');
      setIsLoggedIn(true);
      setActiveMenu('Dashboard');
      // get a dev token for admin (local test account)
      fetch(`${API_URL}/api/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'cms.tester@example.com', password: 'CmsPassword1' }) })
        .then(r => r.json()).then(d => { if (d.success && d.data && d.data.token) setApiToken(d.data.token); }).catch(()=>{});
    } else if (username === 'staff' && password === 'staff123') {
      setUserRole('staff');
      setIsLoggedIn(true);
      setActiveMenu('Pesanan'); // Staff langsung diarahkan ke Pesanan
      // get a dev token for staff (local test account)
      fetch(`${API_URL}/api/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'cms.tester2@example.com', password: 'CmsPassword2' }) })
        .then(r => r.json()).then(d => { if (d.success && d.data && d.data.token) setApiToken(d.data.token); }).catch(()=>{});
    } else {
      alert('Username atau password salah!');
    }
  };

  // --- FUNGSI MENGAMBIL DATA DARI API CLOUD ---
  useEffect(() => {
    if (isLoggedIn && (activeMenu === 'Dashboard' || activeMenu === 'Pesanan')) {
      // Mengambil data pesanan dari API Cloud kamu
      fetch(`${API_URL}/api/orders`)
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            setOrders(data.data); // Asumsi response: { success: true, data: [...] }
          }
        })
        .catch(err => console.log("Gagal mengambil data, pastikan API menyala:", err));
    }
  }, [isLoggedIn, activeMenu]);

  // --- RENDER HALAMAN LOGIN ---
  if (!isLoggedIn) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', backgroundColor: '#f3f4f6' }}>
        <form onSubmit={handleLogin} style={{ background: 'white', padding: '40px', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)', width: '350px' }}>
          <h2 style={{ textAlign: 'center', marginBottom: '20px', color: '#111827' }}>Lumiora Login</h2>
          <div style={{ marginBottom: '15px' }}>
            <label>Username (admin/staff)</label>
            <input type="text" name="username" style={{ width: '100%', padding: '10px', marginTop: '5px', borderRadius: '6px', border: '1px solid #ccc' }} required />
          </div>
          <div style={{ marginBottom: '20px' }}>
            <label>Password (admin123/staff123)</label>
            <input type="password" name="password" style={{ width: '100%', padding: '10px', marginTop: '5px', borderRadius: '6px', border: '1px solid #ccc' }} required />
          </div>
          <button type="submit" style={{ width: '100%', padding: '12px', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold' }}>
            Masuk
          </button>
        </form>
      </div>
    );
  }

  // --- MENENTUKAN MENU BERDASARKAN ROLE ---
  const menuItems = [
    { name: 'Dashboard', icon: <LayoutDashboard size={20} />, roles: ['admin'] }, // Hanya admin
    { name: 'Pesanan', icon: <ShoppingCart size={20} />, roles: ['admin', 'staff'] }, // Admin & Staff
    { name: 'Menu / Cek Stok', icon: <Coffee size={20} />, roles: ['staff'] }, // Admin & Staff
    { name: 'Manage', icon: <Coffee size={20} />, roles: ['admin'] },
    { name: 'Pelanggan', icon: <Users size={20} />, roles: ['admin'] },
    { name: 'Laporan', icon: <PieChart size={20} />, roles: ['admin'] },
    { name: 'Pengaturan', icon: <Settings size={20} />, roles: ['admin'] },
  ];

  // --- RENDER DASHBOARD ---
  return (
    <div className="dashboard-container">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="sidebar-logo">
          <Coffee size={28} color="#3b82f6" />
          <span>Lumiora</span>
        </div>
        
        <ul className="sidebar-menu">
          {menuItems.filter(item => item.roles.includes(userRole)).map((item) => (
            <li 
              key={item.name} 
              className={activeMenu === item.name ? 'active' : ''}
              onClick={() => setActiveMenu(item.name)}
            >
              {item.icon}
              <span>{item.name}</span>
            </li>
          ))}
        </ul>

        <div className="sidebar-logout">
          <li onClick={() => setIsLoggedIn(false)} style={{ display: 'flex', gap: '12px', cursor: 'pointer', color: '#ef4444' }}>
            <LogOut size={20} />
            <span>Keluar ({userRole})</span>
          </li>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <main className="main-content">
        <header className="header">
          <div className="search-bar">
            <Search size={18} color="#9ca3af" />
            <input type="text" placeholder="Cari pesanan, menu..." />
          </div>
          <div className="header-right">
            <Bell size={20} color="#6b7280" />
            <div className="profile">
              <span style={{ textTransform: 'capitalize' }}>{userRole} Lumiora</span>
            </div>
          </div>
        </header>

        <div className="content-wrapper">
          <h2 style={{ marginBottom: '20px' }}>{activeMenu}</h2>
          {activeMenu === 'Dashboard' && <div>Dashboard overview coming soon.</div>}
          {activeMenu === 'Pesanan' && <OrdersPage apiUrl={API_URL} token={apiToken} />}
          {activeMenu === 'Menu / Cek Stok' && <InventoryPage apiUrl={API_URL} token={apiToken} userRole={userRole} />}
          {activeMenu === 'Laporan' && <ReportsPage apiUrl={API_URL} token={apiToken} />}
          {['Manage','Pelanggan','Pengaturan'].includes(activeMenu) && <p>Halaman <b>{activeMenu}</b> sedang dalam tahap pengembangan.</p>}
        </div>
      </main>
    </div>
  );
}

export default App;