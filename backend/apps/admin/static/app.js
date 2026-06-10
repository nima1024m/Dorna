/**
 * Dorna Admin Panel - JavaScript
 */

const API_BASE = '/admin';
let accessToken = localStorage.getItem('admin_token');
let currentAdmin = null;
let currentTopics = [];
let topicModalMode = 'create';
const topicLoading = new Set();
const articleLoading = new Set();
let scriptModalTopicId = null;

// API Helper
async function api(endpoint, options = {}) {
    const headers = { 'Content-Type': 'application/json' };
    if (accessToken) headers['Authorization'] = `Bearer ${accessToken}`;

    const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });

    if (response.status === 401) {
        logout();
        throw new Error('Unauthorized');
    }

    return response.json();
}

// Auth
async function login(email, password) {
    const data = await api('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password })
    });

    if (data.status === 'OK') {
        accessToken = data.access_token;
        localStorage.setItem('admin_token', accessToken);
        currentAdmin = data.admin;
        showDashboard();
    } else {
        console.error('Login failed:', data);
        let msg = data.message || 'Login failed';
        if (data.detail) {
            if (Array.isArray(data.detail)) {
                // Handle Pydantic validation errors
                msg = data.detail.map(e => {
                    const field = e.loc ? e.loc[e.loc.length - 1] : '';
                    return field ? `${field}: ${e.msg}` : e.msg;
                }).join(', ');
            } else {
                msg = String(data.detail);
            }
        }
        throw new Error(msg);
    }
    return data;
}

function logout() {
    accessToken = null;
    currentAdmin = null;
    localStorage.removeItem('admin_token');
    document.getElementById('login-page').classList.remove('hidden');
    document.getElementById('dashboard-page').classList.add('hidden');
}

// Navigation
function showSection(sectionId) {
    document.querySelectorAll('.content-section').forEach(s => s.classList.add('hidden'));
    document.getElementById(`section-${sectionId}`).classList.remove('hidden');

    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelector(`[data-section="${sectionId}"]`).classList.add('active');

    if (sectionId === 'dashboard') loadDashboard();
    if (sectionId === 'users') loadUsers();
    if (sectionId === 'topics') loadTopics();
    if (sectionId === 'analytics') loadAnalytics();
    if (sectionId === 'audit') loadAuditLogs();
}

// Dashboard
async function loadDashboard() {
    try {
        const data = await api('/analytics/dashboard');
        if (data.status === 'OK') {
            document.getElementById('stat-total-users').textContent = data.overview.total_users;
            document.getElementById('stat-active-today').textContent = data.overview.active_users_today;
            document.getElementById('stat-new-week').textContent = data.overview.new_users_week;
            document.getElementById('stat-topics').textContent = data.overview.active_topics;
            document.getElementById('stat-requests-today').textContent = data.overview.total_requests_today;

            const statusMap = data.overview.system_status || {};
            setSystemStatus('ai', statusMap.ai);
            setSystemStatus('tts', statusMap.tts);
            setSystemStatus('db', statusMap.database);

            setTokenUsage('7', data.overview.token_usage_7d);
            setTokenUsage('30', data.overview.token_usage_30d);
            setTokenUsage('90', data.overview.token_usage_90d);
        }
    } catch (e) {
        console.error('Dashboard error:', e);
    }
}

function setSystemStatus(key, status) {
    const statusText = document.getElementById(`status-${key}`);
    const statusDot = document.getElementById(`status-dot-${key}`);
    if (!statusText || !statusDot) return;

    const normalized = (status || 'unknown').toLowerCase();
    statusText.textContent = normalized.charAt(0).toUpperCase() + normalized.slice(1);

    statusDot.classList.remove('ok', 'warn', 'down');
    if (normalized === 'online' || normalized === 'healthy') {
        statusDot.classList.add('ok');
    } else if (normalized === 'offline' || normalized === 'down') {
        statusDot.classList.add('down');
    } else {
        statusDot.classList.add('warn');
    }
}

