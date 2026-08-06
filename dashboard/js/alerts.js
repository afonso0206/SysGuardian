import { DashboardStore } from "./store.js";
import { escapeHTML } from "./utils.js";
import { CONFIG } from "./config.js";

const LEVEL_PRIORITY = Object.freeze({

    ERROR: 0,
    WARN: 1,
    INFO: 2,
    OK: 3

});

const LEVEL_ICON = Object.freeze({

    ERROR: "⛔",
    WARN: "⚠️",
    INFO: "ℹ️",
    OK: "✅"

});

export class AlertsComponent {

    constructor() {

        this.container = null;

    }

    render(containerId, entries = null) {

        this.container = document.getElementById(containerId);

        if (!this.container)
            return;

        this.container.replaceChildren();

        const alerts =

            (entries || DashboardStore.alerts())

            .filter(item =>

                item.level === "WARN" ||

                item.level === "ERROR"

            )

            .sort((a, b) =>

                LEVEL_PRIORITY[a.level] -

                LEVEL_PRIORITY[b.level]

            )

            .slice(

                0,

                CONFIG.DASHBOARD.MAX_ALERTS

            );

        if (!alerts.length) {

            this.container.appendChild(

                this.createEmpty()

            );

            return;

        }

        alerts.forEach(alert => {

            this.container.appendChild(

                this.createAlert(alert)

            );

        });

    }

    createAlert(alert) {

        const wrapper =

            document.createElement("article");

        wrapper.className =

            `alert-item level-${alert.level.toLowerCase()} animate-fade-in`;

        wrapper.dataset.level = alert.level;

        wrapper.dataset.category = alert.category;

        /*
         * Conteúdo
         */

        const content =

            document.createElement("div");

        content.className =

            "alert-content";

        const category =

            document.createElement("span");

        category.className =

            "alert-category";

        category.textContent =

            `${LEVEL_ICON[alert.level]} ${escapeHTML(alert.category)}`;

        const message =

            document.createElement("span");

        message.className =

            "alert-message";

        message.textContent =

            escapeHTML(alert.message);

        content.append(

            category,

            message

        );

        /*
         * Badge
         */

        const tag =

            document.createElement("span");

        tag.className =

            `alert-tag level-${alert.level.toLowerCase()}`;

        tag.textContent =

            alert.level;

        wrapper.append(

            content,

            tag

        );

        return wrapper;

    }

    createEmpty() {

        const wrapper =

            document.createElement("article");

        wrapper.className =

            "alert-item level-ok";

        const icon =

            document.createElement("span");

        icon.textContent =

            "✅";

        const text =

            document.createElement("span");

        text.className =

            "alert-message";

        text.textContent =

            "Nenhum alerta crítico encontrado.";

        wrapper.append(

            icon,

            text

        );

        return wrapper;

    }

}
