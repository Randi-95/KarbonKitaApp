<?php

namespace Database\Seeders;

use App\Models\Mission;
use App\Models\Quiz;
use Illuminate\Database\Seeder;

class QuizSeeder extends Seeder
{
    public function run(): void
    {
        $missions = Mission::where('category', 'quiz')->get();

        if ($missions->isEmpty()) {
            return;
        }

        // Questions pool — distributed across quiz missions round-robin
        $questions = [
            [
                'question' => 'Berapa persen sampah di Indonesia yang belum terkelola dengan baik?',
                'options' => ['A' => 'Sekitar 30%', 'B' => 'Sekitar 45%', 'C' => 'Sekitar 60%', 'D' => 'Sekitar 75%'],
                'correct_answer' => 'C',
                'explanation' => 'Data KLHK menyebut ~60% sampah belum terkelola optimal, sehingga pemilahan di sumber sangat penting.',
            ],
            [
                'question' => 'Warna tempat sampah untuk sampah anorganik yang dapat didaur ulang adalah?',
                'options' => ['A' => 'Hijau', 'B' => 'Kuning', 'C' => 'Merah', 'D' => 'Biru'],
                'correct_answer' => 'B',
                'explanation' => 'Kuning untuk anorganik daur ulang (plastik, kertas), hijau untuk organik.',
            ],
            [
                'question' => 'Bersepeda 5 km menggantikan motor dapat menghemat emisi CO2 sekitar?',
                'options' => ['A' => '0,2 kg CO2', 'B' => '0,6 kg CO2', 'C' => '1,2 kg CO2', 'D' => '2,5 kg CO2'],
                'correct_answer' => 'B',
                'explanation' => 'Motor rata-rata ~120g CO2/km, jadi 5 km ≈ 0,6 kg CO2 yang dihemat.',
            ],
            [
                'question' => 'Manakah yang termasuk sampah B3 rumah tangga?',
                'options' => ['A' => 'Botol plastik', 'B' => 'Sisa makanan', 'C' => 'Baterai bekas', 'D' => 'Kardus'],
                'correct_answer' => 'C',
                'explanation' => 'Baterai mengandung logam berat dan termasuk B3, jangan buang ke sampah biasa.',
            ],
            [
                'question' => 'Gerakan 3R yang paling efektif mengurangi sampah adalah?',
                'options' => ['A' => 'Recycle', 'B' => 'Reuse', 'C' => 'Reduce', 'D' => 'Replace'],
                'correct_answer' => 'C',
                'explanation' => 'Reduce (kurangi) di hulu paling berdampak sebelum sampah tercipta.',
            ],
            [
                'question' => 'Jalan kaki 30 menit membakar kalori sekitar?',
                'options' => ['A' => '50-70 kkal', 'B' => '90-120 kkal', 'C' => '200-250 kkal', 'D' => '300-350 kkal'],
                'correct_answer' => 'B',
                'explanation' => 'Jalan kaki sedang ~90-120 kkal per 30 menit tergantung berat badan.',
            ],
            [
                'question' => 'Sampah organik sebaiknya diolah menjadi?',
                'options' => ['A' => 'Paving block', 'B' => 'Kompos', 'C' => 'Kertas daur ulang', 'D' => 'Plastik daur ulang'],
                'correct_answer' => 'B',
                'explanation' => 'Sisa makanan/daun cocok jadi kompos untuk kesuburan tanah.',
            ],
            [
                'question' => 'Berapa lama botol plastik terurai di alam?',
                'options' => ['A' => '10-20 tahun', 'B' => '50-80 tahun', 'C' => '200-500 tahun', 'D' => '5 tahun'],
                'correct_answer' => 'C',
                'explanation' => 'Botol PET butuh ratusan tahun terurai, jadi kurangi & daur ulang.',
            ],
            [
                'question' => 'Transportasi ramah karbon terbaik untuk jarak <3 km adalah?',
                'options' => ['A' => 'Motor', 'B' => 'Mobil', 'C' => 'Jalan kaki / sepeda', 'D' => 'Ojek online mobil'],
                'correct_answer' => 'C',
                'explanation' => 'Jalan kaki/sepeda nol emisi dan menyehatkan untuk jarak dekat.',
            ],
            [
                'question' => 'Simbol segitiga daur ulang dengan angka 1 (PET) berarti?',
                'options' => ['A' => 'Aman untuk panas tinggi', 'B' => 'Sekali pakai, daur ulang', 'C' => 'Bisa jadi kompos', 'D' => 'Mengandung B3'],
                'correct_answer' => 'B',
                'explanation' => 'PET kode 1 ideal untuk sekali pakai dan dapat didaur ulang.',
            ],
        ];

        $order = 1;
        foreach ($questions as $idx => $q) {
            $mission = $missions[$idx % $missions->count()];
            Quiz::create([
                'mission_id' => $mission->id,
                'question' => $q['question'],
                'options' => $q['options'],
                'correct_answer' => $q['correct_answer'],
                'explanation' => $q['explanation'],
                'order' => $order++,
            ]);
        }
    }
}