function setTokenUsage(period, usage) {
    if (!usage) return;
    const userEl = document.getElementById(`token-${period}-user`);
    const systemEl = document.getElementById(`token-${period}-system`);
    const ttsEl = document.getElementById(`token-${period}-tts`);
    const costEl = document.getElementById(`token-${period}-cost`);

    if (userEl) userEl.textContent = formatTokensShort(usage.user_tokens || 0);
    if (systemEl) systemEl.textContent = formatTokensShort(usage.system_tokens || 0);
    if (ttsEl) ttsEl.textContent = formatTokensShort(usage.tts_tokens || 0);
    const totalCost = (usage.user_cost_cents || 0) + (usage.system_cost_cents || 0) + (usage.tts_cost_cents || 0);
    setCostLabel(costEl, totalCost);
}

function setCostLabel(el, costCents) {
    if (!el) return;
    el.textContent = formatUsd(costCents || 0);
    el.classList.remove('hidden');
}

// Users
let usersPage = 1;
async function loadUsers(page = 1) {
    usersPage = page;
    const search = document.getElementById('user-search')?.value || '';
    const status = document.getElementById('user-status-filter')?.value || '';

    try {
        const params = new URLSearchParams({ page, page_size: 20 });
        if (search) params.set('search', search);
        if (status) params.set('status', status);

        const data = await api(`/users?${params}`);
        renderUsersTable(data);
    } catch (e) {
        console.error('Users error:', e);
    }
}

function renderUsersTable(data) {
    const tbody = document.getElementById('users-table-body');

    if (!data.users || data.users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading-row">No users found</td></tr>';
        return;
    }

    tbody.innerHTML = data.users.map(u => `
        <tr>
            <td>
                <div class="user-cell">
                    <div class="user-avatar">${(u.full_name || u.email)[0].toUpperCase()}</div>
                    <div class="user-info">
                        <span class="user-name">${u.full_name || 'No Name'}</span>
                        <span class="user-email">${u.email}</span>
                    </div>
                </div>
            </td>
            <td><span class="status-badge ${u.is_active ? 'active' : 'inactive'}">${u.is_active ? 'Active' : 'Inactive'}</span></td>
            <td class="token-cell">${formatTokenUsage(u.token_usage, u.token_cost_cents)}</td>
            <td>${u.initial_clb_level || '—'}</td>
            <td>${new Date(u.created_at).toLocaleDateString()}</td>
            <td>
                <div class="action-buttons">
                    <button class="action-btn" onclick="viewUser(${u.id})" title="View">👁</button>
                    <button class="action-btn" onclick="toggleUserLock(${u.id}, ${u.is_active})" title="${u.is_active ? 'Lock' : 'Unlock'}">${u.is_active ? '🔒' : '🔓'}</button>
                </div>
            </td>
        </tr>
    `).join('');

    document.getElementById('users-page-info').textContent = `Page ${data.page} of ${data.total_pages}`;
    document.getElementById('users-prev-btn').disabled = data.page <= 1;
    document.getElementById('users-next-btn').disabled = data.page >= data.total_pages;
}

function formatTokenUsage(usage = {}, costCents = 0) {
    const parts = [];
    const order = ['gemini', 'tts', 'system'];
    order.forEach(key => {
        const tokens = usage?.[key];
        if (!tokens) return;
        parts.push(`${formatTokensShort(tokens)} ${key.toUpperCase()}`);
    });

    if (parts.length === 0) return '—';

    const costText = costCents > 0 ? ` · ${formatUsd(costCents)}` : '';
    return `${parts.join(' • ')}${costText}`;
}

function formatTokensShort(tokens) {
    if (tokens >= 1000000) return `${(tokens / 1000000).toFixed(1)}M`;
    if (tokens >= 1000) return `${(tokens / 1000).toFixed(1)}K`;
    return `${tokens}`;
}

function formatUsd(costMicro) {
    const amount = (costMicro / 100000).toFixed(5);
    return `${amount} USD`;
}

