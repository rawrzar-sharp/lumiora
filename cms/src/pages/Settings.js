import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
  rust: '#C2452F',
};

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

const inputStyle = {
  width: '100%', padding: '10px', borderRadius: 8,
  border: `1px solid ${palette.parchment}`, boxSizing: 'border-box', fontSize: 13,
};

export default function SettingsPage({ apiUrl, token, userRole }) {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [msg, setMsg] = useState({ tone: 'info', text: '' });
  const isAdmin = userRole === 'admin';

  const authHeaders = token ? { Authorization: `Bearer ${token}` } : {};

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`${apiUrl}/api/users`, { headers: authHeaders });
      const json = await res.json();
      if (json && json.success) {
        // CMS only manages admin/staff accounts; filter out the auto-created
        // customer rows that get inserted when shoppers self-register.
        const data = (json.data || []).filter((u) => u.role === 'admin' || u.role === 'staff');
        setUsers(data);
      }
      else if (res.status === 403) setMsg({ tone: 'warn', text: 'Admin role required to view staff list.' });
    } catch (e) {
      setMsg({ tone: 'error', text: 'Could not reach the API.' });
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiUrl, token]);

  useEffect(() => { if (isAdmin) fetchUsers(); else setLoading(false); }, [fetchUsers, isAdmin]);

  const createStaff = async (e) => {
    e.preventDefault();
    setCreating(true);
    setMsg({ tone: 'info', text: '' });
    const form = e.target;
    const payload = {
      name: form.name.value.trim(),
      email: form.email.value.trim(),
      password: form.password.value,
      role: form.role.value,
    };
    try {
      const res = await fetch(`${apiUrl}/api/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...authHeaders },
        body: JSON.stringify(payload),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        setMsg({ tone: 'success', text: `Staff "${payload.name}" created.` });
        form.reset();
        fetchUsers();
      } else {
        setMsg({ tone: 'error', text: json.message || 'Failed to create staff' });
      }
    } catch (e) {
      setMsg({ tone: 'error', text: 'Could not reach API' });
    } finally {
      setCreating(false);
    }
  };

  const deleteUser = async (u) => {
    if (!window.confirm(`Remove ${u.name} (${u.email})?`)) return;
    try {
      const res = await fetch(`${apiUrl}/api/users/${u.id}`, {
        method: 'DELETE',
        headers: authHeaders,
      });
      const json = await res.json();
      if (json && json.success) fetchUsers();
      else setMsg({ tone: 'error', text: json.message || 'Failed to delete' });
    } catch (e) {
      setMsg({ tone: 'error', text: 'Could not reach API' });
    }
  };

  return (
    <div data-testid="cms-settings-page" style={{ display: 'grid', gap: 18 }}>
      <div>
        <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Settings</h3>
        <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
          Manage staff accounts that can sign in to the CMS.
        </p>
      </div>

      {!isAdmin && (
        <div style={{ ...card, color: palette.rust }} data-testid="settings-restricted">
          You need an admin account to manage staff users.
        </div>
      )}

      {isAdmin && (
        <>
          <section style={card} data-testid="settings-create-staff">
            <h4 style={{ margin: 0, color: palette.ink, fontSize: 16 }}>Add staff member</h4>
            <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>
              New accounts are saved straight to the <code>users</code> table.
            </p>
            <form onSubmit={createStaff} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: 10, marginTop: 12 }}>
              <input data-testid="settings-name"     name="name"     placeholder="Full name"        required style={inputStyle} />
              <input data-testid="settings-email"    name="email"    type="email" placeholder="email@lumiora.com" required style={inputStyle} />
              <input data-testid="settings-password" name="password" type="password" placeholder="Password (min. 6)" minLength={6} required style={inputStyle} />
              <select data-testid="settings-role" name="role" defaultValue="staff" style={inputStyle}>
                <option value="staff">Staff</option>
                <option value="admin">Admin</option>
              </select>
              <button
                data-testid="settings-submit"
                type="submit"
                disabled={creating}
                style={{ background: palette.moss, color: 'white', border: 'none', padding: '10px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 700, fontSize: 13 }}
              >
                {creating ? 'Saving…' : 'Create staff'}
              </button>
            </form>
            {msg.text && (
              <div data-testid="settings-msg" style={{
                marginTop: 10, padding: '8px 12px', borderRadius: 8, fontSize: 12,
                background: msg.tone === 'success' ? '#E7F3D9' : msg.tone === 'error' ? '#FEE' : '#F1ECE0',
                color: msg.tone === 'success' ? palette.moss : msg.tone === 'error' ? palette.rust : palette.ink,
              }}>{msg.text}</div>
            )}
          </section>

          <section style={card}>
            <h4 style={{ margin: 0, color: palette.ink, fontSize: 16 }}>Staff & Admins</h4>
            {loading ? (
              <div style={{ color: '#777', marginTop: 10 }}>Loading…</div>
            ) : users.length === 0 ? (
              <div data-testid="settings-users-empty" style={{ color: '#777', marginTop: 10 }}>No users yet.</div>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, marginTop: 10 }}>
                <thead>
                  <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                    <th style={{ padding: '8px 4px' }}>ID</th>
                    <th style={{ padding: '8px 4px' }}>Name</th>
                    <th style={{ padding: '8px 4px' }}>Email</th>
                    <th style={{ padding: '8px 4px' }}>Role</th>
                    <th style={{ padding: '8px 4px' }}>Created</th>
                    <th style={{ padding: '8px 4px' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((u) => (
                    <tr key={u.id} data-testid={`user-row-${u.id}`} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                      <td style={{ padding: '10px 4px', color: '#999' }}>#{u.id}</td>
                      <td style={{ padding: '10px 4px', fontWeight: 600, color: palette.ink }}>{u.name}</td>
                      <td style={{ padding: '10px 4px', color: '#666' }}>{u.email}</td>
                      <td style={{ padding: '10px 4px', textTransform: 'capitalize' }}>
                        <span style={{
                          padding: '3px 10px', borderRadius: 999, fontWeight: 700, fontSize: 11,
                          background: u.role === 'admin' ? '#FFF1D5' : '#E7F3D9',
                          color: u.role === 'admin' ? '#B57E2F' : palette.moss,
                        }}>{u.role}</span>
                      </td>
                      <td style={{ padding: '10px 4px', color: '#666' }}>{u.created_at ? new Date(u.created_at).toLocaleDateString() : '—'}</td>
                      <td style={{ padding: '10px 4px', textAlign: 'right' }}>
                        <button
                          data-testid={`user-delete-${u.id}`}
                          onClick={() => deleteUser(u)}
                          style={{ background: 'transparent', border: `1px solid ${palette.rust}`, color: palette.rust, padding: '6px 10px', borderRadius: 8, cursor: 'pointer', fontSize: 12, fontWeight: 700 }}
                        >Remove</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </section>
        </>
      )}
    </div>
  );
}
