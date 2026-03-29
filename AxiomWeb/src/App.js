import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { useState, useEffect } from 'react';
import { getBeliefs, getEvidence, runAIStressTest } from './api';
function App() {
    const [beliefs, setBeliefs] = useState([]);
    const [selected, setSelected] = useState(null);
    const [evidence, setEvidence] = useState([]);
    const [suggestions, setSuggestions] = useState([]);
    const [tab, setTab] = useState('support');
    const [loading, setLoading] = useState(true);
    useEffect(() => {
        getBeliefs().then(b => {
            setBeliefs(b);
            setSelected(b[0] ?? null);
            setLoading(false);
        });
    }, []);
    useEffect(() => {
        if (!selected)
            return;
        getEvidence(selected.id).then(setEvidence);
        runAIStressTest(selected.id).then(setSuggestions);
    }, [selected]);
    if (loading) {
        return (_jsx("div", { className: "loading", children: _jsx("span", { children: "Loading beliefs..." }) }));
    }
    const supporting = evidence.filter(e => e.type === 'support');
    const contradicting = evidence.filter(e => e.type === 'contradict');
    return (_jsxs("div", { className: "app", children: [_jsxs("header", { className: "header", children: [_jsx("h1", { className: "logo", children: "Axiom" }), _jsxs("span", { className: "count", children: [beliefs.length, " beliefs"] })] }), _jsxs("div", { className: "layout", children: [_jsx("aside", { className: "sidebar", children: beliefs.map(b => (_jsxs("button", { className: `belief-item ${selected?.id === b.id ? 'active' : ''}`, onClick: () => setSelected(b), children: [_jsx("span", { className: "belief-text", children: b.text }), _jsxs("div", { className: "belief-meta", children: [_jsxs("span", { className: "score", style: { color: b.score >= 50 ? '#4ade80' : '#ef4444' }, children: [b.score, "%"] }), b.isCore && _jsx("span", { className: "core-badge", children: "core" })] })] }, b.id))) }), _jsx("main", { className: "detail", children: selected ? (_jsxs(_Fragment, { children: [_jsxs("div", { className: "belief-header", children: [_jsx("h2", { className: "belief-title", children: selected.text }), _jsxs("div", { className: "belief-stats", children: [_jsxs("span", { className: "stat-score", style: { color: selected.score >= 50 ? '#4ade80' : '#ef4444' }, children: [selected.score, "% confidence"] }), selected.isCore && _jsx("span", { className: "core-badge", children: "core belief" })] })] }), _jsxs("div", { className: "tabs", children: [_jsxs("button", { className: `tab ${tab === 'support' ? 'active' : ''}`, onClick: () => setTab('support'), children: ["Supporting (", supporting.length, ")"] }), _jsxs("button", { className: `tab ${tab === 'contradict' ? 'active' : ''}`, onClick: () => setTab('contradict'), children: ["Contradicting (", contradicting.length, ")"] }), _jsx("button", { className: `tab ${tab === 'stress' ? 'active' : ''}`, onClick: () => setTab('stress'), children: "AI Stress Test" })] }), _jsxs("div", { className: "tab-content", children: [tab === 'support' && (_jsxs("ul", { className: "evidence-list", children: [supporting.length === 0 && _jsx("li", { className: "empty", children: "No supporting evidence yet." }), supporting.map(e => (_jsxs("li", { className: "evidence-item support", children: [_jsx("span", { className: "evidence-dot" }), _jsx("p", { children: e.text })] }, e.id)))] })), tab === 'contradict' && (_jsxs("ul", { className: "evidence-list", children: [contradicting.length === 0 && _jsx("li", { className: "empty", children: "No contradicting evidence yet." }), contradicting.map(e => (_jsxs("li", { className: "evidence-item contradict", children: [_jsx("span", { className: "evidence-dot" }), _jsx("p", { children: e.text })] }, e.id)))] })), tab === 'stress' && (_jsx("ul", { className: "suggestion-list", children: suggestions.map((s, i) => (_jsxs("li", { className: `suggestion-item ${s.type}`, children: [_jsx("span", { className: "suggestion-type", children: s.type }), _jsx("p", { children: s.challenge })] }, i))) }))] })] })) : (_jsx("div", { className: "empty-state", children: _jsx("p", { children: "Select a belief to view details." }) })) })] })] }));
}
export default App;
