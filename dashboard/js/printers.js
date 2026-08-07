import { escapeHTML } from './utils.js';

export class PrintersComponent {

    render(containerId, entries = []) {

        const container = document.getElementById(containerId);

        if (!container)
            return;

        container.replaceChildren();

        const printerEntries = entries.filter(entry =>
            entry.category === 'Printers'
        );

        if (!printerEntries.length) {
            const empty = document.createElement('article');
            empty.className = 'alert-item level-ok';
            empty.textContent = 'Nenhum evento de impressora disponível.';
            container.appendChild(empty);
            return;
        }

        printerEntries.forEach(entry => {
            const item = document.createElement('article');
            const level = entry.level || 'INFO';

            item.className = `alert-item level-${level.toLowerCase()}`;

            const message = document.createElement('span');
            message.className = 'alert-message';
            message.textContent = escapeHTML(entry.message || 'Sem detalhes.');

            const tag = document.createElement('span');
            tag.className = `alert-tag level-${level.toLowerCase()}`;
            tag.textContent = level;

            item.append(message, tag);
            container.appendChild(item);
        });

    }

}
