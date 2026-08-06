import { DashboardStore } from "./store.js";
import { escapeHTML, formatDate } from "./utils.js";
import { CONFIG } from "./config.js";

const LEVEL_ICONS = Object.freeze({

    ERROR: "⛔",
    WARN: "⚠️",
    INFO: "ℹ️",
    OK: "✅"

});

export class HistoryComponent {

    constructor() {

        this.container = null;

    }

    renderTimeline(containerId, entries = null) {

        this.container = document.getElementById(containerId);

        if (!this.container)
            return;

        this.container.replaceChildren();

        const history =

            (entries || DashboardStore.entries())

            .slice(0, CONFIG.DASHBOARD.MAX_ALERTS);

        if (!history.length) {

            this.container.appendChild(

                this.createEmpty()

            );

            return;

        }

        const timeline =

            document.createElement("div");

        timeline.className =

            "timeline-container";

        history.forEach(entry => {

            timeline.appendChild(

                this.createEvent(entry)

            );

        });

        this.container.appendChild(timeline);

    }

    createEvent(entry) {

        const item =

            document.createElement("article");

        item.className =

            `timeline-event level-${(entry.level || "INFO").toLowerCase()}`;

        item.dataset.level =

            entry.level;

        item.dataset.category =

            entry.category;

        /*
         * Ponto
         */

        const point =

            document.createElement("div");

        point.className =

            "timeline-point";

        /*
         * Conteúdo
         */

        const content =

            document.createElement("div");

        content.className =

            "timeline-content";

        /*
         * Cabeçalho
         */

        const header =

            document.createElement("div");

        header.className =

            "timeline-header";

        const icon =

            document.createElement("span");

        icon.className =

            "timeline-icon";

        icon.textContent =

            LEVEL_ICONS[entry.level] || "📄";

        const category =

            document.createElement("strong");

        category.textContent =

            escapeHTML(entry.category);

        header.append(

            icon,

            category

        );

        /*
         * Mensagem
         */

        const message =

            document.createElement("div");

        message.className =

            "timeline-message";

        message.textContent =

            escapeHTML(entry.message);

        /*
         * Data (quando existir)
         */

        if (entry.date) {

            const date =

                document.createElement("small");

            date.className =

                "timeline-date";

            date.textContent =

                formatDate(entry.date);

            content.appendChild(date);

        }

        content.prepend(

            header,

            message

        );

        item.append(

            point,

            content

        );

        return item;

    }

    createEmpty() {

        const empty =

            document.createElement("div");

        empty.className =

            "timeline-empty";

        empty.textContent =

            "Nenhum evento disponível.";

        return empty;

    }

}
