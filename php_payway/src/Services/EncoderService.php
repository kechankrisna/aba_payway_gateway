<?php

namespace PhpPayway\Services;

class EncoderService
{

    /**
     * @param mixed|null $v
     * @return string
     */
    static function base64_encode(mixed $v = null) : string {
        if($v == null) return "";
        if(gettype($v) == 'string') return base64_encode($v);
        $json = json_encode((array) $v);
        return base64_encode($json);
    }

    /**
     * should return array of array as the result
     * @param string|null $v
     * @return null|string|array []
     */
    static function base64_decode(?string $v = null): array|string|null
    {
        if($v == null || $v == '') return null;
        $str = base64_decode($v);
        $decoded = json_decode($str);
        if($decoded == null) return $str;
        return array_map(fn($e) => (array) $e, $decoded);
    }
}