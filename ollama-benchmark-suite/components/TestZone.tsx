import React, { useState, useRef } from 'react';
import { BenchmarkCategory, EvaluationResponse } from '../types';
import { generateChallenge, evaluateSubmission } from '../services/geminiService';
import { Play, ClipboardCopy, Loader2, CheckCircle2, UploadCloud, Image as ImageIcon } from 'lucide-react';

interface TestZoneProps {
  category: BenchmarkCategory;
  categoryInfo: any;
  onComplete: (score: number, details: EvaluationResponse) => void;
}

export const TestZone: React.FC<TestZoneProps> = ({ category, categoryInfo, onComplete }) => {
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [generatedPrompt, setGeneratedPrompt] = useState('');
  const [userOutput, setUserOutput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);

  // Vision specific refs
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleGenerate = async () => {
    setIsLoading(true);
    try {
      if (category === BenchmarkCategory.VISION) {
         // For vision, we skip generation text initially, user uploads first
         setStep(2);
      } else {
        const challenge = await generateChallenge(category);
        setGeneratedPrompt(challenge);
        setStep(2);
      }
    } catch (e) {
      alert("Failed to generate test case. Check API Key.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64String = reader.result as string;
        // Remove data url prefix for Gemini API usage later if needed, 
        // but for display we keep it. We usually strip it just before sending.
        setUploadedImage(base64String);
        
        // After upload, we generate a prompt suitable for vision
        setIsLoading(true);
        generateChallenge(category).then(prompt => {
            setGeneratedPrompt(prompt);
            setIsLoading(false);
        });
      };
      reader.readAsDataURL(file);
    }
  };

  const handleEvaluate = async () => {
    if (!userOutput.trim()) return;
    setIsLoading(true);
    try {
      // Strip base64 header for API if image exists
      const cleanImage = uploadedImage ? uploadedImage.split(',')[1] : undefined;
      
      const result = await evaluateSubmission(category, generatedPrompt, userOutput, cleanImage);
      onComplete(result.score, result);
      setStep(3);
    } catch (e) {
      alert("Evaluation failed.");
    } finally {
      setIsLoading(false);
    }
  };

  const resetTest = () => {
    setStep(1);
    setGeneratedPrompt('');
    setUserOutput('');
    setUploadedImage(null);
  };

  const copyToClipboard = () => {
    navigator.clipboard.writeText(generatedPrompt);
  };

  return (
    <div className="bg-slate-800 rounded-xl p-6 border border-slate-700 shadow-lg min-h-[500px] flex flex-col">
      <div className="flex items-center gap-3 mb-6 pb-4 border-b border-slate-700">
        <categoryInfo.icon className="w-6 h-6 text-emerald-400" />
        <h2 className="text-xl font-bold text-white">{categoryInfo.label} Benchmark</h2>
      </div>

      <div className="flex-1">
        {step === 1 && (
          <div className="flex flex-col items-center justify-center h-full space-y-6 text-center">
            <div className="max-w-md text-slate-400">
              <p className="mb-4">{categoryInfo.description}</p>
              <p className="text-sm">Click below to generate a randomized, high-complexity test case for your local Ollama model.</p>
            </div>
            
            {category === BenchmarkCategory.VISION ? (
               <div className="w-full max-w-sm">
                 <label className="flex flex-col items-center justify-center w-full h-32 border-2 border-slate-600 border-dashed rounded-lg cursor-pointer bg-slate-700 hover:bg-slate-600 transition">
                    <div className="flex flex-col items-center justify-center pt-5 pb-6">
                        <UploadCloud className="w-8 h-8 mb-3 text-emerald-400" />
                        <p className="mb-2 text-sm text-slate-300">Upload Test Image</p>
                    </div>
                    <input ref={fileInputRef} type="file" className="hidden" accept="image/*" onChange={handleImageUpload} />
                </label>
               </div>
            ) : (
                <button
                onClick={handleGenerate}
                disabled={isLoading}
                className="flex items-center gap-2 px-6 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-semibold rounded-lg transition-all transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? <Loader2 className="animate-spin" /> : <Play size={20} />}
                Generate Test Case
              </button>
            )}
          </div>
        )}

        {step === 2 && (
          <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
             {uploadedImage && (
                <div className="mb-4 p-2 bg-slate-900 rounded border border-slate-700 flex justify-center">
                    <img src={uploadedImage} alt="Test Subject" className="max-h-48 rounded" />
                </div>
             )}

            <div className="space-y-2">
              <div className="flex justify-between items-center text-sm text-slate-400">
                <span className="font-mono">PROMPT (Input to Ollama)</span>
                <button onClick={copyToClipboard} className="hover:text-white flex items-center gap-1">
                  <ClipboardCopy size={14} /> Copy
                </button>
              </div>
              <div className="bg-slate-900 p-4 rounded-lg border border-slate-700 font-mono text-sm text-emerald-100 whitespace-pre-wrap">
                {generatedPrompt || (isLoading ? "Analyzing image to generate prompt..." : "Prompt ready.")}
              </div>
            </div>

            <div className="space-y-2">
              <span className="text-sm text-slate-400 font-mono">MODEL RESPONSE (Paste from Ollama)</span>
              <textarea
                value={userOutput}
                onChange={(e) => setUserOutput(e.target.value)}
                placeholder="Paste the output from your local model here..."
                className="w-full h-40 bg-slate-900 border border-slate-700 rounded-lg p-4 text-slate-200 focus:ring-2 focus:ring-emerald-500 focus:border-transparent outline-none resize-none font-mono text-sm"
              />
            </div>

            <button
              onClick={handleEvaluate}
              disabled={isLoading || !userOutput || !generatedPrompt}
              className="w-full py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition flex justify-center items-center gap-2 disabled:opacity-50"
            >
              {isLoading ? (
                <>
                  <Loader2 className="animate-spin" /> Judging...
                </>
              ) : (
                <>
                  <CheckCircle2 size={20} /> Evaluate Performance
                </>
              )}
            </button>
          </div>
        )}

        {step === 3 && (
            <div className="flex flex-col items-center justify-center h-full text-center space-y-4">
                 <div className="w-16 h-16 bg-emerald-500/20 text-emerald-400 rounded-full flex items-center justify-center mb-2">
                    <CheckCircle2 size={32} />
                 </div>
                 <h3 className="text-2xl font-bold text-white">Evaluation Complete</h3>
                 <p className="text-slate-400 max-w-xs">The result has been recorded on the dashboard.</p>
                 <button 
                    onClick={resetTest}
                    className="px-6 py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-white transition"
                 >
                    Run Another Test
                 </button>
            </div>
        )}
      </div>
    </div>
  );
};