async function viewUser(userId) {
    try {
        const data = await api(`/users/${userId}`);
        const modal = document.getElementById('user-modal');
        const body = document.getElementById('user-modal-body');

        body.innerHTML = `
            <div style="display: grid; gap: 16px;">
                <div><strong>Email:</strong> ${data.user.email}</div>
                <div><strong>Name:</strong> ${data.user.full_name || '—'}</div>
                <div><strong>Status:</strong> ${data.user.is_active ? 'Active' : 'Inactive'}</div>
                <div><strong>CLB Level:</strong> ${data.user.initial_clb_level || '—'}</div>
                <div><strong>Nationality:</strong> ${data.user.nationality || '—'}</div>
                <div><strong>Profession:</strong> ${data.user.profession || '—'}</div>
                <div><strong>Created:</strong> ${new Date(data.user.created_at).toLocaleString()}</div>
            </div>
        `;

        modal.classList.remove('hidden');
    } catch (e) {
        console.error('View user error:', e);
    }
}

async function toggleUserLock(userId, isActive) {
    const action = isActive ? 'lock' : 'unlock';
    if (!confirm(`Are you sure you want to ${action} this user?`)) return;

    try {
        await api(`/users/${userId}/${action}`, { method: 'POST' });
        loadUsers(usersPage);
    } catch (e) {
        console.error('Toggle lock error:', e);
    }
}

// Topics
async function loadTopics() {
    try {
        const data = await api('/topics');
        currentTopics = data.topics || [];
        renderTopicsTable(data);
    } catch (e) {
        console.error('Topics error:', e);
    }
}

function renderTopicsTable(data) {
    const tbody = document.getElementById('topics-table-body');

    if (!data.topics || data.topics.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="loading-row">No topics found</td></tr>';
        return;
    }

    tbody.innerHTML = data.topics.map(t => `
        <tr>
            <td><strong>${t.title}</strong><br><small style="color: var(--text-muted)">${t.topic_id}</small></td>
            <td><span class="status-badge ${t.is_active ? 'active' : 'inactive'}">${t.is_active ? 'Active' : 'Inactive'}</span></td>
            <td>${t.priority}</td>
            <td>${t.news_item_count || 0}</td>
            <td>${t.last_refreshed_at ? new Date(t.last_refreshed_at).toLocaleString() : '—'}</td>
            <td>
                <div class="action-buttons">
                    <button class="action-btn play ${topicLoading.has(t.topic_id) ? 'loading' : ''}" onclick="generateTopicArticle('${t.topic_id}')" title="Generate article" ${topicLoading.has(t.topic_id) ? 'disabled' : ''}>
                        <span class="btn-icon">${topicLoading.has(t.topic_id) ? '' : '▶'}</span>
                        <span class="btn-spinner" aria-hidden="true"></span>
                    </button>
                    ${t.podcast_ready ? `<button class="action-btn" onclick="viewTopicPodcast('${t.topic_id}')" title="View script">📄</button>` : `<button class="action-btn script-disabled" title="No script yet" disabled>📄<span class="icon-x">×</span></button>`}
                    <button class="action-btn ${articleLoading.has(t.topic_id) ? 'loading' : ''}" onclick="openTopicArticle('${t.topic_id}')" title="View article" ${articleLoading.has(t.topic_id) ? 'disabled' : ''}>
                        <span class="btn-icon">📰</span>
                        <span class="btn-spinner" aria-hidden="true"></span>
                        ${t.article_ready ? '' : '<span class="icon-x">×</span>'}
                    </button>
                    <button class="action-btn" onclick="openTopicModal('edit', '${t.topic_id}')" title="Edit">✏️</button>
                    <button class="action-btn danger" onclick="deleteTopic('${t.topic_id}')" title="Delete">🗑</button>
                </div>
            </td>
        </tr>
    `).join('');
}

function renderTopicScript(panelTitle, payload) {
    const titleEl = document.getElementById('topic-script-title');
    const bodyEl = document.getElementById('topic-script-body');
    const sourcesEl = document.getElementById('topic-script-sources');

    titleEl.textContent = panelTitle;
    if (!payload || !payload.script || payload.script.length === 0) {
        if (payload && payload.error_message) {
            bodyEl.innerHTML = `<p class="muted">Error: ${payload.error_message}</p>`;
        } else {
            bodyEl.innerHTML = '<p class="muted">No script available yet.</p>';
        }
        sourcesEl.innerHTML = '';
        return;
    }

    bodyEl.innerHTML = payload.script.map(turn => `
        <div class="script-turn">
            <span class="script-speaker">${turn.speaker}</span>
            <p>${turn.text}</p>
        </div>
    `).join('');

    if (payload.sources && payload.sources.length > 0) {
        sourcesEl.innerHTML = payload.sources.map(s => `
            <a href="${s.url}" target="_blank" rel="noreferrer">${s.title}</a>
        `).join('');
    } else {
        sourcesEl.innerHTML = '';
    }
}

