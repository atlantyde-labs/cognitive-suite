import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import Dashboard from './components/Dashboard';
import IngestForm from './components/IngestForm';
import ResultsView from './components/ResultsView';
import GitOpsPanel from './components/GitOpsPanel';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'analyze':
        return <IngestForm onProcess={(view) => setActiveTab(view)} />;
      case 'results':
        return <ResultsView onBack={() => setActiveTab('analyze')} />;
      case 'gitops':
        return <GitOpsPanel />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="flex bg-slate-950 min-h-screen text-slate-200">
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      <main className="flex-1 ml-64 min-h-screen">
        <header className="h-16 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md sticky top-0 z-10 flex items-center justify-end px-8">
          <div className="flex items-center gap-4 text-xs font-semibold uppercase tracking-widest text-slate-500">
            <span className="flex items-center gap-1">
              <div className="w-1.5 h-1.5 rounded-full bg-blue-500"></div>
              Enclave: Local-Primary
            </span>
            <span className="flex items-center gap-1">
              <div className="w-1.5 h-1.5 rounded-full bg-green-500"></div>
              Status: Verified
            </span>
          </div>
        </header>

        <div className="max-w-[1600px] mx-auto">
          {renderContent()}
        </div>
      </main>
    </div>
  );
}

export default App;
