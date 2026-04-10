<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Setting extends Model
{
    protected $fillable = [
        'mode',
        'ppm_min',
        'pump_delay',
    ];
}
