import React, { useState, useEffect } from 'react';
import { PipelineItem, ItemStatus } from '../types';
import { Check, X, RefreshCw, Wand2, ArrowLeft, Image as ImageIcon, Code, FileText } from 'lucide-react';
import { generateGeminiDescription } from '../services/geminiService';

interface ReviewDetailProps {
  item: PipelineItem;
  onClose: () => void;
  onUpdateStatus: (id: string, status: ItemStatus, description: string) => void;
  geminiApiKey: string;
}

const ReviewDetail: React.FC<ReviewDetailProps> = ({ item, onClose, onUpdateStatus, geminiApiKey }) => {
  const [description, setDescription] = useState(item.description);
  const [activeTab, setActiveTab] = useState<'preview' | 'json' | 'metadata'>('preview');
  const [isGenerating, setIsGenerating] = useState(false);
  const [generationError, setGenerationError] = useState<string | null>(null);

  // Reset local state when item changes
  useEffect(() => {
    setDescription(item.description);
    setGenerationError(null);
  }, [item]);

  const handleGeminiRegenerate = async () => {
    if (!geminiApiKey) {
      alert("請先在設定中輸入 Gemini API Key (Please configure Gemini API Key in Settings)");
      return;
    }
    setIsGenerating(true);
    setGenerationError(null);
    try {
      const newDesc = await generateGeminiDescription(geminiApiKey, "", "請用繁體中文詳細描述這張圖片。");
      setDescription(newDesc);
    } catch (e) {
      setGenerationError("生成失敗，請稍後再試。");
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="flex flex-col h-full bg-white rounded-xl shadow-lg border border-gray-200 overflow-hidden animate-in slide-in-from-right duration-300">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
        <div className="flex items-center gap-3">
          <button onClick={onClose} className="p-2 hover:bg-gray-200 rounded-full text-gray-600 transition-colors">
            <ArrowLeft size={20} />
          </button>
          <div>
            <h2 className="text-lg font-bold text-gray-800">{item.filename}</h2>
            <p className="text-xs text-gray-500 font-mono">{item.id}</p>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => onUpdateStatus(item.id, ItemStatus.REJECTED, description)}
            className="flex items-center gap-2 px-4 py-2 bg-white border border-red-200 text-red-600 rounded-lg hover:bg-red-50 transition-colors"
          >
            <X size={18} />
            駁回 (Reject)
          </button>
          <button
            onClick={() => onUpdateStatus(item.id, ItemStatus.APPROVED, description)}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 shadow-md transition-colors"
          >
            <Check size={18} />
            核准 (Approve)
          </button>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* Left: Image Panel */}
        <div className="w-1/2 bg-gray-900 flex items-center justify-center p-6 relative">
          <img 
            src={item.thumbnailUrl} 
            alt={item.filename} 
            className="max-w-full max-h-full object-contain shadow-2xl rounded"
          />
          {/* Tag Overlay Visualization (Mock) */}
          <div className="absolute top-4 left-4 flex flex-wrap gap-2">
            {item.detection_raw?.objects.map((obj, idx) => (
              <span key={idx} className="bg-black/50 backdrop-blur-sm text-white text-xs px-2 py-1 rounded border border-white/20">
                {obj.label} ({Math.round(obj.confidence * 100)}%)
              </span>
            ))}
          </div>
        </div>

        {/* Right: Data Panel */}
        <div className="w-1/2 flex flex-col bg-white">
          {/* Tabs */}
          <div className="flex border-b border-gray-200">
            <button 
              onClick={() => setActiveTab('preview')}
              className={`flex-1 py-3 text-sm font-medium flex items-center justify-center gap-2 border-b-2 transition-colors ${activeTab === 'preview' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
            >
              <FileText size={16} /> 描述 (Description)
            </button>
            <button 
              onClick={() => setActiveTab('metadata')}
              className={`flex-1 py-3 text-sm font-medium flex items-center justify-center gap-2 border-b-2 transition-colors ${activeTab === 'metadata' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
            >
              <ImageIcon size={16} /> 中繼資料 (Metadata)
            </button>
            <button 
              onClick={() => setActiveTab('json')}
              className={`flex-1 py-3 text-sm font-medium flex items-center justify-center gap-2 border-b-2 transition-colors ${activeTab === 'json' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
            >
              <Code size={16} /> JSON
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-6">
            {activeTab === 'preview' && (
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                   <label className="block text-sm font-medium text-gray-700">圖片描述 (Image Description)</label>
                   <button 
                     onClick={handleGeminiRegenerate}
                     disabled={isGenerating}
                     className="text-xs flex items-center gap-1 text-purple-600 hover:text-purple-800 disabled:opacity-50"
                   >
                     {isGenerating ? <RefreshCw size={14} className="animate-spin" /> : <Wand2 size={14} />}
                     使用 Gemini 2.5 Flash 優化
                   </button>
                </div>
                
                {generationError && (
                   <div className="p-3 bg-red-50 text-red-600 text-xs rounded-md">{generationError}</div>
                )}

                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full h-64 p-4 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-800 leading-relaxed resize-none"
                  placeholder="輸入描述..."
                />
                <div className="flex gap-2">
                    <span className="text-xs px-2 py-1 bg-gray-100 rounded text-gray-600">Source: {isGenerating ? 'Generating...' : item.source || 'Ollama'}</span>
                    <span className="text-xs px-2 py-1 bg-gray-100 rounded text-gray-600">Tokens: {description.length} chars</span>
                </div>
              </div>
            )}

            {activeTab === 'metadata' && (
              <div className="space-y-4">
                 <div className="grid grid-cols-2 gap-4">
                    <div className="p-3 bg-gray-50 rounded-lg">
                        <p className="text-xs text-gray-500">Camera Model</p>
                        <p className="font-medium">{item.metadata.camera_model || 'N/A'}</p>
                    </div>
                    <div className="p-3 bg-gray-50 rounded-lg">
                        <p className="text-xs text-gray-500">Dimensions</p>
                        <p className="font-medium">{item.metadata.width} x {item.metadata.height}</p>
                    </div>
                    <div className="p-3 bg-gray-50 rounded-lg">
                        <p className="text-xs text-gray-500">ISO</p>
                        <p className="font-medium">{item.metadata.iso || 'Auto'}</p>
                    </div>
                    <div className="p-3 bg-gray-50 rounded-lg">
                        <p className="text-xs text-gray-500">Processing Time</p>
                        <p className="font-medium">{item.processingTimeMs?.toFixed(0)} ms</p>
                    </div>
                 </div>
              </div>
            )}

            {activeTab === 'json' && (
              <div className="bg-gray-900 rounded-lg p-4 overflow-x-auto">
                <pre className="text-xs text-green-400 font-mono">
                  {JSON.stringify(item.detection_raw, null, 2)}
                </pre>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReviewDetail;
