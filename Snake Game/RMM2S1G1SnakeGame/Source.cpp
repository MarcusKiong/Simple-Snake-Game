#include <iostream>
#include <string>
using namespace std;

extern "C" {
	char encryption(char, int);
	void mainAsm();
	char validatePosition(char, char, char, char);
	int getSpeed();
	int gameOverValidation();
}

void main() {
	mainAsm();								// run the mainAsm function
}

char encryption(char val, int key) {
	if (val > 80)
		return (char)(val - key);		// subtract the encryption key if the char value is higher than 80
	else
		return (char)(val + key);		// add the encryption key if the char value is lower than or equals to 80
}

char validatePosition(char xPos, char yPos, char xCoinPos, char yCoinPos)
{
	if ((xPos == xCoinPos) && (yPos == yCoinPos)) {
		return '0';									// return '0' if the first two x and y position is same with the x and y position of the coin
	}
	return '1';											// otherwise, return '1'
}

int getSpeed() {
	string speed;
	getline(cin, speed);					// read string
	if (speed == "1")						//return 1 if user inputs "1"
		return 1;
	else if (speed == "2")					//return 2 if user inputs "2"
		return 2;
	else if (speed == "3")					//return 3 if user inputs "3"
		return 3;
	else
		return 99;							// otherwise, return 99
}

int gameOverValidation() {
	string speed;
	getline(cin, speed);					// read string
	if (speed == "0")						//return 0 if user inputs "0"
		return 0;
	else if (speed == "1")					//return 1 if user inputs "1"
		return 1;
	else
		return 99;							// otherwise, return 99
}



