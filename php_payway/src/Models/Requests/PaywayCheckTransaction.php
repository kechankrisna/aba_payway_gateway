<?php
declare(strict_types=1);

namespace PhpPayway\Models\Requests;

class PaywayCheckTransaction
{

    public function __construct(
        public string $tran_id,
        public string $req_time,
    )
    {
        //
    }

    public function copyWith(
        ?string $tran_id = null,
        ?string $req_time = null,
    )
    {
        $copy = clone($this);
        $this->tran_id = $tran_id ?? $copy->tran_id;
        $this->req_time = $req_time ?? $copy->req_time;
    }

    public function toMap(): array
    {
        return [
            'tran_id' => $this->tran_id,
            'req_time' => $this->req_time,
        ];
    }
}