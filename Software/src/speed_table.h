const uint8_t speed_table[32] = {
		0b00000, // Stop
		0b10000, // Stop (I)
		0b00001, // E-Stop
		0b10001, // E-Stop (I)
		0b00010, // Step 1
		0b10010, // Step 2
		0b00011, // Step 3
		0b10011, // Step 4
		0b00100, // Step 5
		0b10100, // Step 6
		0b00101, // Step 7
		0b10101, // Step 8
		0b00110, // Step 9
		0b10110, // Step 10
		0b00111, // Step 11
		0b10111, // Step 12
		0b01000, // Step 13
		0b11000, // Step 14
		0b01001, // Step 15
		0b11001, // Step 16
		0b01010, // Step 17
		0b11010, // Step 18
		0b01011, // Step 19
		0b11011, // Step 20
		0b01100, // Step 21
		0b11100, // Step 22
		0b01101, // Step 23
		0b11101, // Step 24
		0b01110, // Step 25
		0b11110, // Step 26
		0b01111, // Step 27
		0b11111, // Step 28
};
