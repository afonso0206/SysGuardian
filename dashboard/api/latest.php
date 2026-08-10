<?php

require_once __DIR__ . '/report-source.php';

header('Content-Type: application/json; charset=utf-8');

$latest = sysguardian_latest_report();

if ($latest === null) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "message" => "Nenhum relatório encontrado."
    ]);
    exit;
}

readfile($latest);
