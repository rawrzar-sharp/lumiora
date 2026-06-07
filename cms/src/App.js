import React, { useState } from 'react';
import './App.css';
import OrdersPage from './pages/Orders';
import InventoryPage from './pages/Inventory';
import ReportsPage from './pages/Reports';
import DashboardPage from './pages/Dashboard';
import MenuManagePage from './pages/MenuManage';
import CustomersPage from './pages/Customers';
import SettingsPage from './pages/Settings';
import {
  LayoutDashboard, Coffee, ShoppingCart, Users,
  PieChart, Settings, LogOut, Search, Bell, ClipboardList,
} from 'lucide-react';

// Backend URL (override with REACT_APP_API_URL in production)
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:3000';

// Menu items per role — single source of truth, English everywhere.
const MENU_ITEMS = [
  { key: 'dashboard', label: 'Dashboard',   icon: LayoutDashboard, roles: ['admin'] },
  { key: 'orders',    label: 'Orders',      icon: ShoppingCart,    roles: ['admin', 'staff'] },
  { key: 'stock',     label: 'Menu / Stock', icon: Coffee,         roles: ['staff', 'admin'] },
  { key: 'manage',    label: 'Menu Manager', icon: ClipboardList,  roles: ['admin'] },
  { key: 'customers', label: 'Customers',   icon: Users,           roles: ['admin'] },
  { key: 'reports',   label: 'Reports',     icon: PieChart,        roles: ['admin'] },
  { key: 'settings',  label: 'Settings',    icon: Settings,        roles: ['admin'] },
];

