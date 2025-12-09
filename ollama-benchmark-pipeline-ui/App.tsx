import React, { useState, useEffect } from 'react';
import { LayoutDashboard, List, CheckSquare, Settings as SettingsIcon, Menu } from 'lucide-react';
import Dashboard from './components/Dashboard';
import QueueList from './components/QueueList';
import ReviewDetail from './components/ReviewDetail';
import Settings from './components/Settings';
import { mockBackend } from './services/mockBackend';
import { PipelineItem, ItemStatus, PipelineStats, SystemConfig } from './types';

const App: React.FC = () => {
  // Navigation State
  const [activeView, setActiveView] = useState<'dashboard' | 'queue' | 'processed' | 'settings'>('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  
  // Data State
  const [items, setItems] = useState<PipelineItem[]>([]);
  const [stats, setStats] = useState<PipelineStats>({
    total: 0, pending: 0, approved: 0, rejected: 0, avgProcessingTime: 0, uptime: '-'
  });
  
  // Selection State for Review
  const [selectedItem, setSelectedItem] = useState<PipelineItem | null>(null);

  // Config State
  const [config, setConfig] = useState<SystemConfig>({
    ollamaUrl: 'http://localhost:11434',
    model: 'llama3.2-vision',
    useGeminiFallback: false,
    geminiApiKey: '',
    autoApproveConfidence: 0.85,
    watchPath: './input',
    outputPath: './output'
  });

  // Initial Load
  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000); // Poll every 30s
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    const [fetchedItems, fetchedStats] = await Promise.all([
      mockBackend.getItems(),
      mockBackend.getStats()
    ]);
    setItems(fetchedItems);
    setStats(fetchedStats);
  };

  const handleUpdateStatus = async (id: string, status: ItemStatus, description: string) => {
    const updated = await mockBackend.updateItemStatus(id, status, description);
    if (updated) {
      setItems(prev => prev.map(i => i.id === id ? updated : i));
      setSelectedItem(null); // Close detail view
      
      // Update stats optimistically
      setStats(prev => ({
        ...prev,
        pending: status === ItemStatus.PENDING ? prev.pending : prev.pending - 1,
        approved: status === ItemStatus.APPROVED ? prev.approved + 1 : prev.approved,
        rejected: status === ItemStatus.REJECTED ? prev.rejected + 1 : prev.rejected
      }));
    }
  };

  const renderContent = () => {
    if (selectedItem) {
      return (
        <ReviewDetail 
          item={selectedItem} 
          onClose={() => setSelectedItem(null)}
          onUpdateStatus={handleUpdateStatus}
          geminiApiKey={config.geminiApiKey}
        />
      );
    }

    switch (activeView) {
      case 'dashboard':
        return <Dashboard stats={stats} />;
      case 'queue':
        return (
          <div className="space-y-4">
            <h2 className="text-2xl font-bold text-gray-800">待審核隊列 (Pending Queue)</h2>
            <QueueList items={items} filter={ItemStatus.PENDING} onSelectItem={setSelectedItem} />
          </div>
        );
      case 'processed':
        return (
           <div className="space-y-4">
            <h2 className="text-2xl font-bold text-gray-800">已處理記錄 (Processed History)</h2>
            <QueueList items={items} filter="all" onSelectItem={setSelectedItem} />
          </div>
        );
      case 'settings':
        return <Settings config={config} onSave={setConfig} />;
      default:
        return <Dashboard stats={stats} />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-100 text-gray-900 font-sans overflow-hidden">
      {/* Sidebar */}
      <aside 
        className={`${isSidebarOpen ? 'w-64' : 'w-20'} bg-gray-900 text-gray-300 transition-all duration-300 flex flex-col shadow-xl z-20`}
      >
        <div className="h-16 flex items-center justify-center border-b border-gray-800 px-4">
          {isSidebarOpen ? (
            <span className="text-xl font-bold text-white tracking-wider">OllamaUI</span>
          ) : (
            <span className="text-xl font-bold text-white">O</span>
          )}
        </div>

        <nav className="flex-1 py-6 space-y-2 px-2">
          <button 
            onClick={() => setActiveView('dashboard')}
            className={`w-full flex items-center px-4 py-3 rounded-lg transition-colors ${activeView === 'dashboard' ? 'bg-blue-600 text-white shadow-lg' : 'hover:bg-gray-800'}`}
          >
            <LayoutDashboard size={20} />
            {isSidebarOpen && <span className="ml-3 font-medium">儀表板</span>}
          </button>

          <button 
            onClick={() => setActiveView('queue')}
            className={`w-full flex items-center px-4 py-3 rounded-lg transition-colors ${activeView === 'queue' ? 'bg-blue-600 text-white shadow-lg' : 'hover:bg-gray-800'}`}
          >
            <List size={20} />
            {isSidebarOpen && (
              <div className="ml-3 flex-1 flex justify-between items-center">
                <span className="font-medium">待審核</span>
                {stats.pending > 0 && (
                   <span className="bg-yellow-500 text-gray-900 text-xs font-bold px-2 py-0.5 rounded-full">{stats.pending}</span>
                )}
              </div>
            )}
          </button>

          <button 
            onClick={() => setActiveView('processed')}
            className={`w-full flex items-center px-4 py-3 rounded-lg transition-colors ${activeView === 'processed' ? 'bg-blue-600 text-white shadow-lg' : 'hover:bg-gray-800'}`}
          >
            <CheckSquare size={20} />
            {isSidebarOpen && <span className="ml-3 font-medium">已處理</span>}
          </button>
        </nav>

        <div className="p-2 border-t border-gray-800">
           <button 
            onClick={() => setActiveView('settings')}
            className={`w-full flex items-center px-4 py-3 rounded-lg transition-colors ${activeView === 'settings' ? 'bg-gray-800 text-white' : 'hover:bg-gray-800'}`}
          >
            <SettingsIcon size={20} />
            {isSidebarOpen && <span className="ml-3 font-medium">設定</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 shadow-sm z-10">
          <div className="flex items-center gap-4">
             <button onClick={() => setIsSidebarOpen(!isSidebarOpen)} className="p-2 hover:bg-gray-100 rounded-lg text-gray-600">
               <Menu size={20} />
             </button>
             <h1 className="text-xl font-semibold text-gray-800">
               {activeView === 'dashboard' && '儀表板'}
               {activeView === 'queue' && '待審核隊列'}
               {activeView === 'processed' && '所有記錄'}
               {activeView === 'settings' && '系統設定'}
               {selectedItem && ` / ${selectedItem.filename}`}
             </h1>
          </div>
          <div className="flex items-center gap-4">
             <div className="flex flex-col items-end">
                <span className="text-xs text-gray-500">Daemon Status</span>
                <span className="text-sm font-medium text-green-600 flex items-center gap-1">
                   <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                   Active
                </span>
             </div>
          </div>
        </header>

        <main className="flex-1 overflow-auto p-6 relative">
          {renderContent()}
        </main>
      </div>
    </div>
  );
};

export default App;
