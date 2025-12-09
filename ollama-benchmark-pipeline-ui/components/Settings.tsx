import React from 'react';
import { SystemConfig } from '../types';
import { Save, AlertTriangle } from 'lucide-react';

interface SettingsProps {
  config: SystemConfig;
  onSave: (newConfig: SystemConfig) => void;
}

const Settings: React.FC<SettingsProps> = ({ config, onSave }) => {
  const [localConfig, setLocalConfig] = React.useState<SystemConfig>(config);
  const [isDirty, setIsDirty] = React.useState(false);

  const handleChange = (key: keyof SystemConfig, value: any) => {
    setLocalConfig(prev => ({ ...prev, [key]: value }));
    setIsDirty(true);
  };

  const handleSave = () => {
    onSave(localConfig);
    setIsDirty(false);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-800">系統設定 (Settings)</h2>
        <button
          onClick={handleSave}
          disabled={!isDirty}
          className={`flex items-center gap-2 px-6 py-2 rounded-lg font-medium transition-colors ${
            isDirty 
            ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md' 
            : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          <Save size={18} />
          儲存變更 (Save)
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6 space-y-8">
        {/* Core Paths */}
        <section>
          <h3 className="text-lg font-semibold text-gray-700 mb-4 pb-2 border-b">目錄路徑 (Directory Paths)</h3>
          <div className="grid gap-6 md:grid-cols-2">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">監控資料夾 (Input/Watch Path)</label>
              <input
                type="text"
                value={localConfig.watchPath}
                onChange={(e) => handleChange('watchPath', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
              />
              <p className="text-xs text-gray-500 mt-1">Daemon 將監控此資料夾中的新圖片</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">輸出資料夾 (Output Path)</label>
              <input
                type="text"
                value={localConfig.outputPath}
                onChange={(e) => handleChange('outputPath', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
              />
              <p className="text-xs text-gray-500 mt-1">核准後的檔案將移動至此</p>
            </div>
          </div>
        </section>

        {/* Models */}
        <section>
          <h3 className="text-lg font-semibold text-gray-700 mb-4 pb-2 border-b">模型配置 (Model Configuration)</h3>
          <div className="space-y-4">
             <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Ollama API URL</label>
              <input
                type="text"
                value={localConfig.ollamaUrl}
                onChange={(e) => handleChange('ollamaUrl', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                placeholder="http://localhost:11434"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">主要模型 (Primary Model)</label>
              <select
                value={localConfig.model}
                onChange={(e) => handleChange('model', e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="llama3.2-vision">Llama 3.2 Vision (Default)</option>
                <option value="llava">LLaVA</option>
                <option value="moondream">Moondream</option>
              </select>
            </div>
            
            <div className="bg-blue-50 p-4 rounded-lg border border-blue-100 mt-4">
              <div className="flex items-center gap-2 mb-2">
                 <input 
                   type="checkbox" 
                   id="useGemini"
                   checked={localConfig.useGeminiFallback}
                   onChange={(e) => handleChange('useGeminiFallback', e.target.checked)}
                   className="h-4 w-4 text-blue-600 rounded"
                 />
                 <label htmlFor="useGemini" className="font-semibold text-blue-900">啟用 Gemini 雲端備援 (Enable Gemini Fallback)</label>
              </div>
              <p className="text-sm text-blue-700 mb-3 ml-6">當本地模型失敗或描述不佳時，允許使用 Google Gemini 2.5 Flash 重新生成。</p>
              
              {localConfig.useGeminiFallback && (
                <div className="ml-6">
                   <label className="block text-sm font-medium text-blue-900 mb-1">Gemini API Key</label>
                   <input
                    type="password"
                    value={localConfig.geminiApiKey}
                    onChange={(e) => handleChange('geminiApiKey', e.target.value)}
                    className="w-full px-4 py-2 border border-blue-200 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                    placeholder="AIzaSy..."
                  />
                  <p className="text-xs text-blue-500 mt-1">Key is stored locally in browser memory only.</p>
                </div>
              )}
            </div>
          </div>
        </section>

        {/* Automation */}
        <section>
          <h3 className="text-lg font-semibold text-gray-700 mb-4 pb-2 border-b">自動化規則 (Automation Rules)</h3>
          <div className="flex items-start gap-3 p-4 bg-yellow-50 border border-yellow-100 rounded-lg">
            <AlertTriangle className="text-yellow-600 mt-1" size={20} />
            <div>
               <h4 className="font-medium text-yellow-800">自動核准閾值 (Auto-Approve Confidence)</h4>
               <p className="text-sm text-yellow-700 mb-2">當偵測信心分數高於此值時自動標記為 Pending (不會自動 Approve，以確保安全)。</p>
               <input
                type="range"
                min="0.5"
                max="1.0"
                step="0.05"
                value={localConfig.autoApproveConfidence}
                onChange={(e) => handleChange('autoApproveConfidence', parseFloat(e.target.value))}
                className="w-full max-w-xs"
              />
              <span className="text-sm font-bold text-gray-700 ml-2">{localConfig.autoApproveConfidence}</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
};

export default Settings;
