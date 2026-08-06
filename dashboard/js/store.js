/**
 * ============================================================
 * SysGuardian Dashboard
 * Global Store
 * ============================================================
 */

export const DashboardStore = {

    report: null,

    subscribers: [],

    set(report) {

        this.report = report;

        this.notify();

    },

    get() {

        return this.report;

    },

    metadata() {

        return this.report?.metadata ?? {};

    },

    categories() {

        return this.report?.category_scores ?? {};

    },

    entries() {

        return this.report?.entries ?? [];

    },

    alerts() {

        return (this.report?.entries ?? []).filter(item =>
            item.level === 'WARN' ||
            item.level === 'ERROR'
        );

    },

    subscribe(callback) {

        if (typeof callback === 'function') {

            this.subscribers.push(callback);

        }

    },

    unsubscribe(callback) {

        this.subscribers = this.subscribers.filter(fn => fn !== callback);

    },

    notify() {

        this.subscribers.forEach(fn => {

            try {

                fn(this.report);

            }

            catch(error){

                console.error('[DashboardStore]', error);

            }

        });

    },

    clear() {

        this.report = null;

        this.notify();

    }

};
