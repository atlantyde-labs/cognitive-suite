import React, { useState, useEffect } from 'react';
import {
    ArrowLeft,
    Download,
    Share2,
    GitPullRequest,
    Check,
    AlertTriangle,
    Info,
    ShieldAlert,
    Stars
} from 'lucide-react';

const ResultsView = ({ onBack }) => {
    const fullSummary = "El documento analiza la evolución estratégica del enclave local durante el ejercicio 2024. Se identifican tres pilares fundamentales de crecimiento y una reducción del 15% en los costes de latencia. No se han detectado brechas de seguridad críticas, aunque se sugiere reforzar la política de rotación de claves en el módulo de GitOps.";
    const [summary, setSummary] = useState("");
    const [showItems, setShowItems] = useState(false);

    useEffect(() => {
        let i = 0;
        const interval = setInterval(() => {
            setSummary(fullSummary.slice(0, i));
            i++;
            if (i > fullSummary.length) {
                clearInterval(interval);
                setShowItems(true);
            }
        }, 15);
        return () => clearInterval(interval);
    }, []);

    return (
        <div className="p-8 space-y-8 animate-in zoom-in-95 duration-500">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <button
                        onClick={onBack}
                        className="p-2 rounded-xl bg-slate-800 text-slate-400 hover:text-white hover:bg-slate-700 transition-all font-bold"
                    >
                        <ArrowLeft size={20} />
                    </button>
                    <div>
                        <h1 className="text-2xl font-bold text-white tracking-tight">Análisis: Reporte_Anual_2025.pdf</h1>
                        <p className="text-slate-500 text-sm font-medium">Procesado en Enclave Local • ID: #COG-9921</p>
                    </div>
                </div>
                <div className="flex gap-3">
                    <button className="flex items-center gap-2 px-6 py-3 rounded-xl bg-slate-800 text-slate-300 font-bold hover:bg-slate-700 transition-all active:scale-95 shadow-lg border border-slate-700/50">
                        <Download size={18} />
                        Exportar
                    </button>
                    <button className="flex items-center gap-2 px-6 py-3 rounded-xl bg-blue-600 text-white font-bold hover:bg-blue-500 transition-all shadow-xl shadow-blue-500/20 active:scale-95">
                        <GitPullRequest size={18} />
                        Crear Issue GitOps
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-8">
                    {/* Resumen Automático */}
                    <div className="glass-morphism rounded-3xl p-8 space-y-4 border-t-2 border-blue-500/30">
                        <h3 className="text-xl font-bold text-white flex items-center gap-2">
                            <Stars className="text-blue-400" size={24} />
                            Resumen Ejecutivo Cognitivo
                        </h3>
                        <div className="min-h-[100px] relative">
                            <p className="text-slate-200 leading-relaxed text-lg font-medium">
                                {summary}
                                <span className="inline-block w-1.5 h-5 bg-blue-500 ml-1 animate-pulse align-middle"></span>
                            </p>
                        </div>
                    </div>

                    {/* Clasificaciones Semánticas */}
                    <div className={`grid grid-cols-1 md:grid-cols-2 gap-6 transition-all duration-700 ${showItems ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
                        <div className="glass-morphism rounded-3xl p-6 border-l-4 border-amber-500 hover:bg-slate-800/50 transition-colors">
                            <h4 className="text-amber-500 font-bold flex items-center gap-2 mb-4">
                                <AlertTriangle size={18} />
                                Riesgos Detectados
                            </h4>
                            <ul className="space-y-3">
                                <li className="text-sm text-slate-300 flex items-start gap-3">
                                    <div className="w-2 h-2 rounded-full bg-amber-500 mt-1.5 flex-shrink-0 shadow-lg shadow-amber-500/20"></div>
                                    Dependencia excesiva de un solo nodo en la región sur.
                                </li>
                                <li className="text-sm text-slate-300 flex items-start gap-3">
                                    <div className="w-2 h-2 rounded-full bg-amber-500 mt-1.5 flex-shrink-0 shadow-lg shadow-amber-500/20"></div>
                                    Ambigüedad en los términos de la cláusula de indemnización.
                                </li>
                            </ul>
                        </div>
                        <div className="glass-morphism rounded-3xl p-6 border-l-4 border-blue-500 hover:bg-slate-800/50 transition-colors">
                            <h4 className="text-blue-500 font-bold flex items-center gap-2 mb-4">
                                <ShieldAlert size={18} />
                                Cumplimiento (Compliance)
                            </h4>
                            <ul className="space-y-3">
                                <li className="text-sm text-slate-300 flex items-start gap-3">
                                    <div className="w-2 h-2 rounded-full bg-blue-500 mt-1.5 flex-shrink-0 shadow-lg shadow-blue-500/20"></div>
                                    Alineado con OPA Policy v2.4.
                                </li>
                                <li className="text-sm text-slate-300 flex items-start gap-3">
                                    <div className="w-2 h-2 rounded-full bg-blue-500 mt-1.5 flex-shrink-0 shadow-lg shadow-blue-500/20"></div>
                                    Validación de identidad local verificada.
                                </li>
                            </ul>
                        </div>
                    </div>

                    {/* Transcript / Extractos */}
                    <div className={`glass-morphism rounded-3xl p-8 transition-all duration-1000 delay-300 ${showItems ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
                        <h3 className="text-xl font-bold text-white mb-6">Mapeo de Evidencias</h3>
                        <div className="space-y-4">
                            {[
                                { text: "La arquitectura local garantiza que los datos no abandonen el perímetro del enclave físico.", cat: "Seguridad / Soberanía", score: 0.98 },
                                { text: "Se recomienda la migración de los microservicios de análisis a instancias con mayor GPU compartida.", cat: "Operaciones", score: 0.85 },
                                { text: "Los plazos de entrega se han visto afectados por la escasez de componentes semiconductores.", cat: "Logística", score: 0.72 }
                            ].map((item, i) => (
                                <div key={i} className="group p-5 rounded-2xl bg-slate-900/40 hover:bg-slate-800 transition-all border border-slate-800/50 hover:border-blue-500/30">
                                    <p className="text-slate-300 italic mb-4 text-base font-medium">"{item.text}"</p>
                                    <div className="flex items-center justify-between">
                                        <span className="px-3 py-1 rounded-lg bg-blue-500/10 text-blue-400 text-xs font-bold ring-1 ring-blue-500/20 uppercase tracking-widest">
                                            {item.cat}
                                        </span>
                                        <div className="flex items-center gap-3">
                                            <div className="w-32 h-2 bg-slate-800 rounded-full overflow-hidden">
                                                <div className="h-full bg-gradient-to-r from-blue-600 to-indigo-400 transition-all duration-1000 delay-500" style={{ width: showItems ? `${item.score * 100}%` : '0%' }}></div>
                                            </div>
                                            <span className="text-xs text-slate-500 font-bold">{(item.score * 100).toFixed(0)}% Conf.</span>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                <div className="space-y-8">
                    {/* Entidades Detectadas */}
                    <div className={`glass-morphism rounded-3xl p-6 transition-all duration-700 delay-500 ${showItems ? 'opacity-100 scale-100' : 'opacity-0 scale-95'}`}>
                        <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                            <Info size={18} className="text-blue-400" />
                            Entidades Clave
                        </h3>
                        <div className="space-y-6">
                            <div>
                                <span className="text-xs font-bold text-slate-600 uppercase tracking-widest block mb-3">Organizaciones</span>
                                <div className="flex flex-wrap gap-2">
                                    <span className="px-4 py-2 rounded-xl bg-indigo-500/10 text-indigo-400 text-sm font-bold border border-indigo-500/10">Atlantyqa Labs</span>
                                    <span className="px-4 py-2 rounded-xl bg-indigo-500/10 text-indigo-400 text-sm font-bold border border-indigo-500/10">EU Sovereign Fund</span>
                                </div>
                            </div>
                            <div>
                                <span className="text-xs font-bold text-slate-600 uppercase tracking-widest block mb-3">Fechas & Eventos</span>
                                <div className="flex flex-wrap gap-2">
                                    <span className="px-4 py-2 rounded-xl bg-green-500/10 text-green-400 text-sm font-bold border border-green-500/10">Final Q4 2024</span>
                                    <span className="px-4 py-2 rounded-xl bg-green-500/10 text-green-400 text-sm font-bold border border-green-500/10">Marzo 15, 2025</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Timeline de Acciones GitOps */}
                    <div className={`glass-morphism rounded-3xl p-6 transition-all duration-700 delay-700 ${showItems ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4'}`}>
                        <h3 className="text-lg font-bold text-white mb-6">Estado de Persistencia</h3>
                        <div className="relative border-l-2 border-slate-800 ml-2 pl-6 space-y-8">
                            <div className="relative">
                                <div className="absolute -left-[33px] top-1 w-3.5 h-3.5 rounded-full bg-green-500 ring-4 ring-green-500/20"></div>
                                <h4 className="text-sm font-bold text-slate-200 uppercase tracking-tight">Análisis Finalizado</h4>
                                <p className="text-xs text-slate-500 mt-1 font-medium">Sincronización completa con enclave local.</p>
                            </div>
                            <div className="relative">
                                <div className="absolute -left-[33px] top-1 w-3.5 h-3.5 rounded-full bg-blue-500 animate-pulse ring-4 ring-blue-500/20"></div>
                                <h4 className="text-sm font-bold text-blue-400 uppercase tracking-tight">PR Automático</h4>
                                <p className="text-xs text-slate-400 mt-1 font-medium">Generando Pull Request en rama efímera...</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ResultsView;