function openScriptModal(title, payload) {
    scriptModalTopicId = payload && payload.topic_id ? payload.topic_id : null;
    const modal = document.getElementById('script-modal');
    const titleEl = document.getElementById('script-modal-title');
    const bodyEl = document.getElementById('script-modal-body');
    const sourcesEl = document.getElementById('script-modal-sources');
    const errorEl = document.getElementById('script-modal-error');

    titleEl.textContent = title;
    errorEl.classList.add('hidden');

    if (!payload || !payload.script || payload.script.length === 0) {
        if (payload && payload.error_message) {
            bodyEl.innerHTML = '';
            errorEl.textContent = payload.error_message;
            errorEl.classList.remove('hidden');
        } else {
            bodyEl.innerHTML = '<p class="muted">Generating script…</p>';
        }
        sourcesEl.innerHTML = '';
    } else {
        bodyEl.innerHTML = payload.script.map(turn => `
            <div class="script-turn">
                <span class="script-speaker">${turn.speaker}</span>
                <p>${turn.text}</p>
            </div>
        `).join('');
        sourcesEl.innerHTML = (payload.sources || []).map(s => `
            <a href="${s.url}" target="_blank" rel="noreferrer">${s.title}</a>
        `).join('');
    }

    modal.classList.remove('hidden');
}

function closeScriptModal() {
    document.getElementById('script-modal').classList.add('hidden');
}

function openArticleModal(title, payload) {
    const modal = document.getElementById('article-modal');
    const titleEl = document.getElementById('article-modal-title');
    const dateEl = document.getElementById('article-modal-date');
    const imageEl = document.getElementById('article-modal-image');
    const bodyEl = document.getElementById('article-modal-body');
    const sourcesEl = document.getElementById('article-modal-sources');
    const listEl = document.getElementById('article-modal-list');
    const errorEl = document.getElementById('article-modal-error');
    const heroRefreshBtn = document.getElementById('article-hero-refresh');

    titleEl.textContent = title;
    errorEl.classList.add('hidden');
    listEl.innerHTML = '';
    heroRefreshBtn.classList.add('hidden');

    if (!payload) {
        bodyEl.innerHTML = '<div class="loading-block"><span class="spinner"></span><span>Generating article…</span></div>';
        dateEl.textContent = '';
        imageEl.classList.add('hidden');
        sourcesEl.innerHTML = '';
    } else if (!payload.articles || payload.articles.length === 0) {
        bodyEl.innerHTML = '<p class="muted">No article available yet.</p>';
        dateEl.textContent = '';
        imageEl.classList.add('hidden');
        sourcesEl.innerHTML = '';
        if (payload && payload.error_message) {
            errorEl.textContent = payload.error_message;
            errorEl.classList.remove('hidden');
        }
    } else {
        const renderDetail = (article) => {
            dateEl.textContent = new Date(article.published_at).toLocaleString();
            imageEl.referrerPolicy = 'no-referrer';
            imageEl.src = article.image_url;
            imageEl.alt = article.title || 'Article image';
            imageEl.classList.remove('hidden');
            heroRefreshBtn.dataset.id = article.id;
            heroRefreshBtn.classList.remove('hidden');
            imageEl.onerror = () => {
                imageEl.src = 'data:image/svg+xml;utf8,' + encodeURIComponent(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="675">' +
                    '<rect width="100%" height="100%" fill="#efe3d4"/>' +
                    '<text x="50%" y="50%" font-family="Space Grotesk, sans-serif" font-size="32" fill="#7f7a72" text-anchor="middle" dominant-baseline="middle">' +
                    'Image unavailable' +
                    '</text></svg>'
                );
            };
            bodyEl.innerHTML = `
                <article class="article-block active">
                    <h4>${article.title}</h4>
                    ${article.content
                    .split(/\\n+/)
                    .filter(Boolean)
                    .map(p => `<p>${p}</p>`)
                    .join('')}
                </article>
            `;
            sourcesEl.innerHTML = (article.sources || []).map(s => `
                <a href="${s.url}" target="_blank" rel="noreferrer">${s.title}</a>
            `).join('');
        };

        listEl.innerHTML = payload.articles.map((article, idx) => `
            <button class="article-list-item ${idx === 0 ? 'active' : ''}" data-idx="${idx}">
                <div class="article-thumb">
                    <img src="${article.image_url}" alt="${article.title}" loading="lazy" onerror="this.closest('.article-thumb').classList.add('no-image')">
                </div>
                <div class="article-list-meta">
                    <div class="article-list-title">${article.title}</div>
                    <div class="muted">${new Date(article.published_at).toLocaleDateString()}</div>
                </div>
            </button>
        `).join('');

        listEl.querySelectorAll('.article-list-item').forEach(btn => {
            btn.addEventListener('click', () => {
                listEl.querySelectorAll('.article-list-item').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                const article = payload.articles[Number(btn.dataset.idx)];
                renderDetail(article);
            });
        });
        heroRefreshBtn.onclick = async (e) => {
            e.stopPropagation();
            const id = heroRefreshBtn.dataset.id;
            if (!id) return;
            heroRefreshBtn.disabled = true;
            try {
                const updated = await api(`/topics/articles/${id}/image/refresh`, { method: 'POST' });
                const article = payload.articles.find(a => a.id === id);
                if (article) {
                    article.image_url = updated.image_url;
                }
                imageEl.src = updated.image_url;
            } catch (err) {
                console.error('Refresh image error:', err);
                alert(err.message || 'Failed to refresh image');
            } finally {
                heroRefreshBtn.disabled = false;
            }
        };

        renderDetail(payload.articles[0]);
    }

    modal.classList.remove('hidden');
}

