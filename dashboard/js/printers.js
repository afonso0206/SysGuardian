const NOT_AVAILABLE = 'N/D';

export class PrintersComponent {

    render(containerId, entries = [], structuredPrinters = null) {

        const container = document.getElementById(containerId);

        if (!container)
            return;

        const hasStructuredDevices = Array.isArray(structuredPrinters?.devices);
        const printers = hasStructuredDevices
            ? this.normalizeDevices(structuredPrinters.devices)
            : this.normalizeEntries(entries);
        const structuredSummary = hasStructuredDevices ? structuredPrinters?.summary : null;
        const fragment = document.createDocumentFragment();

        fragment.appendChild(this.renderSummary(printers, structuredSummary));

        const grid = document.createElement('section');
        grid.className = 'printers-grid';
        grid.setAttribute('aria-live', 'polite');

        if (!printers.length) {
            const empty = document.createElement('p');
            empty.className = 'printers-empty';
            empty.textContent = 'Nenhuma impressora disponível.';
            grid.appendChild(empty);
        } else {
            printers.forEach(printer => {
                grid.appendChild(this.renderCard(printer));
            });
        }

        fragment.appendChild(grid);
        container.replaceChildren(fragment);

    }

    normalizeDevices(devices) {

        return devices.map(device => {
            const tonerBlack = this.validPercent(device?.toner?.black);
            const tonerCyan = this.validPercent(device?.toner?.cyan);
            const tonerMagenta = this.validPercent(device?.toner?.magenta);
            const tonerYellow = this.validPercent(device?.toner?.yellow);
            const tonerValues = [tonerBlack, tonerCyan, tonerMagenta, tonerYellow]
                .filter(value => Number.isFinite(value));

            return {
                name: this.displayValue(device?.name),
                ip: this.displayValue(device?.ip),
                status: ['online', 'offline'].includes(device?.status) ? device.status : 'unknown',
                responseTime: this.validNumber(device?.response_ms),
                model: this.displayValue(device?.model),
                firmware: this.displayValue(device?.firmware),
                serial: this.displayValue(device?.serial),
                mac: this.formatMac(device?.mac),
                location: this.displayValue(device?.location),
                description: this.displayValue(device?.description),
                uptime: this.displayValue(device?.uptime),
                totalPages: this.validNumber(device?.total_pages),
                tonerBlack,
                tonerCyan,
                tonerMagenta,
                tonerYellow,
                paperPercent: this.validPercent(device?.paper?.percent),
                drumPercent: this.validPercent(device?.drum?.percent),
                errors: this.formatErrors(device?.errors),
                lastCollection: this.formatDate(device?.last_collection),
                warning: device?.status === 'online' && tonerValues.some(value => value <= 10)
            };
        }).sort((a, b) => {
            const rank = { offline: 0, warning: 1, online: 2, unknown: 3 };
            const rankA = a.status === 'online' && a.warning ? rank.warning : rank[a.status];
            const rankB = b.status === 'online' && b.warning ? rank.warning : rank[b.status];
            return rankA - rankB || a.name.localeCompare(b.name);
        });

    }

    displayValue(value) {

        if (value === null || value === undefined || value === '' || value === 'N/A' || value === -1)
            return NOT_AVAILABLE;

        return String(value);

    }

    validNumber(value) {

        return Number.isFinite(value) && value >= 0 ? value : null;

    }

    validPercent(value) {

        return Number.isFinite(value) && value >= 0 && value <= 100 ? value : null;

    }

    formatMac(value) {

        const mac = this.displayValue(value);

        if (mac === NOT_AVAILABLE)
            return mac;

        const octets = mac.trim().split(/[\s:-]+/);

        if (octets.length === 6 && octets.every(octet => /^[0-9a-f]{2}$/i.test(octet)))
            return octets.map(octet => octet.toUpperCase()).join(':');

        return mac;

    }

