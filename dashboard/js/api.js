import { CONFIG } from './config.js';
import { DashboardStore } from './store.js';
import { ReportParser } from './parser.js';

export class SysGuardianAPI {

    async fetchLatestReport(options = {}) {

        const controller = new AbortController();

        const timeout = setTimeout(() => {
            controller.abort();
        }, CONFIG.API.TIMEOUT);

        try {

            const signal = options.signal ?? controller.signal;

            const response = await fetch(
                `${CONFIG.API.ENDPOINT}?_=${Date.now()}`,
                {
                    cache: 'no-store',
                    ...options,
                    signal
                }
            );

            clearTimeout(timeout);

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const json = await response.json();

            const report = ReportParser.parse(json);

            DashboardStore.set(report);

            return DashboardStore.get();

        } catch (error) {

            clearTimeout(timeout);

            console.error('[SysGuardianAPI]', error);

            throw error;

        }

    }

}
