import { DashboardStore } from "./store.js";
import { getScoreMetadata, escapeHTML } from "./utils.js";

const CATEGORY_ICONS = Object.freeze({

    System: "🖥",
    CPU: "🧠",
    Memory: "💾",
    Disks: "💽",
    LVM: "🧱",
    SMART: "💿",
    Network: "🌐",
    Security: "🛡",
    Backup: "📦",
    Logs: "📜",
    Docker: "🐳",
    Apache: "🌍",
    PHP: "🐘",
    MySQL: "🗄",
    TRIM: "✂",
    Hardware: "⚙"

});

export class CardsComponent {

    constructor() {

        this.container = null;

    }

    render(containerId, categoryScores = null) {

        this.container = document.getElementById(containerId);

        if (!this.container)
            return;

        this.container.replaceChildren();

        const scores =

            categoryScores ||

            DashboardStore.categories();

        if (!scores)
            return;

        const orderedCategories =

            Object.entries(scores)

                .sort((a, b) => a[1] - b[1]);

        orderedCategories.forEach(

            ([category, score]) => {

                this.container.appendChild(

                    this.createCard(

                        category,

                        score

                    )

                );

            }

        );

    }

    createCard(category, score) {

        const meta =

            getScoreMetadata(score);

        const card =

            document.createElement("article");

        card.className =

            "metric-card animate-fade-in";

        card.dataset.category = category;

        /*
         * Cabeçalho
         */

        const top =

            document.createElement("div");

        top.className = "card-top";

        const titleGroup =

            document.createElement("div");

        titleGroup.className =

            "card-title-group";

        const icon =

            document.createElement("span");

        icon.className =

            "card-icon";

        icon.textContent =

            CATEGORY_ICONS[category] || "📊";

        const title =

            document.createElement("span");

        title.className =

            "card-name";

        title.textContent =

            escapeHTML(category);

        titleGroup.append(

            icon,

            title

        );

        const value =

            document.createElement("span");

        value.className =

            "card-score";

        value.textContent = `${score}%`;

        value.style.color = meta.color;

        top.append(

            titleGroup,

            value

        );

        /*
         * Barra
         */

        const track =

            document.createElement("div");

        track.className =

            "card-progress-track";

        const progress =

            document.createElement("div");

        progress.className =

            "card-progress-bar";

        progress.style.width = "0%";

        progress.style.backgroundColor =

            meta.color;

        progress.style.transition =

            "width .8s ease";

        track.appendChild(progress);

        requestAnimationFrame(() => {

            progress.style.width = `${score}%`;

        });

        /*
         * Rodapé
         */

        const footer =

            document.createElement("div");

        footer.className =

            "card-footer";

        const label =

            document.createElement("span");

        label.textContent =

            "Status";

        const badge =

            document.createElement("span");

        badge.className =

            "status-badge";

        badge.textContent =

            meta.label;

        badge.style.backgroundColor =

            meta.color;

        badge.style.borderColor =

            meta.color;

        badge.style.color = "#fff";

        footer.append(

            label,

            badge

        );

        /*
         * Montagem
         */

        card.append(

            top,

            track,

            footer

        );

        return card;

    }

}
