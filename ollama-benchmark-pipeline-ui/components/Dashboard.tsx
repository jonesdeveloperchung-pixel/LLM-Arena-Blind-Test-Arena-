import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { PipelineStats, ItemStatus } from '../types';
import { Activity, CheckCircle, XCircle, Clock, Server } from 'lucide-react';

interface DashboardProps {
  stats: PipelineStats;
}

const Dashboard: React.FC<DashboardProps> = ({ stats }) => {
  const data = [
    { name: '待審核 (Pending)', value: stats.pending, color: '#f59e0b' }, // Amber
    { name: '已核准 (Approved)', value: stats.approved, color: '#10b981' }, // Emerald
    { name: '已駁回 (Rejected)', value: stats.rejected, color: '#ef4444' }, // Red
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <h2 className="text-2xl font-bold text-gray-800">儀表板 (Dashboard)</h2>
      
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center space-x-4">
          <div className="p-3 bg-blue-50 text-blue-600 rounded-full">
            <Activity size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">總處理量 (Total)</p>
            <p className="text-2xl font-bold text-gray-800">{stats.total}</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center space-x-4">
          <div className="p-3 bg-green-50 text-green-600 rounded-full">
            <CheckCircle size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">核准率 (Approval Rate)</p>
            <p className="text-2xl font-bold text-gray-800">
              {stats.total > 0 ? ((stats.approved / stats.total) * 100).toFixed(1) : 0}%
            </p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center space-x-4">
          <div className="p-3 bg-purple-50 text-purple-600 rounded-full">
            <Clock size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">平均處理時間 (Avg Time)</p>
            <p className="text-2xl font-bold text-gray-800">{stats.avgProcessingTime.toFixed(0)} ms</p>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex items-center space-x-4">
          <div className="p-3 bg-orange-50 text-orange-600 rounded-full">
            <Server size={24} />
          </div>
          <div>
            <p className="text-sm text-gray-500">運行時間 (Uptime)</p>
            <p className="text-2xl font-bold text-gray-800">{stats.uptime}</p>
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">狀態分佈 (Status Distribution)</h3>
          <div className="h-64 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data} layout="vertical" margin={{ top: 5, right: 30, left: 40, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                <XAxis type="number" />
                <YAxis dataKey="name" type="category" width={100} tick={{fontSize: 12}} />
                <Tooltip />
                <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                  {data.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">系統健康度 (System Health)</h3>
          <div className="space-y-4">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
              <span className="flex items-center space-x-2 text-gray-600">
                 <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
                 <span>Daemon Service</span>
              </span>
              <span className="text-green-600 font-medium">Running</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
              <span className="flex items-center space-x-2 text-gray-600">
                 <div className="w-2 h-2 rounded-full bg-green-500"></div>
                 <span>Database (SQLite)</span>
              </span>
              <span className="text-green-600 font-medium">Connected</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
              <span className="flex items-center space-x-2 text-gray-600">
                 <div className="w-2 h-2 rounded-full bg-yellow-500"></div>
                 <span>Ollama API</span>
              </span>
              <span className="text-yellow-600 font-medium">Idle</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
