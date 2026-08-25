# Entity Relationship Diagram (ERD) - KarbonKita

Diagram ini menggunakan standar **Mermaid.js**. Anda dapat melihat diagram ini secara visual dengan menggunakan ekstensi Markdown Preview yang mendukung Mermaid di VSCode (seperti *Markdown Preview Mermaid Support*) atau dengan mem-paste kode di bawah ini ke [Mermaid Live Editor](https://mermaid.live).

```mermaid
erDiagram

    %% ----------------------------------------------------
    %% CORE AUTHENTICATION
    %% ----------------------------------------------------
    USERS {
        BIGINT id PK
        VARCHAR name
        VARCHAR email "UNIQUE"
        VARCHAR phone "UNIQUE"
        VARCHAR password
        ENUM role "'warga', 'mitra', 'super_admin'"
        TIMESTAMP created_at
    }

    %% ----------------------------------------------------
    %% PROFILES
    %% ----------------------------------------------------
    WARGA_PROFILES {
        BIGINT id PK
        BIGINT user_id FK
        VARCHAR city
        VARCHAR district
        VARCHAR sub_district
        VARCHAR rt
        VARCHAR rw
        INT level
        INT xp
        INT eco_points
        INT streak_count
        DECIMAL total_distance_km
        DECIMAL total_waste_kg
        DECIMAL total_carbon_saved_kg
    }

    MITRA_PROFILES {
        BIGINT id PK
        BIGINT user_id FK
        VARCHAR store_name
        VARCHAR category
        TEXT address
        VARCHAR bank_name
        VARCHAR bank_account_number
        VARCHAR xendit_external_id "UNIQUE"
        ENUM verification_status
        BOOLEAN is_open
        DECIMAL balance_saldo
    }

    %% ----------------------------------------------------
    %% GAMIFICATION & MISSIONS
    %% ----------------------------------------------------
    MISSIONS {
        BIGINT id PK
        VARCHAR title
        ENUM category "'mobility', 'waste', 'quiz'"
        INT reward_points
        INT reward_xp
        INT saga_level
        BOOLEAN is_active
    }

    USER_MISSIONS {
        BIGINT id PK
        BIGINT user_id FK
        BIGINT mission_id FK
        VARCHAR proof_image_url
        JSON ai_gemini_response
        DECIMAL confidence_score
        ENUM status "'pending', 'verified', 'rejected'"
        BOOLEAN anti_fraud_flagged
        TIMESTAMP verified_at
    }

    MOBILITY_LOGS {
        BIGINT id PK
        BIGINT user_id FK
        ENUM activity_type
        DECIMAL distance_km
        INT duration_seconds
        DECIMAL carbon_saved_kg
        INT points_earned
        JSON gps_coordinates_path
    }
    
    QUIZ_QUESTIONS {
        BIGINT id PK
        BIGINT mission_id FK
        TEXT question_text
        VARCHAR option_a
        VARCHAR option_b
        VARCHAR option_c
        VARCHAR option_d
        ENUM correct_option
        TEXT explanation
    }

    %% ----------------------------------------------------
    %% CIRCULAR ECONOMY (VOUCHERS & FINANCE)
    %% ----------------------------------------------------
    VOUCHERS {
        BIGINT id PK
        BIGINT mitra_profile_id FK
        VARCHAR title
        DECIMAL discount_value_idr
        INT points_price
        INT stock
        DATE expired_at
        BOOLEAN is_active
    }

    VOUCHER_CLAIMS {
        BIGINT id PK
        BIGINT user_id FK
        BIGINT voucher_id FK
        VARCHAR unique_code "UNIQUE"
        ENUM status "'unused', 'used', 'expired'"
        TIMESTAMP claimed_at
        TIMESTAMP used_at
    }

    POINT_TRANSACTIONS {
        BIGINT id PK
        BIGINT user_id FK
        ENUM type "'credit', 'debit'"
        INT amount
        VARCHAR description
        BIGINT reference_id
        VARCHAR reference_type
    }

    DISBURSEMENTS {
        BIGINT id PK
        BIGINT mitra_profile_id FK
        BIGINT voucher_claim_id FK
        DECIMAL amount_idr
        VARCHAR xendit_disbursement_id "UNIQUE"
        ENUM status "'pending', 'completed', 'failed'"
        JSON response_log
        TIMESTAMP processed_at
    }

    %% ====================================================
    %% RELATIONSHIPS (CARDINALITY)
    %% ====================================================

    USERS ||--o| WARGA_PROFILES : "has profile"
    USERS ||--o| MITRA_PROFILES : "has profile"

    USERS ||--o{ USER_MISSIONS : "performs"
    MISSIONS ||--o{ USER_MISSIONS : "attempted in"
    
    USERS ||--o{ MOBILITY_LOGS : "tracks"
    
    MISSIONS ||--o{ QUIZ_QUESTIONS : "contains"
    
    MITRA_PROFILES ||--o{ VOUCHERS : "creates"
    VOUCHERS ||--o{ VOUCHER_CLAIMS : "claimed as"
    USERS ||--o{ VOUCHER_CLAIMS : "claims"
    
    USERS ||--o{ POINT_TRANSACTIONS : "owns balance log"
    
    MITRA_PROFILES ||--o{ DISBURSEMENTS : "receives"
    VOUCHER_CLAIMS ||--o| DISBURSEMENTS : "triggers payout"

```
