import React, { useState, useEffect } from 'react';
import {
    Upload,
    File,
    Tag,
    Layers,
    Send,
    X,
    Loader2,
    CheckCircle2,
    Search,
    ChevronRight,
    Lock,
    ShieldCheck
} from 'lucide-react';

const IngestForm = ({ onProcess }) => {
    const [dragActive, setDragActive] = useState(false);
    const [isProcessing, setIsProcessing] = useState(false);
    const [progress, setProgress] = useState(0);
    const [logStep, setLogStep] = useState(0);

    const logs = [
        "Iniciando worker de ingesta local...",
        "Validando integridad del documento...",
        "Fragmentando contenido (Chunking v2)...",
        "Generando embeddings vectoriales...",
        "Consultando base de conocimiento interna...",
        "Ejecutando motor de análisis semántico...",
        "Validando políticas de privacidad (Local-First)...",
        "Generando resumen cognitivo final..."
    ];

    useEffect(() => {
        let interval;
        if (isProcessing) {
            interval = setInterval(() => {
                setProgress(prev => {
                    if (prev >= 100) {
                        clearInterval(interval);
                        setTimeout(() => onProcess('results'), 500);
                        return 100;
                    }
                    return prev + 1.25;
                });

                setLogStep(prev => (prev < logs.length - 1 ? prev + 1 : prev));
            }, 400);
        }
        return () => clearInterval(interval);
    }, [isProcessing, onProcess]);

    const handleDrag = (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (e.type === "dragenter" || e.type === "dragover") {
            setDragActive(true);
        } else if (e.type === "dragleave") {
            setDragActive(false);
        }
    };

    const handleStart = () => {
        setIsProcessing(true);
    };

    return (
        <div className="p-8 max-w-4xl mx-auto space-y-8 animate-in slide-in-from-bottom duration-500">
            {isProcessing && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 backdrop-blur-xl animate-in fade-in duration-300">
                    <div className="max-w-md w-full p-8 glass-morphism rounded-[2rem] border-blue-500/30 shadow-2xl shadow-blue-500/10 space-y-8">
                        <div className="flex flex-col items-center text-center space-y-4">
                            <div className="relative">
                                <div className="absolute inset-0 rounded-full bg-blue-500/20 animate-ping"></div>
                                <div className="relative w-20 h-20 rounded-full border-4 border-slate-800 border-t-blue-500 animate-spin"></div>
                                <div className="absolute inset-0 flex items-center justify-center">
                                    <Search size={24} className="text-blue-400" />
                                </div>
                            </div>
                            <div>
                                <h2 className="text-2xl font-bold text-white">Analizando en Enclave</h2>
                                <p className="text-slate-400 text-sm mt-1">Procesando semánticamente en infraestructura local</p>
                            </div>
                        </div>

                        <div className="space-y-3">
                            <div className="flex justify-between text-xs font-bold tracking-wider uppercase text-slate-500">
                                <span>Progreso del Motor</span>
                                <span className="text-blue-400">{Math.round(progress)}%</span>
                            </div>
                            <div className="h-2 w-full bg-slate-800 rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-blue-500 transition-all duration-300 ease-out"
                                    style={{ width: `${progress}%` }}
                                ></div>
                            </div>
                        </div>

                        <div className="bg-slate-900/80 rounded-2xl p-4 font-mono text-[10px] space-y-2 h-32 overflow-hidden border border-slate-800">
                            {logs.slice(0, logStep + 1).map((log, i) => (
                                <div key={i} className="flex gap-2 items-start text-blue-400/80 animate-in slide-in-from-left duration-300">
                                    <span className="text-slate-600">[{new Date().toLocaleTimeString([], { hour12: false })}]</span>
                                    <span className={i === logStep ? "text-blue-400 font-bold" : ""}>
                                        {i === logStep ? "> " : "✓ "}{log}
                                    </span>
                                </div>
                            ))}
                        </div>

                        <div className="flex items-center gap-2 justify-center text-xs text-slate-500">
                            <Lock size={12} />
                            <span>Protegido por políticas de Digital Sovereignty</span>
                        </div>
                    </div>
                </div>
            )}

            <div>
                <h1 className="text-3xl font-bold text-white">Ingesta Multimodal</h1>
                <p className="text-slate-400 mt-1">Sube documentos o pega contenido estructurado para iniciar el análisis semántico.</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div className="space-y-6">
                    <div
                        className={`relative h-64 border-2 border-dashed rounded-3xl flex flex-col items-center justify-center transition-all duration-300 ${dragActive ? 'border-blue-500 bg-blue-500/10' : 'border-slate-700 bg-slate-800/40 hover:border-slate-500'
                            }`}
                        onDragEnter={handleDrag}
                        onDragLeave={handleDrag}
                        onDragOver={handleDrag}
                        onDrop={handleDrag}
                    >
                        <div className="p-4 rounded-full bg-slate-700/50 text-slate-400 mb-4">
                            <Upload size={32} />
                        </div>
                        <p className="text-slate-300 font-medium text-center px-6">
                            Arrastra y suelta tus archivos aquí o <span className="text-blue-400 cursor-pointer">explora</span>
                        </p>
                        <p className="text-slate-500 text-xs mt-2 text-center px-6">
                            PDF, DOCX, JSON, YAML hasta 50MB
                        </p>
                        <input type="file" className="absolute inset-0 opacity-0 cursor-pointer" />
                    </div>

                    <div className="glass-morphism rounded-3xl p-6 space-y-4">
                        <div className="flex items-center gap-2 text-slate-300 font-semibold mb-2">
                            <Tag size={18} />
                            <span>Etiquetas y Metadatos</span>
                        </div>
                        <div className="flex flex-wrap gap-2">
                            {['Legal', 'Anual', 'Riesgo', 'Estrategia'].map(tag => (
                                <span key={tag} className="flex items-center gap-1 px-3 py-1 rounded-full bg-slate-700 text-slate-300 text-xs font-medium">
                                    {tag} <X size={12} className="cursor-pointer hover:text-white" />
                                </span>
                            ))}
                            <button className="px-3 py-1 rounded-full border border-slate-700 text-slate-500 text-xs font-medium hover:border-blue-500 hover:text-blue-400 transition-colors">
                                + Añadir
                            </button>
                        </div>
                    </div>
                </div>

                <div className="space-y-6">
                    <div className="glass-morphism rounded-3xl p-6 h-full flex flex-col">
                        <div className="flex items-center gap-2 text-slate-300 font-semibold mb-4">
                            <Layers size={18} />
                            <span>Configuración de Análisis</span>
                        </div>

                        <div className="flex-1 space-y-4">
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-400">Título del Análisis</label>
                                <input
                                    type="text"
                                    placeholder="Ej: Análisis Trimestral Q1"
                                    className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all font-medium"
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-400">Categoría Pre-análisis</label>
                                <select className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500/50 transition-all font-medium cursor-pointer appearance-none">
                                    <option>Detección automática</option>
                                    <option>Jurídico / Legal</option>
                                    <option>Técnico / Infraestructura</option>
                                    <option>Gubernamental</option>
                                </select>
                            </div>

                            <div className="p-4 rounded-xl bg-blue-500/10 border border-blue-500/20 text-xs text-blue-300 leading-relaxed">
                                <strong>Nota Local:</strong> Este documento se procesará enteramente en tu infraestructura. No se enviarán datos a la nube.
                            </div>
                        </div>

                        <button
                            onClick={handleStart}
                            disabled={isProcessing}
                            className={`w-full mt-6 bg-blue-600 hover:bg-blue-500 text-white font-bold py-4 rounded-2xl flex items-center justify-center gap-2 shadow-lg shadow-blue-500/20 transition-all active:scale-[0.98] ${isProcessing ? 'opacity-50 cursor-not-allowed' : ''}`}
                        >
                            <Send size={20} />
                            Iniciar Procesamiento Semántico
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default IngestForm;
