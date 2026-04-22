'use client';

import { useEffect, useState } from 'react';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

interface StatsData {
  totalSos: number;
  activeAlerts: number;
  totalUsers: number;
  resolvedToday: number;
}

interface SosAlert {
  id: string;
  lat: number;
  lng: number;
  trigger_type: string;
  status: string;
  created_at: string;
  battery_pct: number;
}

async function supabaseFetch(path: string) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: {
      apikey: ANON_KEY,
      Authorization: `Bearer ${ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    cache: 'no-store',
  });
  return res.json();
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<StatsData | null>(null);
  const [alerts, setAlerts] = useState<SosAlert[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const [allAlerts, active] = await Promise.all([
        supabaseFetch('sos_alerts?select=id,lat,lng,trigger_type,status,created_at,battery_pct&order=created_at.desc&limit=50'),
        supabaseFetch('sos_alerts?status=eq.active&select=id'),
      ]);
      
      const today = new Date().toISOString().split('T')[0];
      const resolvedToday = allAlerts.filter((a: SosAlert) => 
        a.status === 'resolved' && a.created_at.startsWith(today)
      ).length;

      setStats({
        totalSos: allAlerts.length,
        activeAlerts: active.length,
        totalUsers: 0, // Expand later with users table query
        resolvedToday,
      });
      setAlerts(allAlerts);
      setLoading(false);
    }
    load();
    const interval = setInterval(load, 15000); // Auto-refresh every 15s
    return () => clearInterval(interval);
  }, []);

  if (loading) return (
    <div className="min-h-screen bg-gray-950 flex items-center justify-center">
      <div className="text-pink-500 text-2xl font-bold animate-pulse">KAWACH ADMIN LOADING...</div>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-950 text-white p-8">
      {/* Header */}
      <div className="flex items-center gap-3 mb-10">
        <div className="w-3 h-3 rounded-full bg-pink-500 animate-pulse" />
        <h1 className="text-3xl font-bold tracking-wide">KAWACH <span className="text-pink-500">ADMIN</span></h1>
        <span className="ml-auto text-xs text-gray-500">Live · refreshes every 15s</span>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-10">
        {[
          { label: 'Total SOS Events', value: stats!.totalSos, color: 'text-pink-400' },
          { label: 'Active Now', value: stats!.activeAlerts, color: 'text-red-500' },
          { label: 'Resolved Today', value: stats!.resolvedToday, color: 'text-green-400' },
          { label: 'Offline Queue', value: '—', color: 'text-yellow-400' },
        ].map((s) => (
          <div key={s.label} className="bg-gray-900 border border-gray-800 rounded-2xl p-6">
            <div className={`text-4xl font-bold ${s.color}`}>{s.value}</div>
            <div className="text-gray-400 text-sm mt-2">{s.label}</div>
          </div>
        ))}
      </div>

      {/* SOS Log Table */}
      <div className="bg-gray-900 border border-gray-800 rounded-2xl overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-800 flex items-center gap-2">
          <span className="text-lg font-bold">SOS Event Log</span>
          <span className="ml-auto text-xs text-gray-500">{alerts.length} records</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-gray-500 border-b border-gray-800">
              <tr>
                {['Time', 'Trigger', 'Status', 'Battery', 'Coordinates'].map(h => (
                  <th key={h} className="px-6 py-3 text-left font-medium">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {alerts.map((a) => (
                <tr key={a.id} className="hover:bg-gray-800 transition-colors">
                  <td className="px-6 py-4 text-gray-300">
                    {new Date(a.created_at).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' })}
                  </td>
                  <td className="px-6 py-4">
                    <span className="bg-pink-900 text-pink-300 px-2 py-0.5 rounded-full text-xs">
                      {a.trigger_type}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      a.status === 'active' ? 'bg-red-900 text-red-300' :
                      a.status === 'resolved' ? 'bg-green-900 text-green-300' :
                      'bg-gray-700 text-gray-300'
                    }`}>{a.status}</span>
                  </td>
                  <td className="px-6 py-4 text-gray-400">{a.battery_pct}%</td>
                  <td className="px-6 py-4 text-gray-400 font-mono text-xs">
                    {a.lat?.toFixed(4)}, {a.lng?.toFixed(4)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