function closeArticleModal() {
    document.getElementById('article-modal').classList.add('hidden');
}

async function generateTopicArticle(topicId) {
    if (topicLoading.has(topicId)) return;
    try {
        topicLoading.add(topicId);
        renderTopicsTable({ topics: currentTopics });
        openArticleModal(`Article (${topicId})`, null);
        const data = await api(`/topics/${topicId}/articles/generate?count=1`, { method: 'POST' });
        const topic = currentTopics.find(t => t.topic_id === topicId);
        if (topic) topic.article_ready = true;
        openArticleModal(`Article (${topicId})`, data);
    } catch (e) {
        console.error('Generate article error:', e);
        openArticleModal('Article', { error_message: e.message || 'Failed to generate article' });
    } finally {
        topicLoading.delete(topicId);
        renderTopicsTable({ topics: currentTopics });
    }
}

async function viewTopicPodcast(topicId) {
    try {
        const data = await api(`/topics/${topicId}/podcast`);
        renderTopicScript(`Podcast Script (${topicId})`, data);
        openScriptModal(`Podcast Script (${topicId})`, data);
    } catch (e) {
        console.error('View podcast error:', e);
        renderTopicScript('Podcast Script', { script: [] });
        openScriptModal('Podcast Script', { script: [], error_message: e.message || 'No podcast script found for this topic' });
    }
}

async function openTopicArticle(topicId) {
    if (articleLoading.has(topicId)) return;
    try {
        articleLoading.add(topicId);
        renderTopicsTable({ topics: currentTopics });
        const topic = currentTopics.find(t => t.topic_id === topicId);
        const data = topic && !topic.article_ready
            ? await api(`/topics/${topicId}/articles/generate`, { method: 'POST' })
            : await api(`/topics/${topicId}/articles`);
        if (topic) {
            topic.article_ready = true;
        }
        openArticleModal(`Article (${topicId})`, data);
    } catch (e) {
        console.error('View article error:', e);
        openArticleModal('Article', { error_message: e.message || 'Failed to load article' });
    } finally {
        articleLoading.delete(topicId);
        renderTopicsTable({ topics: currentTopics });
    }
}

