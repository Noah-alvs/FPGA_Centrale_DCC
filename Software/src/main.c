#include "xparameters.h"
#include "xil_io.h"
#include "xgpio.h"
#include "CENTRALE_DCC.h"
#include "sev_seg.h"
#include "stdio.h"
#include "speed_table.h"
#include "func_table.h"


extern const uint8_t SevenSegmentASCII[96];
extern const uint8_t speed_table[32];
extern const uint8_t func_table_F0_to_F12_on[13];
extern const uint8_t func_table_F0_to_F12_off[13];
extern const uint16_t func_table_F13_to_F20_on[8];

// Attention au reset

#define MICROBLAZE_FREQ 100000000 // ?

#define APPUI_BOUTON_GAUCHE ((but_state & 0x04) == 4) && ((old_but_state & 0x04) == 0)
#define APPUI_BOUTON_DROITE ((but_state & 0x08) == 8) && ((old_but_state & 0x08) == 0)
#define APPUI_BOUTON_HAUT ((but_state & 0x02) == 2) && ((old_but_state & 0x02) == 0)
#define APPUI_BOUTON_BAS ((but_state & 0x10) == 16) && ((old_but_state & 0x16) == 0)
#define APPUI_BOUTON_CENTRE ((but_state & 0x1) == 1) && ((old_but_state & 0x1) == 0)


// Variables globales pour le 7 segments
const int sev_seg_del_4ms = 0.00004 * MICROBLAZE_FREQ;
uint8_t num_to_display = 0; 								// chiffre du 7 segments affiché
char* string_to_display ="A000";							// chaîne de caractères à afficher

const int boutons_del_10ms = 0.0001 * MICROBLAZE_FREQ;
// addr disp = addr affichée quand on selectionne
// addr = adresse effective pour le calcul des trames
uint8_t addr = 0;
uint8_t addr_disp = 0;

// speed disp = vitesse affichée quand on selectionne
// speed = vitesse effective pour le calcul des trames
int8_t speed = 0;
int8_t speed_disp = 0;

// func disp = fonction affichée quand on selectionne
// func = fonction effective pour le calcul des trames
uint8_t func = 0;
uint8_t func_disp;

// func_on_off_disp = sous menu on/off affichée quand on selectionne
// func_on_off = sous menu effectif pour le calcul des trames
uint8_t func_on_off = 0;
uint8_t func_on_off_disp = 0;

uint8_t menu = 0;

void write_sev_seg(int *cpt, XGpio* an, XGpio* seg, char* s) {

	if(*cpt > sev_seg_del_4ms) { 											// on actualise le 7seg ttes les 4ms à priori

		int an_reg = ~(1 << num_to_display); 								// on allume l'écran suivant (actif état bas)
		int seg_reg = ~(SevenSegmentASCII[(int)s[3-num_to_display]-32]);	// on affiche le bon caractère sur le bon écran + décalage pour matcher avec la table ascii

		XGpio_DiscreteWrite(an, 1, an_reg);
		XGpio_DiscreteWrite(seg, 2, seg_reg);

		num_to_display = (num_to_display + 1) % 4;
		*cpt = 0;
	} else {
		(*cpt)++;
	}
}

void calculate_trame_speed(uint64_t * trame) {
	uint32_t preambule = 0x7FFFFF; 											// 23 bits à 1

	uint8_t command;

	if(speed < 0) {
		command = (0b010) << 5 | speed_table[(speed * (-1)) + 3];		// décalage pour sauter les 4 différents type de stop
	} else if(speed > 0) {
		command = (0b011) << 5 | speed_table[speed + 3];		// décalage pour sauter les 4 différents type de stop
	} else if (speed == 0) {
		command = (0b011) << 5 | speed_table[speed];			// pour le cas speed = 0 => STOP
	}


	uint8_t controle = addr ^ command;										// XOR

	*trame = (uint64_t)preambule << (51-23) | (uint64_t)0 << (51-24) |		// cast systématique sur (uint64_t) sinon risque d'overflow lors du décalage
			 (uint64_t)addr << (51-32) | (uint64_t)0 << (51-33) |
			 (uint64_t)command << (51-41) | (uint64_t)0 << (51-42) |
			 (uint64_t)controle << (51-50) | (uint64_t)1;
}

