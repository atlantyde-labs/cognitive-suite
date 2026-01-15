import React from 'react';
import {
    FileText,
    CheckCircle,
    AlertCircle,
    GitPullRequest,
    TrendingUp,
    Activity,
    Clock
} from 'lucide-react';

const StatCard = ({ icon: Icon, label, value, trend, color }) => (
    <div className="glass-morphism p-6 rounded-2xl flex flex-col gap-2">
        <div className="flex items-center justify-between">
            <div className={`p-2 rounded-lg bg-${color}-500/20 text-${color}-400`}>
                <Icon size={24} />
            </div>
            <span className={`text-xs font-semibold px-2 py-1 rounded bg-green-500/10 text-green-400`}>
                {trend}
            </span>
        </div>
        <div className="mt-4">
            <p className="text-slate-400 text-sm font-medium">{label}</p>
            <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
        </div>
    </div>
);

const Dashboard = () => {
    const recentDocs = [
        { id: 1, name: 'reporte_anual_2025.pdf', status: 'Procesado', time: 'hace 10 min', type: 'Análisis' },
        { id: 2, name: 'contrato_servicios_v2.docx', status: 'En cola', time: 'hace 15 min', type: 'Legal' },
        { id: 3, name: 'infraestructura_enclave.yaml', status: 'Error', time: 'hace 1 h', type: 'GitOps' },
    ];

    return (
        <div className="p-8 space-y-8 animate-in fade-in duration-500">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-white tracking-tight">Dashboard Overview</h1>
                    <p className="text-slate-400 mt-1">Bienvenido de nuevo. Aquí tienes un resumen de la actividad local.</p>
                </div>
                <div className="flex gap-3">
                    <div className="flex items-center gap-2 px-4 py-2 bg-green-500/10 text-green-400 rounded-full border border-green-500/20 text-sm font-medium">
                        <Activity size={16} />
                        Sistema: Operativo
                    </div>
                    <div className="flex items-center gap-2 px-4 py-2 bg-blue-500/10 text-blue-400 rounded-full border border-blue-500/20 text-sm font-medium">
                        <Clock size={16} />
                        Uptime: 14d 2h
                    </div>
                </div>
            </div>

            {/* Grid de KPIs */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard icon={FileText} label="Docs Procesados" value="1,284" trend="+12%" color="blue" />
                <StatCard icon={CheckCircle} label="Análisis Exitosos" value="98.2%" trend="+0.5%" color="green" />
                <StatCard icon={GitPullRequest} label="PRs Automáticos" value="456" trend="+8%" color="purple" />
                <StatCard icon={AlertCircle} label="Incidentes" value="3" trend="-2%" color="red" />
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Gráfico Placeholder */}
                <div className="lg:col-span-2 glass-morphism rounded-3xl p-8 h-[400px] flex flex-col">
                    <div className="flex items-center justify-between mb-8">
                        <h3 className="text-xl font-bold text-white">Análisis por Categoría</h3>
                        <button className="text-blue-400 text-sm font-medium hover:underline">Ver detalles</button>
                    </div>
                    <div className="flex-1 flex items-end gap-4 px-4 overflow-hidden">
                        {[60, 45, 80, 55, 90, 70, 85].map((h, i) => (
                            <div key={i} className="flex-1 bg-gradient-to-t from-blue-600 to-indigo-400 rounded-t-lg transition-all duration-1000" style={{ height: `${h}%` }}></div>
                        ))}
                    </div>
                    <div className="flex justify-between mt-4 text-xs text-slate-500 font-medium px-4">
                        <span>Riesgo</span>
                        <span>Legal</span>
                        <span>Finanzas</span>
                        <span>Infra</span>
                        <span>UX</span>
                        <span>HR</span>
                        <span>Gov</span>
                    </div>
                </div>

                {/* Últimos Documentos */}
                <div className="glass-morphism rounded-3xl p-8">
                    <h3 className="text-xl font-bold text-white mb-6">Últimos Documentos</h3>
                    <div className="space-y-4">
                        {recentDocs.map((doc) => (
                            <div key={doc.id} className="flex items-center justify-between p-4 rounded-xl bg-slate-800/40 hover:bg-slate-800 transition-colors border border-slate-700/50">
                                <div className="flex items-center gap-3">
                                    <div className={`p-2 rounded-lg ${doc.status === 'Procesado' ? 'text-green-400 bg-green-400/10' :
                                            doc.status === 'Error' ? 'text-red-400 bg-red-400/10' : 'text-amber-400 bg-amber-400/10'
                                        }`}>
                                        <FileText size={20} />
                                    </div>
                                    <div>
                                        <h4 className="text-sm font-semibold text-slate-200 truncate max-w-[120px]">{doc.name}</h4>
                                        <p className="text-xs text-slate-500">{doc.time}</p>
                                    </div>
                                </div>
                                <span className={`text-[10px] font-bold px-2 py-1 rounded tracking-wider uppercase ${doc.status === 'Procesado' ? 'text-green-400 border border-green-400/20' :
                                        doc.status === 'Error' ? 'text-red-400 border border-red-400/20' : 'text-amber-400 border border-amber-400/20'
                                    }`}>
                                    {doc.status}
                                </span>
                            </div>
                        ))}
                    </div>
                    <button className="w-full mt-8 py-3 rounded-xl border border-slate-700 text-slate-300 font-medium hover:bg-slate-800 transition-colors text-sm">
                        Ver todo el historial
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
