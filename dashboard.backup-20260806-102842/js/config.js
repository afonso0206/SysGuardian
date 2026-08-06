/**
 * ============================================================
 * SPA Router
 * ============================================================
 */

const Router = {

    initialize(){

        window.addEventListener(

            "hashchange",

            Router.navigate

        );

        Router.navigate();

    },

    navigate(){

        const page =

            location.hash.replace("#","")

            || "overview";

        STATE.currentPage = page;

    }

};
