import React from 'react';
import {
    LayoutDashboard,
    FileSearch,
    GitBranch,
    BookOpen,
    Settings,
    LogOut,
    ChevronRight
} from 'lucide-react';

const Sidebar = ({ activeTab, setActiveTab }) => {
    const menuItems = [
        { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
        { id: 'analyze', icon: FileSearch, label: 'Nuevo Análisis' },
        { id: 'gitops', icon: GitBranch, label: 'GitOps Panel' },
        { id: 'docs', icon: BookOpen, label: 'Docs' },
    ];

    return (
        <div className="w-64 h-screen bg-slate-900 border-r border-slate-800 flex flex-col fixed left-0 top-0">
            <div className="p-6">
                <div className="flex items-center gap-3 mb-8">
                    <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold text-white shadow-lg shadow-blue-500/20">
                        A
                    </div>
                    <span className="text-xl font-bold tracking-tight text-white">Cognitive Suite</span>
                </div>

                <nav className="space-y-1">
                    {menuItems.map((item) => (
                        <button
                            key={item.id}
                            onClick={() => setActiveTab(item.id)}
                            className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 ${activeTab === item.id
                                    ? 'bg-blue-600/10 text-blue-400 border border-blue-600/20'
                                    : 'text-slate-400 hover:bg-slate-800 hover:text-slate-200'
                                }`}
                        >
                            <div className="flex items-center gap-3">
                                <item.icon size={20} />
                                <span className="font-medium">{item.label}</span>
                            </div>
                            {activeTab === item.id && <ChevronRight size={16} />}
                        </button>
                    ))}
                </nav>
            </div>

            <div className="mt-auto p-6 border-t border-slate-800">
                <div className="flex items-center gap-3 p-2 rounded-lg hover:bg-slate-800 cursor-pointer transition-colors">
                    <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center text-xs">
                        JD
                    </div>
                    <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-200 truncate">Juan Mantenedor</p>
                        <p className="text-xs text-slate-500">Admin Local</p>
                    </div>
                </div>
                <button className="w-full mt-4 flex items-center gap-2 px-4 py-2 text-slate-400 hover:text-red-400 transition-colors text-sm">
                    <LogOut size={16} />
                    <span>Cerrar Sesión</span>
                </button>
            </div>
        </div>
    );
};

export default Sidebar;