async function openTopicModal(mode, topicId = null) {
    topicModalMode = mode;
    const modal = document.getElementById('topic-modal');
    const form = document.getElementById('topic-form');
    const titleEl = document.getElementById('topic-modal-title');
    const deleteHint = document.getElementById('topic-delete-hint');

    form.reset();
    deleteHint.classList.add('hidden');

    if (mode === 'edit') {
        let topic = currentTopics.find(t => t.topic_id === topicId);
        if (!topic) return;
        try {
            const detail = await api(`/topics/${topicId}`);
            if (detail.topic) {
                topic = { ...topic, ...detail.topic };
            }
        } catch (e) {
            console.error('Topic detail error:', e);
        }
        titleEl.textContent = 'Edit Topic';
        form.elements['topic_id'].value = topic.topic_id;
        form.elements['topic_id'].disabled = true;
        form.elements['title'].value = topic.title || '';
        form.elements['description'].value = topic.description || '';
        form.elements['ai_search_prompt'].value = topic.ai_search_prompt || '';
        form.elements['tags'].value = (topic.tags || []).join(', ');
        form.elements['geo_codes'].value = (topic.geo_codes || []).join(', ');
        form.elements['update_minutes'].value = topic.update_minutes || 60;
        form.elements['priority'].value = topic.priority ?? 0;
        form.elements['is_active'].checked = !!topic.is_active;
        form.elements['language'].value = topic.language || '';
        deleteHint.classList.remove('hidden');
    } else {
        titleEl.textContent = 'Add Topic';
        form.elements['topic_id'].disabled = false;
        form.elements['update_minutes'].value = 60;
        form.elements['priority'].value = 0;
        form.elements['is_active'].checked = true;
    }

    modal.classList.remove('hidden');
}

function closeTopicModal() {
    document.getElementById('topic-modal').classList.add('hidden');
}

function parseListInput(value) {
    if (!value) return [];
    return value.split(',').map(v => v.trim()).filter(Boolean);
}

async function submitTopicForm(event) {
    event.preventDefault();
    const form = event.target;
    const topicIdInput = form.elements['topic_id'].value.trim().toLowerCase();
    const payload = {
        topic_id: topicIdInput,
        title: form.elements['title'].value.trim(),
        description: form.elements['description'].value.trim() || null,
        ai_search_prompt: form.elements['ai_search_prompt'].value.trim(),
        tags: parseListInput(form.elements['tags'].value),
        geo_codes: parseListInput(form.elements['geo_codes'].value),
        update_minutes: Number(form.elements['update_minutes'].value || 60),
        is_active: !!form.elements['is_active'].checked,
        priority: Number(form.elements['priority'].value || 0),
        language: form.elements['language'].value.trim() || null
    };

    try {
        if (topicModalMode === 'edit') {
            const updates = { ...payload };
            delete updates.topic_id;
            const resp = await api(`/topics/${form.elements['topic_id'].value}`, {
                method: 'PATCH',
                body: JSON.stringify(updates)
            });
            if (resp.status && resp.status !== 'OK') throw new Error(resp.message || 'Failed to update topic');
            if (resp.detail) throw new Error('Failed to update topic');
        } else {
            const resp = await api('/topics', {
                method: 'POST',
                body: JSON.stringify(payload)
            });
            if (resp.status && resp.status !== 'OK') throw new Error(resp.message || 'Failed to create topic');
            if (resp.detail) throw new Error('Failed to create topic');
        }
        closeTopicModal();
        loadTopics();
    } catch (e) {
        console.error('Topic submit error:', e);
        alert(e.message || 'Failed to save topic');
    }
}

async function deleteTopic(topicId) {
    if (!confirm('Delete this topic and all its news items?')) return;
    try {
        await api(`/topics/${topicId}`, { method: 'DELETE' });
        loadTopics();
    } catch (e) {
        console.error('Delete topic error:', e);
        alert(e.message || 'Failed to delete topic');
    }
}