    formatErrors(errors) {

        if (!Array.isArray(errors))
            return NOT_AVAILABLE;

        const availableErrors = errors
            .map(error => this.displayValue(error))
            .filter(error => error !== NOT_AVAILABLE);

        return availableErrors.length ? availableErrors.join('; ') : NOT_AVAILABLE;

    }

    formatDate(value) {

        const timestamp = this.displayValue(value);

        if (timestamp === NOT_AVAILABLE)
            return timestamp;

        const date = new Date(timestamp);
        return Number.isNaN(date.getTime()) ? timestamp : date.toLocaleString('pt-BR');

    }

    formatPages(value) {

        return Number.isFinite(value) ? value.toLocaleString('pt-BR') : NOT_AVAILABLE;

    }

    formatColorToner(printer) {

        const components = [
            ['C', printer.tonerCyan],
            ['M', printer.tonerMagenta],
            ['Y', printer.tonerYellow]
        ].filter(([, value]) => Number.isFinite(value));

        return components.length
            ? components.map(([label, value]) => `${label}: ${value}%`).join(' · ')
            : NOT_AVAILABLE;

    }

    normalizeEntries(entries) {

        const printers = new Map();

        entries
            .filter(entry => entry?.category === 'Printers')
            .forEach(entry => {
                const message = String(entry.message || '');
                const online = message.match(/^(.+?) \(([^)]+)\) online \((\d+)ms\)$/);
                const offline = message.match(/^(.+?) \(([^)]+)\) offline$/);
                const toner = message.match(/^Toner preto crítico em (.+?) \((\d+)%\)$/);
                const match = online || offline || toner;

                if (!match)
                    return;

                const name = match[1];
                const printer = printers.get(name) || {
                    name,
                    ip: NOT_AVAILABLE,
                    status: 'unknown',
                    responseTime: null,
                    tonerBlack: null,
                    warning: false
                };

                if (online) {
                    printer.ip = online[2];
                    printer.status = 'online';
                    printer.responseTime = Number(online[3]);
                } else if (offline) {
                    printer.ip = offline[2];
                    printer.status = 'offline';
                } else if (toner) {
                    printer.tonerBlack = Number(toner[2]);
                    printer.warning = true;
                }

                printers.set(name, printer);
            });

        return [...printers.values()].sort((a, b) => {
            const rank = { offline: 0, warning: 1, online: 2, unknown: 3 };
            const rankA = a.status === 'online' && a.warning ? rank.warning : rank[a.status];
            const rankB = b.status === 'online' && b.warning ? rank.warning : rank[b.status];
            return rankA - rankB || a.name.localeCompare(b.name);
        });

    }

    renderSummary(printers, structuredSummary = null) {

        const summary = document.createElement('section');
        summary.className = 'printers-summary';

        const responseTimes = printers
            .map(printer => printer.responseTime)
            .filter(value => Number.isFinite(value));

        const summaryNumber = key => this.validNumber(structuredSummary?.[key]);
        const total = summaryNumber('total');
        const online = summaryNumber('online');
        const offline = summaryNumber('offline');
        const warnings = summaryNumber('warnings');

        const metrics = [
            ['Total', total ?? printers.length],
            ['Online', online ?? printers.filter(printer => printer.status === 'online').length],
            ['Offline', offline ?? printers.filter(printer => printer.status === 'offline').length],
            ['Tempo médio', responseTimes.length ? `${Math.round(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)} ms` : NOT_AVAILABLE],
            ['Toner crítico', warnings ?? printers.filter(printer => printer.warning).length],
            ['Maior latência', responseTimes.length ? `${Math.max(...responseTimes)} ms` : NOT_AVAILABLE]
        ];

        metrics.forEach(([label, value]) => {
            const card = document.createElement('article');
            card.className = 'printer-summary-card';

            const title = document.createElement('span');
            title.className = 'printer-summary-label';
            title.textContent = label;

            const content = document.createElement('strong');
            content.className = 'printer-summary-value';
            content.textContent = String(value);

            card.append(title, content);
            summary.appendChild(card);
        });

        return summary;

    }

    renderCard(printer) {

        const card = document.createElement('article');
        const statusClass = printer.status === 'online' && printer.warning ? 'warning' : printer.status;
        card.className = `printer-card printer-status-${statusClass}`;

        const header = document.createElement('header');
        header.className = 'printer-card-header';

        const name = document.createElement('h3');
        name.textContent = printer.name;

        header.append(name, this.renderStatusBadge(printer.status, printer.warning));
        card.appendChild(header);

        const identity = document.createElement('dl');
        identity.className = 'printer-identity';

        [
            ['IP', printer.ip],
            ['Modelo', printer.model ?? NOT_AVAILABLE],
            ['Firmware', printer.firmware ?? NOT_AVAILABLE],
            ['Serial', printer.serial ?? NOT_AVAILABLE],
            ['MAC', printer.mac ?? NOT_AVAILABLE],
            ['Local', printer.location ?? NOT_AVAILABLE],
            ['Descrição', printer.description ?? NOT_AVAILABLE],
            ['Erros', printer.errors ?? NOT_AVAILABLE]
        ].forEach(([label, value]) => {
            const term = document.createElement('dt');
            term.textContent = `${label}:`;
            const description = document.createElement('dd');
            description.textContent = value;
            identity.append(term, description);
        });

        card.append(identity, this.renderMetrics(printer));
        card.append(
            this.renderProgressBar('Toner preto', printer.tonerBlack),
            this.renderProgressBar('Toner colorido', null, this.formatColorToner(printer)),
            this.renderProgressBar('Papel', printer.paperPercent),
            this.renderProgressBar('Drum', printer.drumPercent)
        );

        const collection = document.createElement('small');
        collection.className = 'printer-last-collection';
        collection.textContent = `Última coleta: ${printer.lastCollection ?? NOT_AVAILABLE}`;
        card.appendChild(collection);

        return card;

    }

    renderProgressBar(label, value, formattedValue = null) {

        const wrapper = document.createElement('div');
        wrapper.className = 'printer-progress';

        const heading = document.createElement('div');
        heading.className = 'printer-progress-heading';
        heading.textContent = label;

        const valueLabel = document.createElement('span');
        valueLabel.textContent = formattedValue ?? (Number.isFinite(value) ? `${value}%` : NOT_AVAILABLE);
        heading.appendChild(valueLabel);

        const track = document.createElement('div');
        track.className = 'printer-progress-track';

        if (Number.isFinite(value)) {
            const fill = document.createElement('div');
            fill.className = 'printer-progress-fill';
            fill.style.width = `${Math.max(0, Math.min(100, value))}%`;
            track.appendChild(fill);
        }

        wrapper.append(heading, track);
        return wrapper;

    }

    renderStatusBadge(status, warning = false) {

        const badge = document.createElement('span');
        const effectiveStatus = status === 'online' && warning ? 'warning' : status;
        const labels = {
            online: 'ONLINE',
            offline: 'OFFLINE',
            warning: 'WARNING',
            unknown: NOT_AVAILABLE
        };

        badge.className = `printer-status-badge printer-status-${effectiveStatus}`;
        badge.textContent = labels[effectiveStatus] || labels.unknown;
        return badge;

    }

    renderMetrics(printer) {

        const metrics = document.createElement('dl');
        metrics.className = 'printer-metrics';

        [
            ['Tempo resposta', Number.isFinite(printer.responseTime) ? `${printer.responseTime} ms` : NOT_AVAILABLE],
            ['Uptime', printer.uptime ?? NOT_AVAILABLE],
            ['Páginas', this.formatPages(printer.totalPages)]
        ].forEach(([label, value]) => {
            const term = document.createElement('dt');
            term.textContent = `${label}:`;
            const description = document.createElement('dd');
            description.textContent = value;
            metrics.append(term, description);
        });

        return metrics;

    }

}
