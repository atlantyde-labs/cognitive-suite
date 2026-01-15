import React, { useState } from 'react';
import {
    GitBranch,
    GitPullRequest,
    History,
    ShieldCheck,
    RefreshCcw,
    ExternalLink,
    Lock,
    Terminal,
    Settings,
    CheckCircle2,
    Loader2
} from 'lucide-react';

const GitOpsPanel = () => {
    const [isSyncing, setIsSyncing] = useState(false);
    const [showSuccess, setShowSuccess] = useState(false);

    const repos = [
        { name: 'cognitive-suite-data', branch: 'main', status: 'Synced', lastCommit: '7a2b5c1', time: '12 min ago' },
        { name: 'analysis-results-archive', branch: 'feat/q1-reports', status: 'Pending PR', lastCommit: '9d4f21a', time: '2h ago' },
    ];

    const handleSync = () => {
        setIsSyncing(true);
        setTimeout(() => {
            setIsSyncing(false);
            setShowSuccess(true);
            setTimeout(() => setShowSuccess(false), 3000);
        }, 3000);
    };

    return (
        <div className="p-8 space-y-8 animate-in slide-in-from-right duration-500 relative">
            {showSuccess && (
                <div className="fixed top-24 right-8 z-50 animate-in slide-in-from-right duration-500">
                    <div className="flex items-center gap-3 bg-green-500 text-white px-6 py-4 rounded-2xl shadow-2xl shadow-green-500/20 font-bold border border-green-400">
                        <CheckCircle2 size={24} />
                        <div>
                            <p>Sincronización Exitosa</p>
                            <p className="text-[10px] opacity-80 font-medium tracking-wide">Infrastructure is up to date</p>
                        </div>
                    </div>
                </div>
            )}

            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-white">GitOps Control Center</h1>
                    <p className="text-slate-400 mt-1">Gestión de persistencia y trazabilidad basada en Git.</p>
                </div>
                <button
                    onClick={handleSync}
                    disabled={isSyncing}
                    className={`flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl transition-all shadow-lg shadow-blue-500/20 font-bold active:scale-95 ${isSyncing ? 'opacity-70 cursor-wait' : ''}`}
                >
                    <RefreshCcw size={18} className={isSyncing ? 'animate-spin' : ''} />
                    {isSyncing ? 'Sincronizando...' : 'Forzar Sincronización'}
                </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Repositories */}
                <div className="glass-morphism rounded-3xl p-8 space-y-6">
                    <h3 className="text-xl font-bold text-white flex items-center gap-2">
                        <GitBranch size={20} className="text-blue-400" />
                        Repositorios Vinculados
                    </h3>
                    <div className="space-y-4">
                        {repos.map((repo, i) => (
                            <div key={i} className="p-5 rounded-2xl bg-slate-800/40 border border-slate-700/50 hover:border-blue-500/30 transition-all group">
                                <div className="flex items-center justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="p-2 rounded-lg bg-slate-700 text-slate-300">
                                            <Lock size={16} />
                                        </div>
                                        <div>
                                            <h4 className="font-bold text-slate-200 group-hover:text-white transition-colors">{repo.name}</h4>
                                            <p className="text-xs text-slate-500 flex items-center gap-1">
                                                <GitBranch size={12} /> {repo.branch}
                                            </p>
                                        </div>
                                    </div>
                                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${repo.status === 'Synced' ? 'bg-green-500/10 text-green-400 border border-green-500/20' : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                                        }`}>
                                        {repo.status}
                                    </span>
                                </div>
                                <div className="flex items-center justify-between text-xs font-medium border-t border-slate-700 pt-3 mt-3">
                                    <span className="text-slate-400 bg-slate-900 px-2 py-1 rounded">commit: {repo.lastCommit}</span>
                                    <span className="text-slate-500">{repo.time}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                    <button className="w-full py-3 rounded-xl border border-dashed border-slate-700 text-slate-500 hover:text-slate-300 hover:border-slate-500 transition-all text-sm font-medium">
                        + Vincular Nuevo Repositorio
                    </button>
                </div>

                {/* Políticas de OPA / Conftest */}
                <div className="space-y-8">
                    <div className="glass-morphism rounded-3xl p-8 bg-gradient-to-br from-slate-900 to-indigo-950/30">
                        <h3 className="text-xl font-bold text-white flex items-center gap-2 mb-6">
                            <ShieldCheck size={20} className="text-indigo-400" />
                            Políticas de Enclave (OPA)
                        </h3>
                        <div className="space-y-4">
                            <div className="flex items-center justify-between p-4 rounded-xl bg-slate-800/50">
                                <span className="text-sm text-slate-300 font-medium">Restricción de Exportación</span>
                                <span className="text-xs font-bold text-green-400 uppercase">Habilitado</span>
                            </div>
                            <div className="flex items-center justify-between p-4 rounded-xl bg-slate-800/50">
                                <span className="text-sm text-slate-300 font-medium">Validación de Esquema YAML</span>
                                <span className="text-xs font-bold text-green-400 uppercase">Habilitado</span>
                            </div>
                            <div className="flex items-center justify-between p-4 rounded-xl bg-slate-800/50">
                                <span className="text-sm text-slate-300 font-medium">Auto-PR en Resultados Sensibles</span>
                                <span className="text-xs font-bold text-amber-500 uppercase">Manual</span>
                            </div>
                        </div>
                        <button className="w-full mt-6 flex items-center justify-center gap-2 py-3 text-indigo-400 font-bold text-sm bg-indigo-500/10 rounded-xl hover:bg-indigo-500/20 transition-all">
                            <Settings size={16} />
                            Configurar Reglas
                        </button>
                    </div>

                    <div className="glass-morphism rounded-3xl p-8 border-l-4 border-blue-500">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="font-bold text-white flex items-center gap-2">
                                <Terminal size={18} className="text-blue-400" />
                                Último PR Generado
                            </h3>
                            <ExternalLink size={16} className="text-slate-500 cursor-pointer hover:text-white" />
                        </div>
                        <div className="bg-slate-950 rounded-xl p-4 font-mono text-xs text-blue-400 border border-slate-800">
                            <div className="flex gap-2">
                                <span className="text-slate-600">analysis-bot:</span>
                                <span>git commit -m "feat: sem-results-0115"</span>
                            </div>
                            <div className="flex gap-2">
                                <span className="text-slate-600">analysis-bot:</span>
                                <span>gh pr create --title "Automatic Analysis Q1"</span>
                            </div>
                            <div className="mt-2 text-green-500">
                                ✓ Pull Request #42 Created successfully.
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default GitOpsPanel;
