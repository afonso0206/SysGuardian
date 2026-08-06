export class Router {

    constructor(routes = {}) {

        this.routes = routes;

        this.currentRoute = null;

        this.beforeNavigate = null;

        this.afterNavigate = null;

        this.pages = [

            ...document.querySelectorAll(".view-page")

        ];

        this.navigation = [

            ...document.querySelectorAll(".nav-item")

        ];

        window.addEventListener(

            "hashchange",

            () => this.handleRoute()

        );

    }

    init() {

        this.handleRoute();

    }

    onBeforeNavigate(callback) {

        this.beforeNavigate = callback;

    }

    onAfterNavigate(callback) {

        this.afterNavigate = callback;

    }

    handleRoute() {

        const hash =

            window.location.hash.replace("#","")

            || "overview";

        const target =

            this.routes[hash]

                ? hash

                : "overview";

        if (this.beforeNavigate)

            this.beforeNavigate(

                this.currentRoute,

                target

            );

        this.currentRoute = target;

        this.pages.forEach(page=>{

            page.classList.remove("active");

        });

        const active =

            document.getElementById(

                `view-${target}`

            );

        if(active)

            active.classList.add("active");

        this.navigation.forEach(item=>{

            item.classList.toggle(

                "active",

                item.dataset.route===target

            );

        });

        if(typeof this.routes[target]==="function")

            this.routes[target]();

        if(this.afterNavigate)

            this.afterNavigate(

                target

            );

    }

}
