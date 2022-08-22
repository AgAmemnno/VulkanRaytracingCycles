#pragma once

#ifndef GLOBAD_H
#define GLOBAD_H

#include <stdint.h>

#ifdef _WIN32
#define KEYMAX 512
#elif defined __APPLE__
#define KEYMAX 512
#else
#define KEYMAX 128
#endif


extern int killme;	/* global killswitch */
extern int sys_width;	/* dimensions of default screen */
extern int sys_height;
extern float sys_dpi;
extern int vid_width;	/* dimensions of our part of the screen */
extern int vid_height;
extern int mouse_x;	/* position */
extern int mouse_y;
extern int mickey_x;	/* velocity */
extern int mickey_y;
extern char keys[KEYMAX];
extern char mouse[8];	/* button status 0=up 1=down */
// On mac...
// the Logitech drivers are happy to send up to 8 numbered "mouse" buttons
// http://www.Logitech.com/pub/techsupport/mouse/mac/lcc3.9.1.b20.zip
extern int fullscreen;
extern int fullscreen_toggle;

/*
int main_init(int argc, char* argv[]);
void main_loop(void);
void main_end(void);
*/

extern uint64_t sys_ticksecond;	/* ticks in a second */
uint64_t sys_time(void);
void sys_time_init(void);

extern const char git_version[];
extern const char binary_name[];

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif


#endif