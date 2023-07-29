section .text
global sum

; Funkcja sum
; void sum(int64_t *x, size_t n);
; Argumenty:
;   x - wskaźnik na niepustą tablicę 64-bitowych liczb całkowitych w reprezentacji uzupełnieniowej do dwójki
;   n - rozmiar tablicy x

sum:
    push rbp

    ; Inicjalizacja iteratora pętli i = 0
    xor rcx, rcx
    ; umieszcza x[0] w rbx
    mov rbx, rdi

forloop:
    ; i++
    add rcx, 1

    cmp rsi, rcx ; sprawdzam warunek pętli i < n, rsi == n, rcx = 1
    jz finish ; zakończ pętlę, jeśli i >= n

    ; rbx = x[i+1]
    add rbx, 8
    ; r11 = x[i], przechowuję wartość, która będzie następnie dodawana do tablicy, po przemnożeniu przez odpowiednią potęgę
    mov r11, QWORD [rbx]

    ; wypełnia x[i] pozycję w tablicy: zerami jeśli x[i-1] >= 0, jedynkami jeśli x[i-1] < 0
    jmp fill_next_64_in_arr

    ; oblicza floor ((64 * i * i )/n)
calculate_floor:
    mov rax, 64 ; rax = 64
    mov r8, rcx ; r8 = i
    imul r8, r8 ; i*i
    imul rax, r8  ; 64*i*i
    cqo
    idiv rsi ; 64*i*i/n

    ; obliczam miejsce x[i], na które zostanie dodana liczba jako rax / 64
    ; obliczam wartość przesunięcia liczby jako rax % 64
    mov r9, 64
    xor rdx, rdx
    idiv r9

    ; liczba będzie reprezentowana w postaci 128 bitowej
    ; aby poprawnie ją zaprezentować, wypełniam drugi rejestr
    test r11, r11
    js fill_r10_with_1 ; jedynkami, jeśli r11 < 0
    jmp fill_r10_with_0 ; zerami, jeśli r11 >= 0

    ; obliczam przesunięcie, któremu będzie poddana liczba, aby mogła zostać dodana we właściwe miejsce w tablicy
calculate_shift:
    mov r8, rcx ; zapamiętuję wartość iteratora
    mov cl, dl
    ; wykonuję przesunięcie bitowe obu reprezentacji liczby w rejestrach o obliczoną wartość
    shld r10, r11, cl
    shl r11, cl

    xor rcx, rcx
    mov rcx, r8 ; odtwarzam iterator

    ; dodaję młodsze bity liczby do odpowiedniego miejsca w tablicy
    adc QWORD [rdi + 8*rax], r11
    ; dodaję starsze bity liczby do odpowiedniego miejsca w tablicy
    add QWORD [rdi + 8*rax + 8], r10

    jmp forloop

; uzupełnia we właściwy sposób 64 bity z tablicy x[]
fill_next_64_in_arr:
    ; sprawdzam, czy x[i - 1] < 0 czy >= 0
    test byte [rbx - 8], 0x80
    jc fill_rbx_with_1 ; jedynkami, jeśli x[i-1] < 0
    jmp fill_rbx_with_0 ; zerami, jeśli x[i-1] >= 0

; uzupełnia w pamięci wskazywanej przez rbx zerami
fill_rbx_with_0:
    mov QWORD [rbx], 0
    jmp calculate_floor

; uzupełnia w pamięci wskazywanej przez rbx jedynkami
fill_rbx_with_1:
    mov QWORD [rbx], -1
    jmp calculate_floor

; wypełnia rejestr r10 zerami
fill_r10_with_0:
    xor r10, r10
    jmp calculate_shift

; wypełnia rejestr r10 jedynkami
fill_r10_with_1:
    mov r10, -1
    jmp calculate_shift

finish:
    pop rbp
    ret

; Komentarz do kodu:
; Kod implementuje funkcję sum, która oblicza wartość y zgodnie z opisem zadania.
; Iteruje po tablicy x, obliczając wykładnik potęgi oraz wartość do dodania do y.
; Na koniec zapisuje wynik w tablicy x w porządku cienkokońcówkowym.
; Funkcja działa w miejscu, bez używania dodatkowej pamięci.
