import { GoogleGenAI, Schema, Type } from "@google/genai";
import { BenchmarkCategory, EvaluationResponse } from "../types";

const apiKey = process.env.API_KEY || '';
const ai = new GoogleGenAI({ apiKey });

// Helper to get enum key for model selection if needed, but we default to 2.5-flash for speed/cost or 3-pro for complex judging
const JUDGE_MODEL = 'gemini-2.5-flash'; 

const EVALUATION_SCHEMA: Schema = {
  type: Type.OBJECT,
  properties: {
    score: {
      type: Type.NUMBER,
      description: "A score from 1 to 5, where 5 is perfect performance.",
    },
    reasoning: {
      type: Type.STRING,
      description: "A concise explanation of why this score was given, citing specific strengths or errors.",
    },
    breakdown: {
      type: Type.OBJECT,
      description: "Key-value pairs of specific metrics and their scores (1-5).",
      properties: {
        accuracy: { type: Type.NUMBER },
        clarity: { type: Type.NUMBER },
        creativity: { type: Type.NUMBER },
        completeness: { type: Type.NUMBER },
      }
    }
  },
  required: ["score", "reasoning", "breakdown"],
};

export const generateChallenge = async (category: BenchmarkCategory): Promise<string> => {
  let sysInstruction = "You are a rigid benchmark generator for Large Language Models.";
  let userPrompt = "";

  switch (category) {
    case BenchmarkCategory.REASONING:
      userPrompt = "Generate a difficult multi-hop logic puzzle or a chain-of-thought math word problem. Do not provide the answer, just the question.";
      break;
    case BenchmarkCategory.CODING:
      userPrompt = "Generate a prompt asking for a specific Python or TypeScript function with a slightly complex constraint (e.g., specific time complexity or handling edge cases). Do not write the code.";
      break;
    case BenchmarkCategory.GENERAL:
      userPrompt = "Generate a prompt for a creative writing task (e.g., write a poem about a specific obscure topic) or a request to summarize a complex concept in a specific style.";
      break;
    case BenchmarkCategory.EMBEDDING:
      userPrompt = "Generate a 'Semantic Odd One Out' task. List 4 sentences, 3 of which are semantically related and 1 is subtly different. Ask the model to identify the outlier and explain why. Do not reveal the answer.";
      break;
    case BenchmarkCategory.VISION:
      userPrompt = "Suggest a complex prompt for a Vision model assuming the user has uploaded a photo of a chaotic workspace. The prompt should ask for specific spatial reasoning (e.g., 'What is to the left of the laptop and how might it be used?').";
      break;
  }

  try {
    const response = await ai.models.generateContent({
      model: JUDGE_MODEL,
      contents: userPrompt,
      config: {
        systemInstruction: sysInstruction,
        temperature: 0.9, 
      }
    });
    return response.text || "Failed to generate test case.";
  } catch (error) {
    console.error("Gemini Generation Error:", error);
    throw error;
  }
};

export const evaluateSubmission = async (
  category: BenchmarkCategory,
  testCase: string,
  modelOutput: string,
  imageData?: string // Base64
): Promise<EvaluationResponse> => {
  
  const systemInstruction = `You are an expert AI Benchmark Judge. 
  You will evaluate the output of a local LLM against a specific test case.
  Category: ${category}.
  
  Scoring Rubric (1-5 Stars):
  1: Completely incorrect, hallucinated, or irrelevant.
  2: Major errors, missed constraints, or poor coherence.
  3: Acceptable but average. Missed nuance or slightly inefficient.
  4: Good quality, accurate, and follows instructions well.
  5: Exceptional. Perfectly accurate, concise, elegant, or insightful.
  
  Return the result in strict JSON format.`;

  const parts: any[] = [];
  
  // If it's a vision task, the Judge needs to see the image to judge the text description of it.
  if (category === BenchmarkCategory.VISION && imageData) {
    parts.push({
      inlineData: {
        mimeType: 'image/jpeg', // Assuming jpeg for simplicity in this demo context
        data: imageData
      }
    });
    parts.push({
      text: `Original Prompt: ${testCase}\n\nModel Answer to Evaluate: ${modelOutput}\n\nTask: Verify if the Model Answer accurately describes the image and answers the prompt.`
    });
  } else {
    parts.push({
      text: `Test Prompt: "${testCase}"\n\nModel Output: "${modelOutput}"\n\nEvaluate this output based on correctness, style, and constraints.`
    });
  }

  try {
    const response = await ai.models.generateContent({
      model: JUDGE_MODEL,
      contents: { parts },
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        responseSchema: EVALUATION_SCHEMA,
      }
    });

    const text = response.text || "{}";
    return JSON.parse(text) as EvaluationResponse;
  } catch (error) {
    console.error("Gemini Evaluation Error:", error);
    throw new Error("Failed to evaluate submission.");
  }
};