function App() {
  // --- AUTH STATE ---
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [userRole, setUserRole] = useState('');
  const [userName, setUserName] = useState('');
  const [apiToken, setApiToken] = useState(null);
  const [activeMenu, setActiveMenu] = useState('orders');

  // --- AUTH FORM STATE ---
  const [authMode, setAuthMode] = useState('login');
  const [authBusy, setAuthBusy] = useState(false);
  const [authError, setAuthError] = useState('');

  // --- LOGIN — searches the DB via POST /api/auth/login ---
  const handleLogin = async (e) => {
    e.preventDefault();
    setAuthBusy(true);
    setAuthError('');
    const email = e.target.email.value.trim();
    const password = e.target.password.value;

    try {
      const response = await fetch(`${API_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();

      if (response.ok && data.success) {
        const payload = data.data || data;
        const role = payload.role || 'admin';
        if (role !== 'admin' && role !== 'staff') {
          setAuthError('This account is not admin/staff. Use a CMS account.');
          return;
        }
        setApiToken(payload.token || data.token);
        setUserRole(role);
        setUserName(payload.name || email);
        setIsLoggedIn(true);
        setActiveMenu(role === 'admin' ? 'dashboard' : 'orders');
      } else {
        setAuthError(data.message || 'Incorrect email or password.');
      }
    } catch (err) {
      setAuthError(`Cannot reach the backend at ${API_URL}.`);
    } finally {
      setAuthBusy(false);
    }
  };

  // --- REGISTER — saves the new account in MySQL via POST /api/auth/register ---
  const handleRegister = async (e) => {
    e.preventDefault();
    setAuthBusy(true);
    setAuthError('');
    const name = e.target.name.value.trim();
    const email = e.target.email.value.trim();
    const password = e.target.password.value;
    const role = e.target.role.value;

    if (password.length < 6) {
      setAuthError('Password must be at least 6 characters.');
      setAuthBusy(false);
      return;
    }

    try {
      const response = await fetch(`${API_URL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password, role }),
      });
      const data = await response.json();

      if (response.ok && (data.success || response.status === 201)) {
        const payload = data.data || data;
        if (payload.token && (payload.role === 'admin' || payload.role === 'staff')) {
          setApiToken(payload.token);
          setUserRole(payload.role);
          setUserName(payload.name || name);
          setIsLoggedIn(true);
          setActiveMenu(payload.role === 'admin' ? 'dashboard' : 'orders');
        } else {
          setAuthMode('login');
          setAuthError('Account created. Please sign in.');
        }
      } else {
        setAuthError(data.message || 'Failed to register. The email may be taken.');
      }
    } catch (err) {
      setAuthError('Cannot reach the backend.');
    } finally {
      setAuthBusy(false);
    }
  };

  // --- LOGIN / REGISTER SCREEN ---
  if (!isLoggedIn) {
    const cardStyle = { background: 'white', padding: '36px', borderRadius: '12px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)', width: '380px' };
    const inputStyle = { width: '100%', padding: '10px', marginTop: '5px', borderRadius: '6px', border: '1px solid #ccc', boxSizing: 'border-box' };
    const tabBtn = (active) => ({
      flex: 1, padding: '10px', cursor: 'pointer',
      background: active ? '#3b82f6' : '#e5e7eb',
      color: active ? 'white' : '#374151',
      border: 'none', fontWeight: 'bold',
    });
    const primaryBtn = { width: '100%', padding: '12px', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 'bold', marginTop: '8px' };

    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', backgroundColor: '#f3f4f6' }}>
        <div style={cardStyle}>
          <h2 style={{ textAlign: 'center', marginBottom: '20px', color: '#111827' }}>Lumiora CMS</h2>

          <div style={{ display: 'flex', marginBottom: '20px', borderRadius: '6px', overflow: 'hidden' }}>
            <button type="button" data-testid="auth-tab-login"    onClick={() => { setAuthMode('login'); setAuthError(''); }} style={tabBtn(authMode === 'login')}>Login</button>
            <button type="button" data-testid="auth-tab-register" onClick={() => { setAuthMode('register'); setAuthError(''); }} style={tabBtn(authMode === 'register')}>Register</button>
          </div>

          {authError && (
            <div data-testid="auth-error" style={{ background: '#fee2e2', color: '#991b1b', padding: '10px', borderRadius: '6px', marginBottom: '12px', fontSize: '13px' }}>
              {authError}
            </div>
          )}

          {authMode === 'login' ? (
            <form onSubmit={handleLogin} data-testid="login-form">
              <div style={{ marginBottom: '15px' }}>
                <label>Email</label>
                <input type="email" name="email" data-testid="login-email" defaultValue="diamonddark269@gmail.com" placeholder="diamonddark269@gmail.com or staff@lumiora.com" style={inputStyle} required />
              </div>
              <div style={{ marginBottom: '20px' }}>
                <label>Password</label>
                <input type="password" name="password" data-testid="login-password" placeholder="admin123 / staff123" style={inputStyle} required />
              </div>
              <button type="submit" disabled={authBusy} data-testid="login-submit" style={primaryBtn}>
                {authBusy ? 'Signing in…' : 'Sign in'}
              </button>
              <p style={{ marginTop: '14px', fontSize: '12px', color: '#6b7280', textAlign: 'center' }}>
                Default accounts: <b>admin123</b> / <b>staff123</b>. Don&apos;t have one?{' '}
                <span onClick={() => { setAuthMode('register'); setAuthError(''); }} style={{ color: '#3b82f6', cursor: 'pointer', fontWeight: 'bold' }}>Register here</span>
              </p>
            </form>
          ) : (
            <form onSubmit={handleRegister} data-testid="register-form">
              <div style={{ marginBottom: '12px' }}>
                <label>Full name</label>
                <input type="text" name="name" data-testid="register-name" style={inputStyle} required />
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label>Email</label>
                <input type="email" name="email" data-testid="register-email" style={inputStyle} required />
              </div>
              <div style={{ marginBottom: '12px' }}>
                <label>Password (min. 6 characters)</label>
                <input type="password" name="password" data-testid="register-password" minLength={6} style={inputStyle} required />
              </div>
              <div style={{ marginBottom: '20px' }}>
                <label>Role</label>
                <select name="role" data-testid="register-role" defaultValue="staff" style={inputStyle}>
                  <option value="admin">Admin</option>
                  <option value="staff">Staff</option>
                </select>
              </div>
              <button type="submit" disabled={authBusy} data-testid="register-submit" style={primaryBtn}>
                {authBusy ? 'Saving…' : 'Register & save to database'}
              </button>
              <p style={{ marginTop: '14px', fontSize: '12px', color: '#6b7280', textAlign: 'center' }}>
                Already have an account?{' '}
                <span onClick={() => { setAuthMode('login'); setAuthError(''); }} style={{ color: '#3b82f6', cursor: 'pointer', fontWeight: 'bold' }}>Sign in</span>
              </p>
            </form>
          )}
        </div>
      </div>
    );
  }

  const visibleMenu = MENU_ITEMS.filter((m) => m.roles.includes(userRole));
  const activeItem  = visibleMenu.find((m) => m.key === activeMenu) || visibleMenu[0];

  // --- DASHBOARD LAYOUT ---
  return (
    <div className="dashboard-container">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="sidebar-logo">
          <Coffee size={28} color="#3b82f6" />
          <span>Lumiora</span>
        </div>

        <ul className="sidebar-menu">
          {visibleMenu.map((item) => {
            const Icon = item.icon;
            return (
              <li
                key={item.key}
                data-testid={`nav-${item.key}`}
                className={activeMenu === item.key ? 'active' : ''}
                onClick={() => setActiveMenu(item.key)}
              >
                <Icon size={20} />
                <span>{item.label}</span>
              </li>
            );
          })}
        </ul>

        <div className="sidebar-logout">
          <li
            data-testid="sidebar-logout"
            onClick={() => { setIsLoggedIn(false); setApiToken(null); setUserRole(''); setUserName(''); }}
            style={{ display: 'flex', gap: '12px', cursor: 'pointer', color: '#ef4444' }}
          >
            <LogOut size={20} />
            <span>Sign out ({userRole})</span>
          </li>
        </div>
      </aside>

      {/* MAIN */}
      <main className="main-content">
        <header className="header">
          <div className="search-bar">
            <Search size={18} color="#9ca3af" />
            <input type="text" placeholder="Search orders, menu…" />
          </div>
          <div className="header-right">
            <Bell size={20} color="#6b7280" />
            <div className="profile">
              <span data-testid="profile-name" style={{ textTransform: 'capitalize' }}>{userName || `${userRole} Lumiora`}</span>
            </div>
          </div>
        </header>

        <div className="content-wrapper">

          {activeMenu === 'dashboard' && <DashboardPage  apiUrl={API_URL} token={apiToken} />}
          {activeMenu === 'orders'    && <OrdersPage     apiUrl={API_URL} token={apiToken} />}
          {activeMenu === 'stock'     && <InventoryPage  apiUrl={API_URL} token={apiToken} userRole={userRole} />}
          {activeMenu === 'manage'    && <MenuManagePage apiUrl={API_URL} token={apiToken} userRole={userRole} />}
          {activeMenu === 'customers' && <CustomersPage  apiUrl={API_URL} token={apiToken} />}
          {activeMenu === 'reports'   && <ReportsPage    apiUrl={API_URL} token={apiToken} />}
          {activeMenu === 'settings'  && <SettingsPage   apiUrl={API_URL} token={apiToken} userRole={userRole} />}
        </div>
      </main>
    </div>
  );
}

export default App;
