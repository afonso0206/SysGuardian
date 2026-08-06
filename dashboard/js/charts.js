import { DashboardStore } from "./store.js";
import { createSVGElement } from "./utils.js";

export class ChartsComponent {

    constructor() {

        this.radarSize = 300;
        this.radius = 90;

    }

    renderRadar(containerId, categoryScores = null) {

        const container = document.getElementById(containerId);

        if (!container)
            return;

        container.replaceChildren();

        const scores =
            categoryScores ||
            DashboardStore.categories();

        const categories =

            Object.entries(scores)

                .sort((a, b) => a[0].localeCompare(b[0]));

        if (!categories.length)
            return;
const svg = createSVGElement("svg", {

    viewBox: "0 0 300 300",

    width: "300",

    height: "300",

    preserveAspectRatio: "xMidYMid meet"

});
        const cx = 150;
        const cy = 150;
        const total = categories.length;

        /*
         * Grid
         */

        [0.25,0.50,0.75,1].forEach(level=>{

            let pts="";

            categories.forEach((_,i)=>{

                const angle=

                    ((Math.PI*2)/total)*i

                    -

                    Math.PI/2;

                const x=

                    cx+

                    this.radius*

                    level*

                    Math.cos(angle);

                const y=

                    cy+

                    this.radius*

                    level*

                    Math.sin(angle);

                pts+=`${x},${y} `;

            });

            svg.appendChild(

                createSVGElement(

                    "polygon",

                    {

                        points:pts.trim(),

                        fill:"none",

                        stroke:"var(--border-color)",

                        "stroke-width":"1"

                    }

                )

            );

        });

        /*
         * Eixos
         */

        categories.forEach(([category],i)=>{

            const angle=

                ((Math.PI*2)/total)*i

                -

                Math.PI/2;

            const x=

                cx+

                this.radius*

                Math.cos(angle);

            const y=

                cy+

                this.radius*

                Math.sin(angle);

            svg.appendChild(

                createSVGElement(

                    "line",

                    {

                        x1:cx,

                        y1:cy,

                        x2:x,

                        y2:y,

                        stroke:"var(--border-color)",

                        "stroke-width":"1"

                    }

                )

            );

            const label=

                createSVGElement(

                    "text",

                    {

                        x:cx+(this.radius+18)*Math.cos(angle),

                        y:cy+(this.radius+18)*Math.sin(angle),

                        "text-anchor":"middle",

                        "font-size":"10",

                        fill:"var(--text-secondary)"

                    }

                );

            label.textContent=category;

            svg.appendChild(label);

        });

        /*
         * Polígono dos dados
         */

        let points="";

        categories.forEach(([_,score],i)=>{

            const angle=

                ((Math.PI*2)/total)*i

                -

                Math.PI/2;

            const r=

                this.radius*

                (score/100);

            const x=

                cx+r*Math.cos(angle);

            const y=

                cy+r*Math.sin(angle);

            points+=`${x},${y} `;

        });

        svg.appendChild(

            createSVGElement(

                "polygon",

                {

                    points:points.trim(),

                    fill:"rgba(59,130,246,.25)",

                    stroke:"var(--color-bom)",

                    "stroke-width":"2"

                }

            )

        );

        /*
         * Pontos
         */

        categories.forEach(([_,score],i)=>{

            const angle=

                ((Math.PI*2)/total)*i

                -

                Math.PI/2;

            const r=

                this.radius*

                (score/100);

            svg.appendChild(

                createSVGElement(

                    "circle",

                    {

                        cx:cx+r*Math.cos(angle),

                        cy:cy+r*Math.sin(angle),

                        r:"3",

                        fill:"var(--color-bom)"

                    }

                )

            );

        });

        container.appendChild(svg);

    }

    renderDonutAlerts(containerId, entries = null) {

        const container=document.getElementById(containerId);

        if(!container)
            return;

        container.replaceChildren();

        const list=

            entries ||

            DashboardStore.entries();

        const counters={

            OK:0,

            WARN:0,

            ERROR:0

        };

        list.forEach(item=>{

            if(counters[item.level]!==undefined)

                counters[item.level]++;

        });

        const total=

            Object.values(counters)

                .reduce((a,b)=>a+b,0)

            ||1;

        const svg=

            createSVGElement("svg",{

                viewBox:"0 0 220 220",

                width:"220",

                height:"220",

                preserveAspectRatio: "xMidYMid meet"

            });

        let offset=0;

        const circumference=314.159;

        [

            ["OK","var(--color-excelente)"],

            ["WARN","var(--level-warn)"],

            ["ERROR","var(--level-error)"]

        ].forEach(([level,color])=>{

            const percent=

                counters[level]/total;

            svg.appendChild(

                createSVGElement(

                    "circle",

                    {

                        cx:110,

                        cy:110,

                        r:50,

                        fill:"none",

                        stroke:color,

                        "stroke-width":18,

                        "stroke-dasharray":

                            `${percent*circumference} ${circumference}`,

                        "stroke-dashoffset":-offset,

                        transform:"rotate(-90 110 110)"

                    }

                )

            );

            offset+=percent*circumference;

        });

        container.appendChild(svg);

    }

}
