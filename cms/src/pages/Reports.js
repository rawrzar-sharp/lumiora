import React, { useEffect, useState } from 'react';

export default function ReportsPage({ apiUrl, token }) {
  const [daily, setDaily] = useState([]);
  const [monthly, setMonthly] = useState([]);

  useEffect(() => {
    if (!apiUrl) return;
    fetch(`${apiUrl}/api/cms/reports/daily`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json()).then(d => { if (d && d.success) setDaily(d.data || []); }).catch(()=>{});
    fetch(`${apiUrl}/api/cms/reports/monthly`, { headers: token ? { Authorization: `Bearer ${token}` } : {} })
      .then(r => r.json()).then(d => { if (d && d.success) setMonthly(d.data || []); }).catch(()=>{});
  }, [apiUrl, token]);

  return (
    <div>
      <h3>Reports</h3>
      <h4>Daily</h4>
      <ul>{daily.length ? daily.map((d,i)=>(<li key={i}>{d.date || d.day}: {d.total || d.sales}</li>)) : <li>No daily data</li>}</ul>
      <h4>Monthly</h4>
      <ul>{monthly.length ? monthly.map((m,i)=>(<li key={i}>{m.month}: {m.total || m.sales}</li>)) : <li>No monthly data</li>}</ul>
    </div>
  );
}
