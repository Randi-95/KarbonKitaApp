<?php

namespace Database\Seeders;

use App\Models\Mission;
use Illuminate\Database\Seeder;

class MissionSeeder extends Seeder
{
    public function run(): void
    {
        $missions = [
            [
                'title' => 'Pejuang Pedal 2Km',
                'description' => 'Catat aktivitas bersepeda atau berjalan kaki minimal 2km dan dapatkan poin!',
                'category' => 'mobility',
                'xp_reward' => 150,
                'points_reward' => 50,
                'icon' => 'directions_bike',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Pahlawan Plastik Terpilah',
                'description' => 'Ambil foto hasil pilah sampahmu dan dapatkan poin!',
                'validation_prompt' => 'Foto harus menunjukkan sampah PLASTIK yang sudah dipilah dan dikumpulkan terpisah dalam wadah atau kantong khusus. Tolak foto yang sampahnya tercampur, bukan plastik, atau tidak menunjukkan upaya pemilahan.',
                'category' => 'waste',
                'xp_reward' => 300,
                'points_reward' => 100,
                'icon' => 'recycling',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Donasi Pohon Mangrove',
                'description' => 'Donasikan pohon mangrove untuk menjaga garis pantai!',
                'validation_prompt' => null,
                'category' => 'donation',
                'xp_reward' => 100,
                'points_reward' => 25,
                'icon' => 'park',
                'max_participants' => 100,
                'is_active' => true,
            ],
            [
                'title' => 'Kuis Hijau Harian',
                'description' => 'Kerjakan kuis harian untuk tetap memperpanjang streak-mu!',
                'category' => 'quiz',
                'xp_reward' => 50,
                'points_reward' => 20,
                'icon' => 'quiz',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Petualangan Kuis Hijau',
                'description' => 'Jawab pertanyaan lingkungan dan dapatkan bonus XP!',
                'category' => 'quiz',
                'xp_reward' => 30,
                'points_reward' => 15,
                'icon' => 'school',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Sepeda Pagi Hari',
                'description' => 'Bersepeda pagi minimal 5km untuk mendapatkan XP bonus!',
                'category' => 'mobility',
                'xp_reward' => 200,
                'points_reward' => 75,
                'icon' => 'wb_sunny',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Pilah Sampah Elektronik',
                'description' => 'Pilah sampah elektronik dengan benar dan dapatkan poin!',
                'validation_prompt' => 'Foto harus menunjukkan sampah ELEKTRONIK yang sudah dipilah dan dikumpulkan terpisah. Tolak foto yang bukan e-waste atau tercampur sampah lain.',
                'category' => 'waste',
                'xp_reward' => 250,
                'points_reward' => 80,
                'icon' => 'memory',
                'max_participants' => null,
                'is_active' => true,
            ],
            [
                'title' => 'Jalan Kaki 3Km',
                'description' => 'Berjalan kaki minimal 3km untuk gaya hidup sehat dan ramah lingkungan!',
                'category' => 'mobility',
                'xp_reward' => 100,
                'points_reward' => 40,
                'icon' => 'directions_walk',
                'max_participants' => null,
                'is_active' => true,
            ],
        ];

        foreach ($missions as $mission) {
            Mission::create($mission);
        }
    }
}