void calculate_trame_func(uint64_t * trame) {
	uint16_t command;														// commande sur 1 ou 2 octets

	if(func < 13) { 														// 1 octet de commande

		if(func_on_off) {
			command = func_table_F0_to_F12_on[func];
		} else {
			command = func_table_F0_to_F12_off[func];
		}

		uint32_t preambule = 0x7FFFFF; 										// 23 bits à 1
		uint8_t control = addr ^ command;
		*trame = (uint64_t)preambule << (51-23) | (uint64_t)0 << (51-24) |	// cast systématique sur (uint64_t) sinon risque d'overflow lors du décalage
				 (uint64_t)addr << (51-32) | (uint64_t)0 << (51-33) |
				 (uint64_t)command << (51-41) | (uint64_t)0 << (51-42) |
				 (uint64_t)control << (51-50) | (uint64_t)1;

	} else { 																// if func >= 13, 2 octets de commande

		if(func_on_off) {
			command = func_table_F13_to_F20_on[func-13]; 					// décalage car F13 = indice 0 de la table
		} else {
			command = 0b1101111000000000;									// même commande pour toutes les fonctions >= 13
		}

		uint16_t preambule = 0x3FFF; 										// 14 bits à 1 car 2 octets de commande
		uint8_t control = (addr) ^ (command & 0xFF) ^ (command >> 8);		// XOR sur addr, commande_octet_1 et commande_octet_2
		*trame = (uint64_t)preambule << (51-14) | 0 << (51-15) |			// cast systématique sur (uint64_t) sinon risque d'overflow lors du décalage
				(uint64_t)addr << (51-23) | 0 << (51-24) |
				(uint64_t)(command >> 8) << (51-32) | 0 << (51-33) |
				(uint64_t)(command & 0xFF) << (51-41) | 0 << (51-42) |
				(uint64_t)control << (51-50) | 1;
	}

}

void send_trame(const uint64_t * trameptr) {

	uint64_t trame = *trameptr;

	uint32_t trame1 = trame >> (51-32); 		// on  récupère les 32 bits de gauche -> Preambule (23 ou 14) + start bit + addr
	uint32_t trame2 = trame & (0x7FFFF);		// on récupère les 19 bits de droite

	CENTRALE_DCC_mWriteReg(XPAR_CENTRALE_DCC_0_S00_AXI_BASEADDR, CENTRALE_DCC_S00_AXI_SLV_REG0_OFFSET, trame1); // écrit dans reg 0 de l'ip centrale dcc
	CENTRALE_DCC_mWriteReg(XPAR_CENTRALE_DCC_0_S00_AXI_BASEADDR, CENTRALE_DCC_S00_AXI_SLV_REG1_OFFSET, trame2); // écrit dans reg 1 de l'ip centrale dcc

}

