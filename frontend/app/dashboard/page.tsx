'use client';
import { useState } from 'react';

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"; // can include path like /ai-for-science

export default function Dashboard() {
  const [prompt, setPrompt] = useState('');
  const [output, setOutput] = useState('');
  const [latency, setLatency] = useState<number | null>(null);

  async function run() {
    const t0 = performance.now();
    const res = await fetch(`${API_URL}/api/v1/llm/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
    });
    const json = await res.json();
    setOutput(json.text ?? JSON.stringify(json));
    setLatency(Math.round(performance.now() - t0));
  }

  return (
    <main style={{ padding: 24, maxWidth: 720, margin: "0 auto" }}>
      <h1>Dashboard</h1>
      <textarea
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        rows={6}
        style={{ width: "100%", padding: 12 }}
        placeholder="Paste an abstract or question..."
      />
      <div style={{ marginTop: 12 }}>
        <button onClick={run}>Run</button>
      </div>
      {latency && <p>Latency: {latency}ms</p>}
      {output && <pre style={{ background: "#f5f5f5", padding: 12 }}>{output}</pre>}
    </main>
  );
}
