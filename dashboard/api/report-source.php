<?php

function sysguardian_latest_report(): ?string
{
    $files = glob('/var/log/sysguardian/*.json');
    $files = array_values(array_filter($files ?: [], function($file) {
        return is_file($file) && is_readable($file);
    }));

    if (!$files) {
        return null;
    }

    $now = time();
    $timezone = new DateTimeZone(date_default_timezone_get());
    $validReports = [];

    foreach ($files as $file) {
        if (!preg_match('/^report_(\d{8}_\d{6})\.json$/', basename($file), $matches)) {
            continue;
        }

        $reportDate = DateTimeImmutable::createFromFormat('!Ymd_His', $matches[1], $timezone);
        $dateErrors = DateTimeImmutable::getLastErrors();

        if ($reportDate === false ||
            ($dateErrors !== false && ($dateErrors['warning_count'] > 0 || $dateErrors['error_count'] > 0)) ||
            $reportDate->format('Ymd_His') !== $matches[1] ||
            $reportDate->getTimestamp() > $now) {
            continue;
        }

        $validReports[] = [
            'file' => $file,
            'timestamp' => $reportDate->getTimestamp()
        ];
    }

    if ($validReports) {
        usort($validReports, function($a, $b) {
            return $b['timestamp'] <=> $a['timestamp'];
        });

        return $validReports[0]['file'];
    }

    usort($files, function($a, $b) {
        return filemtime($b) <=> filemtime($a);
    });

    return $files[0];
}
