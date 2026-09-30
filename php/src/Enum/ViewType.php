<?php

declare(strict_types=1);

namespace PhpPayway\Enum;

/** How the hosted payment page is shown (`view_type`). */
enum ViewType: string
{
    /** redirect the payer to a new tab */
    case HostedView = 'hosted_view';

    /** bottom sheet on mobile browsers, modal popup on desktop browsers */
    case Popup = 'popup';
}
