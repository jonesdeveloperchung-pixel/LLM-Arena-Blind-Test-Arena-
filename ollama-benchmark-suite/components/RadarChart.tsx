import React from 'react';
import {
  Radar,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  ResponsiveContainer,
  Tooltip
} from 'recharts';

interface RadarChartProps {
  data: { subject: string; A: number; fullMark: number }[];
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-slate-800 border border-slate-700 p-2 rounded shadow-xl text-xs text-white">
        <p className="font-bold mb-1">{label}</p>
        <p className="text-emerald-400">Score: {payload[0].value} / 5</p>
      </div>
    );
  }
  return null;
};

export const ScoreChart: React.FC<RadarChartProps> = ({ data }) => {
  return (
    <div className="w-full h-[300px] md:h-[400px]">
      <ResponsiveContainer width="100%" height="100%">
        <RadarChart cx="50%" cy="50%" outerRadius="80%" data={data}>
          <PolarGrid stroke="#334155" />
          <PolarAngleAxis 
            dataKey="subject" 
            tick={{ fill: '#94a3b8', fontSize: 12 }} 
          />
          <PolarRadiusAxis 
            angle={30} 
            domain={[0, 5]} 
            tick={{ fill: '#475569', fontSize: 10 }}
            tickCount={6} 
          />
          <Radar
            name="Model Score"
            dataKey="A"
            stroke="#10b981"
            strokeWidth={3}
            fill="#10b981"
            fillOpacity={0.4}
            isAnimationActive={true}
          />
          <Tooltip content={<CustomTooltip />} />
        </RadarChart>
      </ResponsiveContainer>
    </div>
  );
};
