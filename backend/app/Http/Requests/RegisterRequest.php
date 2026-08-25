<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['required', 'string', 'regex:/^\+[0-9]{10,15}$/', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['required', 'string', 'in:warga'],
            'city' => ['required', 'string', 'max:255'],
            'district' => ['required', 'string', 'max:255'],
            'sub_district' => ['required', 'string', 'max:255'],
            'rt' => ['required', 'string', 'max:10'],
            'rw' => ['required', 'string', 'max:10'],
        ];
    }

    public function messages(): array
    {
        return [
            'phone.regex' => 'Phone number must be in international format (e.g. +628123456789).',
            'phone.unique' => 'This phone number is already registered.',
            'email.unique' => 'This email is already registered.',
            'role.in' => 'Role must be either warga or mitra.',
            'password.confirmed' => 'Password confirmation does not match.',
            'rt.required' => 'RT is required for location mapping.',
            'rw.required' => 'RW is required for location mapping.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Validation failed.',
            'errors' => $validator->errors(),
        ], 422));
    }
}