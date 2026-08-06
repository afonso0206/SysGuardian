import { DashboardStore } from "./store.js";
import { escapeHTML, formatDate } from "./utils.js";

export class HeaderComponent {

    constructor() {

        this.elements = {

            hostname: document.getElementById("headerHostname"),

            version: document.getElementById("headerVersion"),

            date: document.getElementById("headerDate"),

            score: document.getElementById("headerScore"),

            classification: document.getElementById("headerClassification"),

            lastUpdate: document.getElementById("headerLastUpdate")

        };

    }

    updateMeta(metadata) {

        if (!metadata)
            return;

        this.setText(this.elements.hostname, metadata.hostname);
        this.setText(this.elements.version, metadata.version);
        this.setText(this.elements.date, metadata.date);
        this.setText(this.elements.score, metadata.score);
        this.setText(this.elements.classification, metadata.classification);

    }

    setUpdateTimestamp() {

        this.updateTimestamp();

    }
    
    update() {

        const metadata = DashboardStore.metadata();

        if (!metadata)
            return;

        this.setText(

            this.elements.hostname,

            metadata.hostname

        );

        this.setText(

            this.elements.version,

            metadata.version

        );

        this.setText(

            this.elements.date,

            metadata.date

        );

        this.setText(

            this.elements.score,

            metadata.score

        );

        this.setText(

            this.elements.classification,

            metadata.classification

        );

        this.updateTimestamp();

    }

    updateTimestamp() {

        if (!this.elements.lastUpdate)
            return;

        this.elements.lastUpdate.textContent =

            formatDate(new Date());

    }

    setText(element, value) {

        if (!element)
            return;

        element.textContent =

            escapeHTML(

                String(

                    value ?? "N/A"

                )

            );

    }

}