int main() {

	// INIT des compteurs pour les 2 tâches
	int cpt_seg = 0;
	int cpt_boutons = 0;

	// INIT trame (51 bits -> uint64_t)
	uint64_t trame = 0;

	// INIT GPIO
	XGpio an, seg;
	XGpio_Initialize(&an, XPAR_GPIO_SEV_SEG_DEVICE_ID);
	XGpio_Initialize(&seg, XPAR_GPIO_SEV_SEG_DEVICE_ID);
	XGpio_SetDataDirection(&an, 1, 0);
	XGpio_SetDataDirection(&seg, 2, 0);

	XGpio boutons;
	XGpio_Initialize(&boutons, XPAR_GPIO_BOUTONS_DEVICE_ID);
	XGpio_SetDataDirection(&boutons, 2, 0xF);

	uint8_t old_but_state = 0; // pour debounce

	while(1) {

		// actualise le display
		write_sev_seg(&cpt_seg, &an, &seg, string_to_display);

		// Gestion boutons menu
		if(cpt_boutons > boutons_del_10ms) { // polling ttes les 10ms à priori

			int but_state = XGpio_DiscreteRead(&boutons, 2);

			// Les boutons droite et gauche servent à changer de menu
			if(APPUI_BOUTON_GAUCHE && menu > 0 && menu != 3) {
				menu--;
			} else if (APPUI_BOUTON_DROITE && menu < 2 && menu != 3) {
				menu++;
			}

			if(menu == 0) { 												// MENU 0 = ADRESSE

				// On test haut et bas et centre
				if(APPUI_BOUTON_HAUT && addr_disp < 8) { 					// haut
					addr_disp++;											// on incrémente seulement la variable "disp"
				} else if(APPUI_BOUTON_BAS && addr_disp > 0) { 				// bas
					addr_disp--;											// idem
				} else if(APPUI_BOUTON_CENTRE) {	 						// centre
					addr =  addr_disp;										// on confirme que l'adresse affichée sera celle utilisée lors du calcul des adresses
				}

				// Affichage de l'adresse sur le 7 seg
				string_to_display[0] = 'A';
				string_to_display[1] = 48;									// 48 = '0' dans la table ascii
				string_to_display[2] = 48;
				string_to_display[3] = addr_disp + 48;

				speed_disp = speed;											// pour que qd on revient sur le menu speed, la vitesse affichée soit la vitesse effective
				func_disp = func;											// idem avec les fonctions


			} else if(menu == 1) { 											// MENU 1 = VITESSE (SPEED)

				if(APPUI_BOUTON_HAUT && speed_disp < 28) {
					speed_disp++;
				} else if(APPUI_BOUTON_BAS && speed_disp > -28) {
					speed_disp--;
				} else if(APPUI_BOUTON_BAS && (speed_disp == -28) ) {
					speed_disp = 0;
				} else if(APPUI_BOUTON_HAUT && speed_disp == 28) {
					speed_disp = 0;
				} else if(APPUI_BOUTON_CENTRE) {
					speed = speed_disp;
					calculate_trame_speed(&trame);							// quand on appuie sur le bouton central, on calcule puis envoie la trame de vitesse affichée
					send_trame(&trame);
				}


				if(speed_disp < 0) {
					string_to_display[0] = 'S';
					string_to_display[1] = '-';									// '0'
					string_to_display[2] = (speed_disp * (-1))/10 + 48;					// affichage dizaines
					string_to_display[3] = (speed_disp * (-1))%10 + 48;					// affichage unités
				} else {
					string_to_display[0] = 'S';
					string_to_display[1] = 48;									// '0'
					string_to_display[2] = speed_disp/10 + 48;					// affichage dizaines
					string_to_display[3] = speed_disp%10 + 48;					// affichage unités
				}

				addr_disp = addr; 											// pour que qd on revient sur le menu addr, l'adresse affichée soit la vitesse effective
				func_disp = func;											// idem avec les fonctions

			} else if(menu == 2) { 											// MENU 2 = FONCTION


				if(APPUI_BOUTON_HAUT && func_disp < 20) {
					func_disp++;
				} else if(APPUI_BOUTON_BAS && func_disp > 0) {
					func_disp--;
				} else if(APPUI_BOUTON_HAUT && func_disp == 20) {
					func_disp = 0;
				} else if(APPUI_BOUTON_BAS && func_disp == 0) {
					func_disp = 20;
				} else if(APPUI_BOUTON_CENTRE) {
					func =  func_disp;

					if( !( (func == 11) | (func == 12) | (func == 13) | (func == 14) | (func == 15) | (func == 16) | (func == 17) | (func == 19) ) ) {		// les fonctions "one_shot" style klaxon
						menu = 3;													// si on ne selectionne pas une de ces fonctions one shot, on passe dans le menu "ON/OFF"
					} else {
						// send command on
						func_on_off = 1;
						calculate_trame_func(&trame);
						send_trame(&trame);

						//sleep() blocking
						volatile int i;												// pas super propre, car l'affichage freeze pendant ce temps...
						for(i = 0; i < 1000000; i++);

						// send command off
						func_on_off = 0;
						calculate_trame_func(&trame);
						send_trame(&trame);
					}
				}

				string_to_display[0] = 'F';
				string_to_display[1] = 48;
				string_to_display[2] = func_disp/10 + 48;
				string_to_display[3] = func_disp%10 + 48;

				addr_disp = addr;											// idem addr
				speed_disp = speed;											// idem speed

			} else if(menu == 3) { 											// MENU 3 = ON/OFF pour les fonctions de ce type

				if(APPUI_BOUTON_HAUT) {
					func_on_off_disp = 1;									// 1 = ON
				} else if(APPUI_BOUTON_BAS) {
					func_on_off_disp = 0;									// 1 = OFF
				} else if(APPUI_BOUTON_CENTRE) {

					func_on_off = func_on_off_disp;							// confirme la fonction choisie

					calculate_trame_func(&trame);
					send_trame(&trame);

					menu = 2; 												// on revient au menu de sélection des fonctions (menu 2)
				}


				if(!func_on_off_disp) {										// affichage de OFF
					string_to_display[0] = 0;
					string_to_display[1] = 'O';
					string_to_display[2] = 'F';
					string_to_display[3] = 'F';
				} else {													// affichage de ON
					string_to_display[0] = 0;
					string_to_display[1] = 0;
					string_to_display[2] = 'O';
					string_to_display[3] = 'N';
				}

			}

			old_but_state = but_state;
			cpt_boutons = 0;
		} else {
			cpt_boutons++;
		}

	}


}