// Analytics
async function loadAnalytics() {
    try {
        const data = await api('/analytics/language-insights');

        const clbDiv = document.getElementById('clb-distribution');
        clbDiv.innerHTML = Object.entries(data.clb_distribution || {})
            .map(([k, v]) => `<div>${k}: ${v} users</div>`).join('') || 'No data';

        const grammarDiv = document.getElementById('grammar-issues');
        grammarDiv.innerHTML = (data.top_grammar_issues || [])
            .slice(0, 5)
            .map(i => `<div>${i.pattern}: ${i.frequency}</div>`).join('') || 'No data';
    } catch (e) {
        console.error('Analytics error:', e);
    }
}

// Audit
async function loadAuditLogs() {
    try {
        const data = await api('/audit');
        renderAuditTable(data);
    } catch (e) {
        console.error('Audit error:', e);
    }
}

function renderAuditTable(data) {
    const tbody = document.getElementById('audit-table-body');

    if (!data.logs || data.logs.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="loading-row">No audit logs</td></tr>';
        return;
    }

    tbody.innerHTML = data.logs.map(l => `
        <tr>
            <td>${l.admin_email}</td>
            <td>${l.action}</td>
            <td>${l.resource_type}${l.resource_id ? ` #${l.resource_id}` : ''}</td>
            <td>${new Date(l.created_at).toLocaleString()}</td>
            <td><span class="status-badge ${l.success ? 'success' : 'failed'}">${l.success ? 'Success' : 'Failed'}</span></td>
        </tr>
    `).join('');
}

// Show Dashboard
function showDashboard() {
    document.getElementById('login-page').classList.add('hidden');
    document.getElementById('dashboard-page').classList.remove('hidden');

    if (currentAdmin) {
        document.getElementById('admin-initials').textContent = currentAdmin.full_name[0].toUpperCase();
        document.getElementById('admin-name').textContent = currentAdmin.full_name;
        document.getElementById('admin-role').textContent = currentAdmin.role;
    }

    showSection('dashboard');
}

// Init
document.addEventListener('DOMContentLoaded', () => {
    const root = document.documentElement;
    const savedTheme = localStorage.getItem('admin_theme') || 'dark';
    const themeSwitch = document.getElementById('theme-toggle-switch');
    root.setAttribute('data-theme', savedTheme);
    if (themeSwitch) {
        themeSwitch.checked = savedTheme === 'dark';
        themeSwitch.addEventListener('change', () => {
            const theme = themeSwitch.checked ? 'dark' : 'light';
            root.setAttribute('data-theme', theme);
            localStorage.setItem('admin_theme', theme);
        });
    }
    // Login form
    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const errorEl = document.getElementById('login-error');

        try {
            errorEl.textContent = '';
            await login(email, password);
        } catch (err) {
            errorEl.textContent = err.message || 'Login failed';
        }
    });

    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            showSection(item.dataset.section);
        });
    });

    // Logout
    document.getElementById('logout-btn').addEventListener('click', logout);

    // Modal close
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', () => {
            const modal = btn.closest('.modal');
            if (modal) modal.classList.add('hidden');
        });
    });
    document.getElementById('topic-modal-close')?.addEventListener('click', closeTopicModal);
    document.getElementById('topic-modal-cancel')?.addEventListener('click', closeTopicModal);
    document.getElementById('script-modal-close')?.addEventListener('click', closeScriptModal);
    document.getElementById('script-modal-cancel')?.addEventListener('click', closeScriptModal);
    document.getElementById('article-modal-close')?.addEventListener('click', closeArticleModal);
    document.getElementById('article-modal-cancel')?.addEventListener('click', closeArticleModal);

    // User search
    document.getElementById('user-search')?.addEventListener('input', () => loadUsers(1));
    document.getElementById('user-status-filter')?.addEventListener('change', () => loadUsers(1));
    document.getElementById('users-prev-btn')?.addEventListener('click', () => loadUsers(usersPage - 1));
    document.getElementById('users-next-btn')?.addEventListener('click', () => loadUsers(usersPage + 1));
    document.getElementById('add-topic-btn')?.addEventListener('click', () => openTopicModal('create'));
    document.getElementById('topic-form')?.addEventListener('submit', submitTopicForm);

    // Check if already logged in
    if (accessToken) {
        api('/auth/me').then(data => {
            if (data.id) {
                currentAdmin = data;
                showDashboard();
            } else {
                logout();
            }
        }).catch(logout);
    }
});
