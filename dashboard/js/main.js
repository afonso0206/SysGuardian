import { SysGuardianAPI } from './api.js';
import { ThemeManager } from './theme.js';
import { Router } from './router.js';
import { HeaderComponent } from './header.js';
import { SidebarComponent } from './sidebar.js';
import { GaugeComponent } from './gauge.js';
import { CardsComponent } from './cards.js';
import { AlertsComponent } from './alerts.js';
import { ChartsComponent } from './charts.js';
import { HistoryComponent } from './history.js';
import { SettingsComponent } from './settings.js';
import { PrintersComponent } from './printers.js';

class App {
    #abortController = null;

    constructor() {
        this.state = {
            report: null,
            loading: false,
            initialized: false,
            currentRoute: 'overview',
            refreshInterval: 0,
            refreshTimer: null
        };

        this.modules = {
            api: null,
            theme: null,
            header: null,
            sidebar: null,
            gauge: null,
            cards: null,
            alerts: null,
            charts: null,
            history: null,
            printers: null,
            settings: null,
            router: null
        };

        this.eventListeners = new Map();

        this.#viewRenderers = {
            'overview': () => this.renderOverview(),
            'alerts': () => this.renderAlerts(),
            'history': () => this.renderHistory(),
            'printers': () => this.renderPrinters(),
            'settings': () => {}
        };
    }

    #viewRenderers;

    async init() {
        try {
            this.initializeModules();
            this.bindEvents();
            
            const routes = {
                'overview': () => this.onRouteChange('overview'),
                'alerts': () => this.onRouteChange('alerts'),
                'history': () => this.onRouteChange('history'),
                'printers': () => this.onRouteChange('printers'),
                'settings': () => this.onRouteChange('settings')
            };

            this.modules.router = new Router(routes);
            
            await this.loadData();
            
            this.modules.router.init();
            this.state.initialized = true;
        } catch (error) {
            this.handleError('Erro durante a inicialização da aplicação', error);
        }
    }

    initializeModules() {
        this.modules.api = new SysGuardianAPI();
        this.modules.theme = new ThemeManager();
        this.modules.theme.init();

        this.modules.header = new HeaderComponent();
        this.modules.sidebar = new SidebarComponent();
        this.modules.sidebar.init();

        this.modules.gauge = new GaugeComponent();
        this.modules.cards = new CardsComponent();
        this.modules.alerts = new AlertsComponent();
        this.modules.charts = new ChartsComponent();
        this.modules.history = new HistoryComponent();
        this.modules.printers = new PrintersComponent();

        this.modules.settings = new SettingsComponent(
            this.modules.theme, 
            (interval) => this.setRefreshInterval(interval)
        );
        this.modules.settings.init();
    }

    bindEvents() {
        const refreshBtn = document.getElementById('btnManualRefresh');
        if (refreshBtn) {
            const handleManualRefresh = () => {
                this.loadData().catch(err => this.handleError('Erro ao atualizar manualmente', err));
            };
            
            if (this.eventListeners.has(refreshBtn)) {
                const prev = this.eventListeners.get(refreshBtn);
                refreshBtn.removeEventListener(prev.type, prev.listener);
            }

            refreshBtn.addEventListener('click', handleManualRefresh);
            this.eventListeners.set(refreshBtn, { type: 'click', listener: handleManualRefresh });
        }
    }

