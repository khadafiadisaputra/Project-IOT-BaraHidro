<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('sensor_data', function (Blueprint $table) {
            if (!Schema::hasColumn('sensor_data', 'temperature')) {
                $table->float('temperature')->after('id');
            }
            if (!Schema::hasColumn('sensor_data', 'ppm')) {
                $table->integer('ppm')->after('temperature');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sensor_data', function (Blueprint $table) {
            if (Schema::hasColumn('sensor_data', 'ppm')) {
                $table->dropColumn('ppm');
            }
            if (Schema::hasColumn('sensor_data', 'temperature')) {
                $table->dropColumn('temperature');
            }
        });
    }
};
