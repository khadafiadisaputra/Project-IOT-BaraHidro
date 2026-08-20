import React from 'react';
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, 
  Tooltip, ResponsiveContainer 
} from 'recharts';

const CustomTooltip = ({ active, payload, label, unit }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-slate-900/90 backdrop-blur-sm text-white px-3 py-2 rounded-xl shadow-lg border border-slate-700 text-xs">
        <p className="text-slate-400 mb-1">{label}</p>
        <p className="font-bold text-sm">
          {payload[0].value} <span className="text-slate-300 font-normal text-xs">{unit}</span>
        </p>
      </div>
    );
  }
  return null;
};

const ProperSensorChart = ({ data = [], dataKey, color = '#3b82f6', unit = '', title = '', yAxisLabel = '' }) => {
  // Hitung ringkasan statistik (Min, Rata-rata, Max)
  const values = data.map(item => Number(item[dataKey])).filter(val => !isNaN(val));
  const minVal = values.length ? Math.min(...values).toFixed(1) : 0;
  const maxVal = values.length ? Math.max(...values).toFixed(1) : 0;
  const avgVal = values.length ? (values.reduce((a, b) => a + b, 0) / values.length).toFixed(1) : 0;

  // Unique ID untuk gradient SVG
  const gradientId = `colorGradient-${dataKey}`;

  return (
    <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col justify-between h-[380px]">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-full" style={{ backgroundColor: color }}></span>
          <h3 className="font-bold text-slate-800 text-sm tracking-wide">{title}</h3>
        </div>
      </div>

      {/* Area Chart Container */}
      <div className="flex-1 w-full min-h-[200px]">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={color} stopOpacity={0.4} />
                <stop offset="95%" stopColor={color} stopOpacity={0.0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
            <XAxis 
              dataKey="time" 
              tick={{ fontSize: 10, fill: '#94a3b8' }} 
              tickLine={false} 
              axisLine={{ stroke: '#e2e8f0' }}
            />
            <YAxis 
              domain={['auto', 'auto']} // Skala dinamis otomatis mengikuti rentang data
              tick={{ fontSize: 10, fill: '#94a3b8' }} 
              tickLine={false} 
              axisLine={false}
            />
            <Tooltip content={<CustomTooltip unit={unit} />} />
            <Area 
              type="monotone" 
              dataKey={dataKey} 
              stroke={color} 
              strokeWidth={2.5}
              fillOpacity={1} 
              fill={`url(#${gradientId})`} 
              isAnimationActive={true}
              animationDuration={800}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Footer Statistik */}
      <div className="grid grid-cols-3 gap-2 mt-4 pt-3 border-t border-slate-50 text-center">
        <div>
          <p className="text-[11px] text-slate-400 font-medium">Min</p>
          <p className="text-xs font-bold text-slate-700">{minVal} <span className="text-[10px] text-slate-400 font-normal">{unit}</span></p>
        </div>
        <div>
          <p className="text-[11px] text-slate-400 font-medium">Rata-rata</p>
          <p className="text-xs font-bold text-slate-700">{avgVal} <span className="text-[10px] text-slate-400 font-normal">{unit}</span></p>
        </div>
        <div>
          <p className="text-[11px] text-slate-400 font-medium">Max</p>
          <p className="text-xs font-bold text-slate-700">{maxVal} <span className="text-[10px] text-slate-400 font-normal">{unit}</span></p>
        </div>
      </div>
    </div>
  );
};

export default ProperSensorChart;