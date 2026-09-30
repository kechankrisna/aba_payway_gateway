<?php

declare(strict_types=1);

// Code style of the PHP SDK: PER Coding Style (PHP-FIG), the successor of PSR-12.
$finder = PhpCsFixer\Finder::create()
    ->in([__DIR__ . '/php/src', __DIR__ . '/php/tests'])
    ->append([__FILE__]);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PER-CS' => true,
        '@PHP83Migration' => true,
        'declare_strict_types' => true,
        'no_unused_imports' => true,
        'ordered_imports' => ['imports_order' => ['class', 'function', 'const']],
    ])
    ->setFinder($finder)
    ->setCacheFile(__DIR__ . '/.php-cs-fixer.cache');
