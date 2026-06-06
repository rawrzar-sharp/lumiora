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

 // --- FUNGSI LOGIN ASLI (TERHUBUNG KE DATABASE) ---
  const handleLogin = async (e) => {
    e.preventDefault();
    const email = e.target.username.value; // Name di form masih 'username'
    const password = e.target.password.value;

    try {
      const response = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      
      const data = await response.json();

      if (data.success) {
        // Simpan token asli dari database
        setApiToken(data.data.token || data.token);
        setUserRole(data.data.role || 'admin');
        setIsLoggedIn(true);
        setActiveMenu('Pesanan'); // Langsung buka halaman pesanan
      } else {
        alert(data.message || 'Email atau password salah di Database!');
      }
    } catch (err) {
      alert('Gagal terhubung ke server Backend!');
    }
  };
  
  // --- FUNGSI MENGAMBIL DATA DARI API CLOUD/LOKAL ---
  useEffect(() => {
    if (isLoggedIn && (activeMenu === 'Dashboard' || activeMenu === 'Pesanan')) {
      // Tambahkan headers Authorization agar Backend mau memberikan data
      fetch(`${API_URL}/api/orders`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiToken}` // Ini kunci rahasianya!
        }
      })
        .then(res => res.json())
        .then(data => {
          if (data.success) {
            setOrders(data.data); 
          } else {
            console.log("Backend menolak memberikan data:", data.message);
          }
        })
        .catch(err => console.log("Gagal mengambil data, pastikan API menyala:", err));
    }
  }, [isLoggedIn, activeMenu, apiToken]);

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