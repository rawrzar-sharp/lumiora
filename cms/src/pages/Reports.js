import React, { useCallback, useEffect, useState } from 'react';

const palette = {
  ink: '#1F2117',
  moss: '#7B8C2A',
  parchment: '#EFEAD8',
  amber: '#C28840',
};

const fmtRp = (n) => `Rp ${Number(n || 0).toLocaleString('id-ID')}`;

const card = {
  background: 'white',
  borderRadius: 14,
  padding: '18px 20px',
  boxShadow: '0 2px 10px rgba(31, 33, 23, 0.06)',
  border: `1px solid ${palette.parchment}`,
};

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export default function ReportsPage({ apiUrl, token }) {
  const [daily, setDaily] = useState([]);
  const [monthly, setMonthly] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    if (!apiUrl) return;
    const headers = token ? { Authorization: `Bearer ${token}` } : {};
    try {
      const [d, m] = await Promise.all([
        fetch(`${apiUrl}/api/cms/reports/daily`,   { headers }).then((r) => r.json()),
        fetch(`${apiUrl}/api/cms/reports/monthly`, { headers }).then((r) => r.json()),
      ]);
      if (d && d.success) setDaily(d.data || []);
      if (m && m.success) setMonthly(m.data || []);
    } catch (e) {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, [apiUrl, token]);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const dailyMax = Math.max(1, ...daily.map((d) => Number(d.total_sales || 0)));

  return (
    <div data-testid="cms-reports-page" style={{ display: 'grid', gap: 18 }}>
      <div>
        <h3 style={{ margin: 0, color: palette.ink, fontSize: 22 }}>Reports</h3>
        <p style={{ margin: '4px 0 0', color: '#777', fontSize: 13 }}>
          Live sales pulled from the <code>orders</code> table.
        </p>
      </div>

      {loading && <div style={card}>Loading reports…</div>}

      {/* DAILY */}
      <section style={card} data-testid="reports-daily">
        <h4 style={{ margin: 0, color: palette.ink, fontSize: 16 }}>Daily Sales</h4>
        <p style={{ marginTop: 4, fontSize: 12, color: '#888' }}>Up to last 90 days (newest first).</p>
        {daily.length === 0 ? (
          <div data-testid="reports-daily-empty" style={{ color: '#999', marginTop: 12, fontSize: 13 }}>
            No daily sales recorded yet. Once orders are completed they show up here.
          </div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, marginTop: 10 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '8px 4px' }}>Date</th>
                <th style={{ padding: '8px 4px' }}>Revenue</th>
                <th style={{ padding: '8px 4px', width: '50%' }}>Bar</th>
              </tr>
            </thead>
            <tbody>
              {daily.map((d, i) => {
                const pct = Math.round((Number(d.total_sales || 0) / dailyMax) * 100);
                return (
                  <tr key={i} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                    <td style={{ padding: '10px 4px' }}>{(d.report_date || '').toString().slice(0, 10)}</td>
                    <td style={{ padding: '10px 4px', fontWeight: 700, color: palette.ink }}>{fmtRp(d.total_sales)}</td>
                    <td style={{ padding: '10px 4px' }}>
                      <div style={{ height: 10, background: palette.parchment, borderRadius: 999 }}>
                        <div style={{ width: `${pct}%`, height: '100%', background: palette.moss, borderRadius: 999, transition: 'width .4s' }} />
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>

      {/* MONTHLY */}
      <section style={card} data-testid="reports-monthly">
        <h4 style={{ margin: 0, color: palette.ink, fontSize: 16 }}>Monthly Sales</h4>
        {monthly.length === 0 ? (
          <div data-testid="reports-monthly-empty" style={{ color: '#999', marginTop: 12, fontSize: 13 }}>
            No monthly data yet.
          </div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, marginTop: 10 }}>
            <thead>
              <tr style={{ textAlign: 'left', color: '#777', fontSize: 11, textTransform: 'uppercase' }}>
                <th style={{ padding: '8px 4px' }}>Period</th>
                <th style={{ padding: '8px 4px' }}>Revenue</th>
              </tr>
            </thead>
            <tbody>
              {monthly.map((m, i) => (
                <tr key={i} style={{ borderTop: `1px solid ${palette.parchment}` }}>
                  <td style={{ padding: '10px 4px' }}>{MONTHS[(Number(m.month) || 1) - 1]} {m.year}</td>
                  <td style={{ padding: '10px 4px', fontWeight: 700, color: palette.ink }}>{fmtRp(m.total_sales)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}
