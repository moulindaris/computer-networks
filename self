#include <stdio.h>
#include <string.h>

#define max 100
#define max_bit (max * 8)
#define max_stuff (max_bit * 2)

#define CRC8_POLY 0x07

int data[max_bit], stuff[max_stuff], destuff[max_bit];
char str[max];
char output_str[max];
int flag[] = {0, 1, 1, 1, 1, 1, 1, 0};
int flaglen = 8;

void print(const char *label, int arr[], int n) {
    int i;
    printf("%s ", label);
    for(i = 0; i < n; i++) {
        printf("%d", arr[i]);
    }
    printf("\n");
}

unsigned char compute_crc8(int bits[], int len) {
    unsigned char crc = 0x00;
    int i, b;
    for (i = 0; i < len; i += 8) {
        unsigned char byte = 0;
        for (b = 0; b < 8; b++) {
            if (i + b < len) {
                byte = (byte << 1) | bits[i + b];
            }
        }
        crc ^= byte;
        for (b = 0; b < 8; b++) {
            if (crc & 0x80) {
                crc = (crc << 1) ^ CRC8_POLY;
            } else {
                crc <<= 1;
            }
        }
    }
    return crc;
}

int main() {
    int choice;

    while(1) {
        printf("\n___ Bit Stuffing & Simulation Menu ___\n");
        printf("1. Complete Transmission (With CRC & Error Simulation)\n");
        printf("2. Exit\n");
        printf("Enter your choice : ");

        if (scanf("%d", &choice) != 1) {
            printf("Invalid input type. Exiting program.\n");
            break;
        }
        getchar();

        if (choice == 2) {
            printf("\nExiting>>>>\n");
            break;
        }

        switch(choice) {
            case 1: {
                int i, b, bit = 0, ones = 0, j = 0;
                printf("\nEnter a string to transmit: ");
                fgets(str, sizeof(str), stdin);
                str[strcspn(str, "\n")] = '\0';

                int str_len = strlen(str);

                for(i = 0; i < str_len; i++) {
                    unsigned char ch = (unsigned char)str[i];
                    for(b = 7; b >= 0; b--) {
                        data[bit++] = (ch >> b) & 1;
                    }
                }
                
                unsigned char tx_crc = compute_crc8(data, bit);
                for(b = 7; b >= 0; b--) {
                    data[bit++] = (tx_crc >> b) & 1;
                }

                printf("\n--- SENDER SIDE ---\n");
                print("Transmitted Data (+CRC):", data, bit);

                for(i = 0; i < bit; i++) {
                    stuff[j++] = data[i];
                    ones = (data[i] == 1) ? ones + 1 : 0;
                    if(ones == 5) {
                        stuff[j++] = 0;
                        ones = 0;
                    }
                }
                int stufflen = j;

                int framed[max_stuff], k = 0;
                for(i = 0; i < flaglen; i++) framed[k++] = flag[i];
                for(i = 0; i < stufflen; i++) framed[k++] = stuff[i];
                for(i = 0; i < flaglen; i++) framed[k++] = flag[i];
                int framelen = k;

                print("Stuffed Payload:        ", stuff, stufflen);
                print("Generated Frame:        ", framed, framelen);

                int sim_choice;
                printf("\n--- CHANNEL ERROR SIMULATION ---\n");
                printf("0. No Error (Clean Transmission)\n");
                printf("1. Inject Single-Bit Error\n");
                printf("2. Inject Multi-Bit Error\n");
                printf("Select channel condition: ");
                scanf("%d", &sim_choice);
                getchar();

                if(sim_choice == 1) {
                    int err_idx = flaglen + 2;
                    if(err_idx < framelen - flaglen) {
                        framed[err_idx] ^= 1;
                        printf("[SIMULATION] Flipped 1 bit at index %d\n", err_idx);
                    }
                } else if(sim_choice == 2) {
                    int err_idx1 = flaglen + 2;
                    int err_idx2 = flaglen + 4;
                    if(err_idx2 < framelen - flaglen) {
                        framed[err_idx1] ^= 1;
                        framed[err_idx2] ^= 1;
                        printf("[SIMULATION] Flipped 2 bits at indexes %d and %d\n", err_idx1, err_idx2);
                    }
                }

                print("Received Frame:         ", framed, framelen);

                printf("\n--- RECEIVER SIDE ---\n");
                ones = 0;
                j = 0;
                int structural_error = 0;
                for(i = flaglen; i < framelen - flaglen; i++) {
                    destuff[j++] = framed[i];
                    ones = (framed[i] == 1) ? ones + 1 : 0;
                    if(ones == 5) {
                        if(framed[i+1] != 0) {
                            structural_error = 1;
                            break;
                        }
                        i++;
                        ones = 0;
                    }
                }

                if (structural_error) {
                    printf("ERROR DETECTION STATUS: Frame Discarded! Invalid Bit-Stuffing structural pattern detected.\n");
                    break;
                }

                int destufflen = j;
                print("De-stuffed Data (+CRC): ", destuff, destufflen);

                unsigned char rx_crc = compute_crc8(destuff, destufflen);
                
                if(rx_crc != 0) {
                    printf("ERROR DETECTION STATUS: CRC Integrity Check Failed! Data corrupted during transmission.\n");
                } else {
                    printf("ERROR DETECTION STATUS: Success! No errors detected. Data integrity verified.\n");
                    
                    int final_payload_len = destufflen - 8;

                    int out_idx = 0;
                    for(i = 0; i < final_payload_len; i += 8) {
                        unsigned char ch = 0;
                        for(b = 0; b < 8; b++) {
                            if (i + b < final_payload_len) {
                                ch = (ch << 1) | destuff[i+b];
                            }
                        }
                        output_str[out_idx++] = ch;
                    }
                    output_str[out_idx] = '\0';
                    printf("Decoded Output String:   %s\n", output_str);
                }
                break;
            }

            default:
                printf("Invalid selection. Please choose option 1 or 2.\n");
                break;
        }
    }

    return 0;
}
