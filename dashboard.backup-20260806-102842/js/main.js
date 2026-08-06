document.addEventListener("DOMContentLoaded", async ()=>{

    const report = await API.loadLatestReport();

    if(!report){

        console.warn("Nenhum relatório encontrado.");

        return;

    }

    document.getElementById("hostname").textContent =
        "Host: " + report.metadata.hostname;

    document.getElementById("datetime").textContent =
        "Data: " + report.metadata.date;

    document.getElementById("scoreGauge").textContent =
        report.metadata.score + "%";

    document.getElementById("classification").textContent =
        report.metadata.classification;

});
