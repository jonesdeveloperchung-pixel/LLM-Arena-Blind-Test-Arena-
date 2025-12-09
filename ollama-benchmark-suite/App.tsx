import React, { useState } from 'react';
import { CATEGORIES, INITIAL_RADAR_DATA } from './constants';
import { BenchmarkCategory, EvaluationResponse } from './types';
import { ScoreChart } from './components/RadarChart';
import { TestZone } from './components/TestZone';
import { Terminal, Activity, Github, Cpu, AlertTriangle } from 'lucide-react';

interface BenchmarkState {
  [key: string]: EvaluationResponse | null;
}

const App: React.FC = () => {
  const [activeCategory, setActiveCategory] = useState<BenchmarkCategory>(BenchmarkCategory.REASONING);
  const [results, setResults] = useState<BenchmarkState>({});
  const [modelName, setModelName] = useState('My Local Model');

  const handleTestComplete = (score: number, details: EvaluationResponse) => {
    setResults((prev) => ({
      ...prev,
      [activeCategory]: details,
    }));
  };

  // Transform results for the chart
  const chartData = INITIAL_RADAR_DATA.map((item) => {
    const categoryKey = CATEGORIES.find(c => c.label === item.subject)?.id;
    const result = categoryKey ? results[categoryKey] : null;
    return {
      ...item,
      A: result ? result.score : 0,
    };
  });

  const currentResult = results[activeCategory];
  const activeCategoryInfo = CATEGORIES.find(c => c.id === activeCategory)!;
  
  // Calculate Average
  const scores = Object.values(results)
    .filter((r): r is EvaluationResponse => r !== null)
    .map((r) => r.score);

  const averageScore = scores.length > 0 
    ? (scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(1) 
    : '0.0';

  if (!process.env.API_KEY) {
      return (
          <div className="min-h-screen bg-slate-900 text-white flex items-center justify-center p-4">
              <div className="max-w-md text-center space-y-4">
                  <AlertTriangle className="w-16 h-16 text-yellow-500 mx-auto" />
                  <h1 className="text-3xl font-bold">API Key Missing</h1>
                  <p className="text-slate-400">This application requires a Google Gemini API Key to function as the Judge. Please check your environment variables.</p>
              </div>
          </div>
      )
  }

  return (
    <div className="min-h-screen flex flex-col md:flex-row font-sans text-slate-100">
      {/* Sidebar / Navigation */}
      <aside className="w-full md:w-64 bg-slate-950 border-r border-slate-800 flex flex-col">
        <div className="p-6 border-b border-slate-800">
            <div className="flex items-center gap-2 text-emerald-500 font-bold text-xl mb-1">
                <Cpu /> OllamaBench
            </div>
            <p className="text-xs text-slate-500">LLM-as-a-Judge Suite</p>
        </div>

        <div className="p-4 space-y-4 border-b border-slate-800">
            <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Target Model</label>
            <div className="flex items-center gap-2 bg-slate-900 p-2 rounded border border-slate-800">
                <Terminal size={16} className="text-slate-400" />
                <input 
                    type="text" 
                    value={modelName}
                    onChange={(e) => setModelName(e.target.value)}
                    className="bg-transparent text-sm w-full outline-none text-white placeholder-slate-600"
                    placeholder="e.g. Llama3:8b"
                />
            </div>
        </div>

        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          <label className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2 block">Benchmarks</label>
          {CATEGORIES.map((cat) => {
            const isCompleted = !!results[cat.id];
            const isActive = activeCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => setActiveCategory(cat.id)}
                className={`w-full flex items-center justify-between p-3 rounded-lg text-sm transition-all ${
                  isActive 
                    ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' 
                    : 'text-slate-400 hover:bg-slate-900 hover:text-white'
                }`}
              >
                <div className="flex items-center gap-3">
                  <cat.icon size={18} />
                  <span>{cat.label}</span>
                </div>
                {isCompleted && (
                    <span className="text-xs font-bold bg-emerald-500/20 px-2 py-0.5 rounded text-emerald-400">
                        {results[cat.id]?.score} ★
                    </span>
                )}
              </button>
            );
          })}
        </nav>

        <div className="p-6 border-t border-slate-800">
            <div className="text-center">
                <span className="text-xs text-slate-500">Overall Score</span>
                <div className="text-3xl font-bold text-white mt-1">{averageScore}</div>
                <div className="flex justify-center gap-1 mt-2">
                     {[1, 2, 3, 4, 5].map(star => (
                         <div key={star} className={`w-2 h-2 rounded-full ${parseFloat(averageScore) >= star ? 'bg-emerald-500' : 'bg-slate-800'}`} />
                     ))}
                </div>
            </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-4 md:p-8 overflow-y-auto bg-slate-900/50">
        <header className="flex justify-between items-center mb-8">
            <div>
                <h1 className="text-2xl font-bold text-white flex items-center gap-2">
                    {modelName} <span className="text-slate-600">/</span> {activeCategoryInfo.label}
                </h1>
                <p className="text-slate-400 text-sm mt-1">
                    Environment: Local GPU • Judge: Gemini 2.5 Flash
                </p>
            </div>
            <a href="https://github.com/ollama/ollama" target="_blank" rel="noreferrer" className="text-slate-500 hover:text-white transition">
                <Github size={24} />
            </a>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Left Column: Test Interface */}
            <div className="lg:col-span-2">
                <TestZone 
                    category={activeCategory} 
                    categoryInfo={activeCategoryInfo}
                    onComplete={handleTestComplete}
                />
                
                {/* Result Feedback Card (if exists) */}
                {currentResult && (
                    <div className="mt-8 bg-slate-800 border border-slate-700 rounded-xl p-6 animate-in fade-in slide-in-from-bottom-2">
                        <div className="flex items-center gap-2 mb-4">
                            <Activity className="text-emerald-400" />
                            <h3 className="text-lg font-bold text-white">Judge's Analysis</h3>
                        </div>
                        <p className="text-slate-300 leading-relaxed mb-6">
                            {currentResult.reasoning}
                        </p>
                        
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                            {Object.entries(currentResult.breakdown || {}).map(([key, val]) => (
                                <div key={key} className="bg-slate-900 p-3 rounded-lg border border-slate-800 text-center">
                                    <div className="text-xs text-slate-500 uppercase font-semibold mb-1">{key}</div>
                                    <div className="text-xl font-bold text-emerald-400">{val}/5</div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>

            {/* Right Column: Visualization */}
            <div className="space-y-8">
                <div className="bg-slate-800 border border-slate-700 rounded-xl p-6">
                    <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-4">Performance Profile</h3>
                    <ScoreChart data={chartData} />
                </div>

                <div className="bg-slate-800 border border-slate-700 rounded-xl p-6">
                    <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-4">Metric Definitions</h3>
                    <ul className="space-y-3">
                        {activeCategoryInfo.metrics.map((metric, idx) => (
                            <li key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                                <div className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                                {metric}
                            </li>
                        ))}
                    </ul>
                </div>
            </div>
        </div>
      </main>
    </div>
  );
};

export default App;