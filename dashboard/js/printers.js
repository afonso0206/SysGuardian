const NOT_AVAILABLE = 'N/D';

export class PrintersComponent {

    render(containerId, entries = []) {

        const container = document.getElementById(containerId);

        if (!container)
            return;

        const printers = this.normalizeEntries(entries);
        const fragment = document.createDocumentFragment();

        fragment.appendChild(this.renderSummary(printers));

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

    renderSummary(printers) {

        const summary = document.createElement('section');
        summary.className = 'printers-summary';

        const responseTimes = printers
            .map(printer => printer.responseTime)
            .filter(value => Number.isFinite(value));

        const metrics = [
            ['Total', printers.length],
            ['Online', printers.filter(printer => printer.status === 'online').length],
            ['Offline', printers.filter(printer => printer.status === 'offline').length],
            ['Tempo médio', responseTimes.length ? `${Math.round(responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length)} ms` : NOT_AVAILABLE],
            ['Toner crítico', printers.filter(printer => printer.warning).length],
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
            ['Modelo', NOT_AVAILABLE],
            ['Firmware', NOT_AVAILABLE],
            ['Serial', NOT_AVAILABLE],
            ['MAC', NOT_AVAILABLE],
            ['Local', NOT_AVAILABLE]
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
            this.renderProgressBar('Toner colorido', null),
            this.renderProgressBar('Papel', null),
            this.renderProgressBar('Drum', null)
        );

        const collection = document.createElement('small');
        collection.className = 'printer-last-collection';
        collection.textContent = `Última coleta: ${NOT_AVAILABLE}`;
        card.appendChild(collection);

        return card;

    }

    renderProgressBar(label, value) {

        const wrapper = document.createElement('div');
        wrapper.className = 'printer-progress';

        const heading = document.createElement('div');
        heading.className = 'printer-progress-heading';
        heading.textContent = label;

        const valueLabel = document.createElement('span');
        valueLabel.textContent = Number.isFinite(value) ? `${value}%` : NOT_AVAILABLE;
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
            ['Uptime', NOT_AVAILABLE],
            ['Páginas', NOT_AVAILABLE]
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