#validateReport(data) {
    return (
        data !== null &&
        typeof data === 'object' &&
        typeof data.metadata === 'object' &&
        data.metadata !== null &&
        typeof data.category_scores === 'object' &&
        data.category_scores !== null &&
        Array.isArray(data.entries)
    );
}
    #normalizeReport(data) {
        if (!this.#validateReport(data)) {
            return {
                metadata: { score: 0, hostname: 'N/A', version: 'N/A', date: '' },
                category_scores: {},
                entries: [],
                printers: null
            };
        }

        return {
            metadata: {
                score: Number(data.metadata?.score) || 0,
                hostname: data.metadata?.hostname || 'N/A',
                version: data.metadata?.version || 'N/A',
                date: data.metadata?.date || ''
            },
            category_scores: (data.category_scores && typeof data.category_scores === 'object') ? data.category_scores : {},
            entries: Array.isArray(data.entries) ? data.entries : [],
            printers: (data.printers && typeof data.printers === 'object') ? data.printers : null
        };
    }

    async loadData() {
        if (this.state.loading) return;

        if (this.#abortController) {
            this.#abortController.abort();
        }
        this.#abortController = new AbortController();

        this.showLoading();
        try {
            const data = await this.modules.api.fetchLatestReport({ signal: this.#abortController.signal });
            
            const normalizedData = this.#normalizeReport(data);

            this.state.report = normalizedData;
            
            this.#updateHeader();
            this.renderCurrentView();
        } catch (error) {
            if (error.name !== 'AbortError') {
                this.handleError('Falha ao carregar dados do servidor', error);
            }
        } finally {
            this.hideLoading();
            this.#abortController = null;
        }
    }

    #updateHeader() {
        if (!this.state.report) return;
        if (this.state.report.metadata) {
            this.modules.header.updateMeta(this.state.report.metadata);
        }
        this.modules.header.setUpdateTimestamp();
    }

    onRouteChange(route) {
        this.state.currentRoute = route;
        this.renderCurrentView();
    }

    renderCurrentView() {
        if (!this.state.report) return;

        const renderer = this.#viewRenderers[this.state.currentRoute] || this.#viewRenderers['overview'];
        renderer();
    }

    render() {
        this.renderCurrentView();
    }

    renderOverview() {
        if (!this.state.report) return;
        
        const { metadata, category_scores, entries } = this.state.report;

        try {
            this.modules.gauge.render('gaugeContainer', metadata.score);
            this.modules.cards.render('cardsContainer', category_scores);
            this.modules.charts.renderRadar('chartRadarContainer', category_scores);
            this.modules.charts.renderDonutAlerts('chartDonutContainer', entries);
            this.modules.alerts.render('overviewAlertsContainer', entries);
        } catch (error) {
            this.handleError('Erro ao renderizar visão geral', error);
        }
    }

    renderAlerts() {
        if (!this.state.report) return;

        try {
            this.modules.alerts.render('fullAlertsContainer', this.state.report.entries);
        } catch (error) {
            this.handleError('Erro ao renderizar tela de alertas', error);
        }
    }

    renderHistory() {
        if (!this.state.report) return;

        try {
            this.modules.history.renderTimeline('historyTimelineContainer', this.state.report.entries);
        } catch (error) {
            this.handleError('Erro ao renderizar histórico', error);
        }
    }

    renderPrinters() {
        if (!this.state.report) return;

        try {
            this.modules.printers.render(
                'printersContainer',
                this.state.report.entries,
                this.state.report.printers
            );
        } catch (error) {
            this.handleError('Erro ao renderizar tela de impressoras', error);
        }
    }

    setRefreshInterval(interval) {
        const parsedInterval = parseInt(interval, 10);
        const validIntervals = [0, 30000, 60000, 120000, 300000];
        
        this.state.refreshInterval = validIntervals.includes(parsedInterval) ? parsedInterval : 0;
        
        this.clearRefreshInterval();

        if (this.state.refreshInterval > 0) {
            this.state.refreshTimer = setInterval(() => {
                this.loadData().catch(err => this.handleError('Erro na atualização automática', err));
            }, this.state.refreshInterval);
        }
    }

    clearRefreshInterval() {
        if (this.state.refreshTimer !== null) {
            clearInterval(this.state.refreshTimer);
            this.state.refreshTimer = null;
        }
    }

    showLoading() {
        this.state.loading = true;
        const refreshBtn = document.getElementById('btnManualRefresh');
        if (refreshBtn) {
            refreshBtn.classList.add('loading', 'disabled');
        }
    }

    hideLoading() {
        this.state.loading = false;
        const refreshBtn = document.getElementById('btnManualRefresh');
        if (refreshBtn) {
            refreshBtn.classList.remove('loading', 'disabled');
        }
    }

    handleError(contextMessage, error) {
        const errorPayload = {
            timestamp: new Date().toISOString(),
            context: contextMessage,
            message: error?.message || String(error),
            stack: error?.stack || null
        };

        console.error(`[SysGuardian App Error] ${contextMessage}:`, error);

        this.notifyUIError(errorPayload);
    }

    notifyUIError(errorPayload) {
        // Ponto de extensão para integrações futuras (Toasts, Modais, Telemetria)
    }

    destroy() {
        if (this.#abortController) {
            this.#abortController.abort();
            this.#abortController = null;
        }

        this.clearRefreshInterval();
        
        this.eventListeners.forEach((value, element) => {
            if (element && typeof element.removeEventListener === 'function') {
                element.removeEventListener(value.type, value.listener);
            }
        });
        this.eventListeners.clear();

        this.state.report = null;
        this.state.initialized = false;
        this.state.loading = false;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const app = new App();
    app.init().catch(err => app.handleError('Erro fatal ao iniciar aplicação', err));
});
