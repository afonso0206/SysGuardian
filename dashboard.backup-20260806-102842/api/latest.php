<?php

header('Content-Type: application/json; charset=utf-8');

$files = glob('/var/log/sysguardian/*.json');

if (!$files) {
    http_response_code(404);
    echo json_encode([
        "status" => "error",
        "message" => "Nenhum relatório encontrado."
    ]);
    exit;
}

usort($files, function($a, $b) {
    return filemtime($b) - filemtime($a);
});

readfile($files[0]);
